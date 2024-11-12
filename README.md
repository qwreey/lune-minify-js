# lune-minify-js

Simple [minify-js](https://github.com/wilsonzlin/minify-js) wrapper for lune runtime, with ffi edge feature.

## Example usage

```luau
local minify_js = require("./minify-js")
    .new("./minify-js/target/release/liblune_minify_js.so")

-- Throw error if syntax error in code
local result = minify_js:minify([[
    // Javascript code here
    return function (numberA, numberB) {
        return numberA + numberB
    }
]], minify_js.TopLevelMode.Global)

print(result) -- return ((a,b)=>a+ b)
```
