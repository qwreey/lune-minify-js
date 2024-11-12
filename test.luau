local minify_js = require("./")
    .new("./target/release/liblune_minify_js.so")

-- Throw error if syntax error in code
local result = minify_js:minify([[
    // Javascript code here
    return function (numberA, numberB) {
        return numberA + numberB
    }
]], minify_js.TopLevelMode.Global)

print(result) -- return ((a,b)=>a+ b)

minify_js:drop() -- Drop library datas
