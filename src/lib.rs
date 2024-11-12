#![allow(clippy::missing_safety_doc)]

use minify_js::{Session, TopLevelMode};
use std::{mem::ManuallyDrop, slice};

#[no_mangle]
pub unsafe extern "C" fn create_session(session_ptr: *mut ManuallyDrop<Session>) {
    *session_ptr = ManuallyDrop::new(Session::new());
}

#[no_mangle]
pub extern "C" fn size_of_session() -> i32 {
    size_of::<ManuallyDrop<Session>>() as i32
}

#[no_mangle]
pub unsafe extern "C" fn drop_session(session_ptr: *mut ManuallyDrop<Session>) {
    ManuallyDrop::drop(session_ptr.as_mut().unwrap())
}

#[repr(C)]
pub struct MinifyResult {
    len: i32,
    ptr: *const u8,
    err: bool,
}

#[no_mangle]
pub unsafe extern "C" fn size_of_top_level_mode() -> i32 {
    size_of::<TopLevelMode>() as i32
}

#[no_mangle]
pub unsafe extern "C" fn export_top_level_mode(list: *mut TopLevelMode) {
    *list = TopLevelMode::Global;
    *list.add(1) = TopLevelMode::Module;
}

#[no_mangle]
pub unsafe extern "C" fn minify(
    session: *mut ManuallyDrop<Session>,
    toplevel: *mut TopLevelMode,
    ptr: *mut u8,
    len: i32,
) -> MinifyResult {
    let mut out = Vec::new();
    let src = slice::from_raw_parts(ptr, len as usize);
    let session = &**session;

    match minify_js::minify(session, *toplevel, src, &mut out) {
        Ok(()) => {
            let out = Vec::leak(out);
            MinifyResult {
                len: out.len() as i32,
                ptr: out.as_ptr(),
                err: false,
            }
        }
        Err(err) => {
            let msg = String::leak(format!("{:?}", err));
            MinifyResult {
                len: msg.len() as i32,
                ptr: msg.as_ptr(),
                err: true,
            }
        }
    }
}
