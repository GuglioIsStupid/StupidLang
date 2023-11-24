local codeStr = [[
// comments are two forward slashes
/* 
multi-line comments are slash-star, star-slash 
*/

// functions are defined with the func keyword
func add(a, b) {
    return a + b
}

//console.print.line(add(1, 2) + str(add(3, 4)))

// varaibles are defined with the var keyword (global)
var a = 1
var b = 2
var c = a + b

// vars with const keyword are constants (local)
const d = 3

//console.print.line(c)

// to call a lua function, we just use LoadLuaCode
//LoadLuaCode("print('hello world')")

// more advanced example
func love*draw() {
    love*graphics*print("Hello World!", 400, 300)
}

if (!love) {
    console.print.line("love is not defined")
}

// classes
class Person {
    func new(name) {
        this.name = name
    }

    func sayHello() {
        console.print.line("Hello, my name is " + this.name)
    }
}

var p = Person("Bob")
p:sayHello()
]]

-- load main.stupid if it exists
if love.filesystem.getInfo("main.stupid") then
    codeStr = love.filesystem.read("main.stupid")
end

strMetatable = getmetatable("")
strMetatable.__add = function(a, b)
    return a .. b
end

-- convert our code to lua code
codeLines = {}
for line in codeStr:gmatch("[^\r\n]+") do
    table.insert(codeLines, line)
end

-- convert our code to lua code
luaCodeLines = ""

class = require("libs.class")
local inFunction, inIf, inFor, inWhile, inClass = false, false, false, false, false
local curClass = nil
for i, line in ipairs(codeLines) do
    -- Comments
    line = line:gsub("//", "--")
    line = line:gsub("/%*", "--[[")
    line = line:gsub("%*/", "--]]")

    -- Predefined functions
    line = line:gsub("console.print.line", "print")
    line = line:gsub("str", "tostring")
    line = line:gsub("LoadLuaCode", "load")

    -- Defined functions
    -- replace * with . if func in line
    if line:find("func") then
        inFunction = true
    end

    if inFunction then
        --line = line:gsub("%*", ".")
        line = line:gsub("{", " ")
        if line:find("}") then
            line = line:gsub("}", "\nend") --\n for safety
            inFunction = false
        end
    end

    line = line:gsub("func", "function")

    -- Variables
    line = line:gsub("var ", "")
    line = line:gsub("const", "local")

    -- love2d wrappers
    if line:find("love*") then
        line = line:gsub("%*", ".")
    end


    -- Operators. only replace if not in a string


    if line:find("if") then
        inIf = true
        -- replace { with then
        line = line:gsub("{", "then")
    end

    if inIf then
        line = line:gsub("if", "if ")
        line = line:gsub("!", "not ")
        line = line:gsub("{", "then")
        if line:find("}") then
            line = line:gsub("}", "\nend") --\n for safety
            inIf = false
        end

        -- || and &&
        line = line:gsub("||", "or")
        line = line:gsub("&&", "and")
    end

    if line:find("class ") then
        inClass = true
    
        -- get class name
        curClass = line:match("class (.*)")
        -- replace class with class:extend()
        line = line:gsub("class " .. curClass, curClass .. " = class:extend()")
    end

    if inClass then
        -- replace func with function
        line = not line:find("function") and line:gsub("func", "function") or line
        if line:find("function") then
            --add curClass before function name
            local funcName = line:match("function (.*)%(")
            line = line:gsub("function " .. funcName, "function " .. curClass .. ":" .. funcName)
        end

        -- replace this with self
        line = line:gsub("this", "self")

        -- replace } with nothing, and set inClass to false
        if line:find("}") then
            line = line:gsub("}", "")
            inClass = false
        end
    end

    -- if any }, just replace with end
    line = line:gsub("}", "end")

    if line:find("if") and not line:find("then") then
        line = line .. " then"
    end

    luaCodeLines = luaCodeLines .. line .. "\n"
end

-- print out our lua code
print(luaCodeLines)

-- run our lua code
load(luaCodeLines)()