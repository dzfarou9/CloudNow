//! JNI bridge used by the Flutter Android client.
//!
//! This is the native side of the hybrid port. It deliberately owns no UI and
//! no protocol logic of its own: requests are the versioned JSON envelopes from
//! `docs/core-protocol.md`, and the video surface is passed in as a plain
//! `android.view.Surface`.
//!
//! Current state: the transport, event queue and stream lifetime are wired.
//! Live GFN calls return `not_implemented` until `native/opennow-core`'s modules
//! are exposed as a library rather than only through its stdio binary. See
//! `flutter/README.md` for the exact follow-up work.

use jni::objects::{GlobalRef, JClass, JObject, JString};
use jni::sys::{jfloat, jint, jstring};
use jni::JNIEnv;
use once_cell::sync::Lazy;
use serde_json::{json, Value};
use std::collections::VecDeque;
use std::sync::Mutex;

/// Must match `PROTON_PROTOCOL_VERSION` in the desktop core handshake.
const PROTOCOL_VERSION: i64 = 6;
const MAX_EVENT_QUEUE: usize = 256;
const MAX_SETTINGS_BYTES: usize = 64 * 1024;

#[derive(Default)]
struct BridgeState {
    settings: Value,
    events: VecDeque<String>,
    stream_config: Option<Value>,
    streaming: bool,
    surface: Option<GlobalRef>,
}

static STATE: Lazy<Mutex<BridgeState>> = Lazy::new(|| {
    Mutex::new(BridgeState {
        settings: json!({}),
        ..Default::default()
    })
});

fn error_response(id: Option<Value>, code: &str, message: &str) -> String {
    json!({
        "type": "response",
        "id": id.unwrap_or_else(|| Value::Null),
        "error": {"code": code, "message": message},
    })
    .to_string()
}

fn success_response(id: Option<Value>, result: Value) -> String {
    json!({
        "type": "response",
        "id": id.unwrap_or_else(|| Value::Null),
        "result": result,
    })
    .to_string()
}

fn push_event(state: &mut BridgeState, event: Value) {
    if state.events.len() >= MAX_EVENT_QUEUE {
        state.events.pop_front();
    }
    state.events.push_back(event.to_string());
}

/// Handles the small offline subset and forwards everything else as a typed
/// "not implemented" response so the Flutter shell can render without a server.
fn dispatch(request: &str) -> String {
    let value: Value = match serde_json::from_str(request) {
        Ok(value) => value,
        Err(error) => return error_response(None, "invalid_json", &error.to_string()),
    };
    if value.get("type").and_then(Value::as_str) != Some("request") {
        return error_response(None, "invalid_envelope", "expected type=request");
    }
    let id = value.get("id").cloned();
    let method = value.get("method").and_then(Value::as_str).unwrap_or("");
    let params = value.get("params").cloned().unwrap_or_else(|| json!({}));

    match method {
        "shell.ping" => success_response(id, json!({"pong": true})),
        "core.hello" => {
            let requested = params
                .get("protocolVersion")
                .and_then(Value::as_i64)
                .unwrap_or(0);
            if requested != PROTOCOL_VERSION {
                return error_response(
                    id,
                    "incompatible_protocol",
                    "mobile bridge speaks protocol 6 only",
                );
            }
            success_response(
                id,
                json!({
                    "protocolVersion": PROTOCOL_VERSION,
                    "capabilities": [],
                    "streamerProtocol": 8,
                }),
            )
        }
        "settings.get" => {
            let state = STATE.lock().unwrap();
            success_response(id, state.settings.clone())
        }
        "settings.set" => {
            let patch = params.get("settings").cloned().unwrap_or(json!({}));
            let mut state = STATE.lock().unwrap();
            if patch.to_string().len() > MAX_SETTINGS_BYTES {
                return error_response(id, "invalid_params", "settings payload too large");
            }
            let written = if patch.is_object() {
                if let Some(settings) = state.settings.as_object_mut() {
                    for (key, value) in patch.as_object().map(|p| p.iter()).into_iter().flatten() {
                        settings.insert(key.clone(), value.clone());
                    }
                    true
                } else {
                    false
                }
            } else {
                false
            };
            drop(state);
            if written {
                success_response(id, json!({"written": true}))
            } else {
                error_response(id, "invalid_params", "settings store is corrupt")
            }
        }
        "diagnostics.snapshot" => {
            let state = STATE.lock().unwrap();
            success_response(
                id,
                json!({
                    "streaming": state.streaming,
                    "streamConfig": state.stream_config,
                }),
            )
        }
        _ => error_response(
            id,
            "not_implemented",
            "method requires the opennow-core library (see flutter/README.md)",
        ),
    }
}

fn read_string(env: &mut JNIEnv, input: &JString) -> Option<String> {
    env.get_string(input).ok().map(|s| s.into())
}

