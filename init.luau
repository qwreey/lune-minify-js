--!nolint TableOperations

local ffi = require("@lune/ffi")
local minify_js = {} :: minify_js
minify_js.__index = minify_js

local TopLevelMode = {
    Global = 1,
    Module = 2,
}
minify_js.TopLevelMode = TopLevelMode

export type minify_js = minify_js_pub & minify_js_private
export type minify_js_pub = {
    minify: (self: minify_js, code: string, toplevel: number?) -> string,
    drop: (self: minify_js) -> (),
    TopLevelMode: typeof(TopLevelMode)
}
export type minify_js_private = {
    _size_of: (self: minify_js, name: string) -> number,
    _create_session: (self: minify_js) -> (ffi.BoxData, ffi.RefData),

    _lib: ffi.LibData,
    _minify: ffi.CallableData,
    _drop_session: ffi.CallableData,
    _session: ffi.BoxData,
    _session_ptr: ffi.RefData,
}

local session_t = ffi.c.void:ptr()
local minify_result_t = ffi.c.struct({
    -- len
    ffi.i32,
    -- ptr
    ffi.c.char:ptr(),
    -- err
    ffi.u8,
})

function minify_js:_size_of(name: string)
    local size = ffi.box(ffi.i32.size)
    ffi.c.fn({}, ffi.i32):callable(self._lib:find(`size_of_{name}`))(size)
    return ffi.i32:readData(size)
end

function minify_js:_create_session()
    local session = ffi.box(self:_size_of("session"))
    local session_ptr = session:ref():ref()
    ffi.c.fn({ session_t }, ffi.c.void):callable(self._lib:find("create_session"))(nil, session_ptr)
    self._session = session
    self._session_ptr = session_ptr
end

function minify_js:_create_top_level_mode()
    local map = table.create(2)
    self._top_level_mode_map = map
    local size = self:_size_of("top_level_mode")
    local box = ffi.box(size * 2)
    self._top_level_mode_box = box
    for i = 1, 2 do
        map[i] = box:ref(size * (i - 1)):ref()
    end
end

function minify_js.new(lib_path: string): minify_js
    local self = setmetatable({}, minify_js)
    self._lib = ffi.open(lib_path)
    self:_create_session()
    self:_create_top_level_mode()
    self._minify = ffi.c.fn({ session_t, ffi.i32, ffi.c.char:ptr(), ffi.c.void:ptr() }, minify_result_t):callable(self._lib:find("minify"))
    self._drop_session = ffi.c.fn({ session_t }, ffi.c.void):callable(self._lib:find("drop_session"))
    return self
end

function minify_js:minify(code: string, toplevel: number?): string
    local source = ffi.box(#code):writeString(code)
    local result = ffi.box(minify_result_t.size)
    self._minify(result, self._session_ptr, ffi.i32:box(#code):ref(), source:ref():ref(), self._top_level_mode_map[toplevel or 1])
    local result_table = minify_result_t:readData(result)
    local result_string = result_table[2]:readString(result_table[1])
    ffi.free(result_table[2])
    if result_table[3] == 1 then
        error(result_string)
    end
    return result_string
end

function minify_js:drop()
    self._drop_session(nil, self._session_ptr)
    self._lib = nil
    self._session_ptr = nil
    self._session = nil
    self._drop_session = nil
    self._minify = nil
end

return minify_js :: { new: (libpath: string) -> minify_js_pub }
