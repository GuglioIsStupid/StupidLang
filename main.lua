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
    print(line)
    table.insert(codeLines, line)
end

-- convert our code to lua code
luaCodeLines = ""
for i, line in ipairs(codeLines) do
    -- Comments
    line = line:gsub("//", "--")
    line = line:gsub("/%*", "--[[")
    line = line:gsub("%*/", "--]]")

    -- Functions
    line = line:gsub("console.print.line", "print")
    line = line:gsub("str", "tostring")
    if line:find("LoadLuaCode") then
        line = line .. "()"
    end
    line = line:gsub("LoadLuaCode", "load")

    -- Defined functions
    -- replace * with . if func in line
    if line:find("func") then
        line = line:gsub("%*", ".")
    end
    line = line:gsub("func", "function")
    line = line:gsub("{", " ")
    line = line:gsub("}", "end")
    -- if before end theres a normal character, add a new line
    line = line:gsub("end", "end\n")

    -- Variables
    line = line:gsub("var ", "")
    line = line:gsub("const", "local")

    -- love2d wrappers
    if line:find("love*") then
        line = line:gsub("%*", ".")
    end
    if line:find("*graphics*") then
        line = line:gsub("%*", ".")
    end
    if line:find("*draw") then
        line = line:gsub("%*", ".")
    end

    -- Operators. only replace if not in a string
    local quoteFound = false
    for i = 1, #line do
        local char = line:sub(i, i)
        if char == "\"" then
            quoteFound = not quoteFound
        end
        if char == "+" and not quoteFound then
            line = line:sub(1, i - 1) .. ".." .. line:sub(i + 1)
        end
    end

    if line:find("if") then
        line = line:gsub("if", "if ")
        line = line:gsub("!", "not ")
        line = line:gsub("{", "then")
        line = line:gsub("}", "end")
        line = line:gsub("then", "then\n")

        line = line .. "then"
    end

    luaCodeLines = luaCodeLines .. line .. "\n"
end

-- print out our lua code
print(luaCodeLines)

-- run our lua code
load(luaCodeLines)()