fn return_string(env: &mut JNIEnv, value: String) -> jstring {
    match env.new_string(value) {
        Ok(s) => s.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "system" fn Java_com_opencloudgaming_opennow_android_OpenNowNative_coreRequest(
    mut env: JNIEnv,
    _class: JClass,
    request: JString,
) -> jstring {
    let Some(request) = read_string(&mut env, &request) else {
        return std::ptr::null_mut();
    };
    return_string(&mut env, dispatch(&request))
}

#[no_mangle]
pub extern "system" fn Java_com_opencloudgaming_opennow_android_OpenNowNative_nextEvent(
    mut env: JNIEnv,
    _class: JClass,
) -> jstring {
    let event = STATE.lock().unwrap().events.pop_front();
    match event {
        Some(event) => return_string(&mut env, event),
        None => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "system" fn Java_com_opencloudgaming_opennow_android_OpenNowNative_surfaceReady(
    mut env: JNIEnv,
    _class: JClass,
    surface: JObject,
) {
    match env.new_global_ref(surface) {
        Ok(reference) => STATE.lock().unwrap().surface = Some(reference),
        Err(error) => {
            let _ = env.throw_new("java/lang/IllegalStateException", error.to_string());
        }
    }
}

#[no_mangle]
pub extern "system" fn Java_com_opencloudgaming_opennow_android_OpenNowNative_surfaceReleased(
    _env: JNIEnv,
    _class: JClass,
) {
    STATE.lock().unwrap().surface = None;
}

#[no_mangle]
pub extern "system" fn Java_com_opencloudgaming_opennow_android_OpenNowNative_streamStart(
    mut env: JNIEnv,
    _class: JClass,
    config: JString,
) {
    let Some(config) = read_string(&mut env, &config) else {
        return;
    };
    let parsed: Value = match serde_json::from_str(&config) {
        Ok(value) => value,
        Err(error) => {
            let _ = env.throw_new("java/lang/IllegalArgumentException", error.to_string());
            return;
        }
    };
    let mut state = STATE.lock().unwrap();
    state.stream_config = Some(parsed);
    state.streaming = true;
    push_event(
        &mut state,
        json!({
            "type": "event",
            "name": "session.stream.started",
            "payload": {"transport": "pending_android_platform"},
        }),
    );
}

#[no_mangle]
pub extern "system" fn Java_com_opencloudgaming_opennow_android_OpenNowNative_streamStop(
    _env: JNIEnv,
    _class: JClass,
) {
    let mut state = STATE.lock().unwrap();
    state.streaming = false;
    state.stream_config = None;
    push_event(
        &mut state,
        json!({"type": "event", "name": "session.stream.stopped", "payload": {}}),
    );
}

#[no_mangle]
pub extern "system" fn Java_com_opencloudgaming_opennow_android_OpenNowNative_submitKey(
    _env: JNIEnv,
    _class: JClass,
    key_code: jint,
    action: jint,
    modifiers: jint,
) {
    let mut state = STATE.lock().unwrap();
    if !state.streaming {
        return;
    }
    push_event(
        &mut state,
        json!({
            "type": "event",
            "name": "input.key",
            "payload": {"keyCode": key_code, "action": action, "modifiers": modifiers},
        }),
    );
}

#[no_mangle]
pub extern "system" fn Java_com_opencloudgaming_opennow_android_OpenNowNative_submitText(
    mut env: JNIEnv,
    _class: JClass,
    text: JString,
) {
    let Some(text) = read_string(&mut env, &text) else {
        return;
    };
    // Bounded exactly like OPENNOW_STREAMER_MAX_TEXT_BYTES.
    if text.len() > 65_536 {
        let _ = env.throw_new("java/lang/IllegalArgumentException", "text exceeds 65536 bytes");
        return;
    }
    let mut state = STATE.lock().unwrap();
    if !state.streaming {
        return;
    }
    push_event(
        &mut state,
        json!({"type": "event", "name": "input.text", "payload": {"text": text}}),
    );
}

#[no_mangle]
pub extern "system" fn Java_com_opencloudgaming_opennow_android_OpenNowNative_submitMouse(
    _env: JNIEnv,
    _class: JClass,
    dx: jfloat,
    dy: jfloat,
    buttons: jint,
) {
    let mut state = STATE.lock().unwrap();
    if !state.streaming {
        return;
    }
    push_event(
        &mut state,
        json!({
            "type": "event",
            "name": "input.mouse",
            "payload": {"dx": dx, "dy": dy, "buttons": buttons},
        }),
    );
}

#[no_mangle]
pub extern "system" fn Java_com_opencloudgaming_opennow_android_OpenNowNative_requestKeyframe(
    _env: JNIEnv,
    _class: JClass,
) {
    let mut state = STATE.lock().unwrap();
    if state.streaming {
        push_event(
            &mut state,
            json!({"type": "event", "name": "stream.keyframe.request", "payload": {}}),
        );
    }
}

#[no_mangle]
pub extern "system" fn Java_com_opencloudgaming_opennow_android_OpenNowNative_diagnostics(
    mut env: JNIEnv,
    _class: JClass,
) -> jstring {
    let state = STATE.lock().unwrap();
    let snapshot = json!({
        "stage": "pending_android_platform",
        "receive": "not_started",
        "assembly": "not_started",
        "decode": "not_started",
        "presentation": "not_started",
        "feedback": "not_started",
        "streaming": state.streaming,
    });
    return_string(&mut env, snapshot.to_string())
}
