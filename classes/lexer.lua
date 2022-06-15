local Lexer = {
    __WHITESPACE = " \n",
    __COMMENT = "..",
    __STRINGS = [["']],
    __POINTER = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
    __POINTERSTART = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
    __NUMBERSTART = "0123456789",
    __NUMBER = "0123456789.",

    __SPECIALCHARS = { -- MAX LENGTH 3
        ["("] = Token.new("lparen"),
        [")"] = Token.new("rparen"),
        ["{"] = Token.new("lbrack"),
        ["}"] = Token.new("rbrack"),

        ["="] = Token.new("equals"),
        ["+"] = Token.new("add"),
        ["-"] = Token.new("sub"),
        ["/"] = Token.new("div"),
        ["*"] = Token.new("mul"),
        [","] = Token.new("comma"),

        ["**"] = Token.new("pow"),

        ["ret"] = Token.new("return"),
        ["fun"] = Token.new("constructor"),

        [">="] = Token.new("igreaterthan"),
        ["<="] = Token.new("ilessthan"),
        [">"] = Token.new("greaterthan"),
        ["<"] = Token.new("lessthan"),
        ["=="] = Token.new("identical"),

        ["and"] = Token.new("AND"),
        ["or"] = Token.new("OR"),

        ["not"] = Token.new("NOT")
    },
}

function Lexer.Process(code)
    local ERR = false
    code = " " .. code .. " "
    local pos = 1
    local lexerResult = {}
    while pos <= #code do
        local c = code:sub(pos,pos)

        if code:sub(pos, pos+1) == Lexer.__COMMENT then
            repeat
                pos = pos + 1
            until code:sub(pos, pos+1) == Lexer.__COMMENT or code:sub(pos, pos) == "\n" or pos > #code

            c = code:sub(pos,pos)
        end

        for length = 3, 1, -1 do
            if Lexer.__SPECIALCHARS[code:sub(pos, pos + (length-1))] then
                table.insert(lexerResult, Lexer.__SPECIALCHARS[code:sub(pos, pos + (length-1))])
                pos = pos + length - (length > 1 and 0 or 1)
                c = code:sub(pos, pos)
                break
            end
        end

        if isIn(Lexer.__WHITESPACE, c) then
            local count = 1
            repeat
                count = count + 1
                pos = pos + 1
            until not isIn(Lexer.__WHITESPACE, code:sub(pos,pos)) or pos > #code
            --table.insert(lexerResult, {"ws", count})
            pos = pos - 1
            c = code:sub(pos,pos)
        end

        if isIn(Lexer.__STRINGS, c) then
            local strStart = pos+1
            local stringType = c
            pos = pos + 1
            while not isIn(stringType, code:sub(pos,pos)) and pos <= #code do
                pos = pos + 1
            end

            if pos > #code then
                ERR = true
            end

            table.insert(lexerResult, Token.new("string", code:sub(strStart, pos-1)) )
            c = code:sub(pos,pos)
        end

        if isIn(Lexer.__POINTERSTART, c) then
            local idStart = pos
            while isIn(Lexer.__POINTER, code:sub(pos,pos)) and pos <= #code do
                pos = pos + 1
            end

            pos = pos - 1
            table.insert(lexerResult, Token.new("pointer", code:sub(idStart, pos)) )

            c = code:sub(pos, pos)
        end

        if isIn(Lexer.__NUMBERSTART, c) then
            local idStart = pos
            while isIn(Lexer.__NUMBER, code:sub(pos,pos)) do
                pos = pos + 1
            end

            pos = pos - 1
            table.insert(lexerResult, Token.new("number", tonumber(code:sub(idStart, pos))) )
        end

        -------------------------------------------------------
        pos = pos + 1
    end

    -- clear leading/trailing whitespace
    --table.remove(lexerResult, 1)
    --lexerResult[#lexerResult] = nil

    --lexerResult[#lexerResult+1] = Token.new("empty")

    -- apply a simple metatable to negate nil indices
    setmetatable(lexerResult, {
        __index = function ()
            return Token.new("eof")
        end
    })

    return lexerResult, ERR
end

return Lexer