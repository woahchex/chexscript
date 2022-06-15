local Lexer = {
    __STRINGS = [["']],
    __POINTER = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
    __POINTERSTART = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
    __NUMBERSTART = "0123456789.",
    __NUMBER = "0123456789.-",
    __COMMENT = "..",
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
        ["%"] = Token.new("mod"),
        ["**"] = Token.new("pow"),

        [","] = Token.new("comma"),
        [":"] = Token.new("at"),

        [">="] = Token.new("igreaterthan"),
        ["<="] = Token.new("ilessthan"),
        [">"] = Token.new("greaterthan"),
        ["<"] = Token.new("lessthan"),
        ["=="] = Token.new("identical"),

        ["&"] = Token.new("AND"),
        ["|"] = Token.new("OR"),
        ["!"] = Token.new("NOT")
    },

    __SPECIALWORDS = {
        ["and"] = Token.new("AND"),
        ["or"] = Token.new("OR"),

        ["not"] = Token.new("NOT"),

        ["ret"] = Token.new("return"),
        ["fun"] = Token.new("constructor"),
    }
}

function Lexer.Process(code)
    local tokens = {}

    local p = 0

    while p < #code do
        local done = false
        p = p + 1
        ---------------------------------- COMMENTS
        if code:sub(p, p+#Lexer.__COMMENT-1) == Lexer.__COMMENT then
            repeat
                p = p + 1
            until code:sub(p, p) == "\n" or p > #code
        end

        ---------------------------------- SPECIAL SYMBOLS
        local negativeCancel = code:sub(p,p)=="-" and isIn(Lexer.__NUMBER, code:sub(p+1,p+1)) and not isIn(Lexer.__POINTER, code:sub(p-1,p-1))
        if not negativeCancel then
            for length = 2, 0, -1 do
                if Lexer.__SPECIALCHARS[code:sub(p, p+length)] then
                    table.insert(tokens, Lexer.__SPECIALCHARS[code:sub(p, p+length)])
                    done = true
                    p = p + length
                    break
                end
            end
        end

        for length = 2, 0, -1 do
            if Lexer.__SPECIALWORDS[code:sub(p, p+length)] and not isIn(Lexer.__POINTER, code:sub(p+length+1,p+length+1)) and not isIn(Lexer.__POINTER, code:sub(p-1,p-1)) then
                table.insert(tokens, Lexer.__SPECIALWORDS[code:sub(p, p+length)])
                done = true
                p = p + length
                break
            end
        end

        ---------------------------------- STRINGS
        if not done and isIn(Lexer.__STRINGS, code:sub(p,p)) then
            local strStart = p+1
            local stringType = code:sub(p,p)
            p = strStart
            while not isIn(stringType, code:sub(p,p)) and p <= #code do
                p = p + 1
            end

            table.insert(tokens, Token.new("string", code:sub(strStart, p-1)))
            done = true
        end

        ---------------------------------- POINTERS
        if not done and isIn(Lexer.__POINTERSTART, code:sub(p,p)) then
            local pStart = p
            while isIn(Lexer.__POINTER, code:sub(p,p)) and p <= #code do
                p = p + 1
            end

            if Lexer.__SPECIALWORDS[code:sub(pStart, p-1)] then
                -- oops! picked up a keyword by mistake
                table.insert(tokens, Lexer.__SPECIALWORDS[code:sub(pStart, p-1)])
            else
                local pointerToken = Token.new("pointer", code:sub(pStart, p-1))

                table.insert(tokens, pointerToken)
    
                p = p - 1
                done = true
    
                -- special number shorthand
                if tokens[#tokens-1] and tokens[#tokens-1]:GetType() == "number" and isIn(Lexer.__NUMBER, code:sub(pStart-1,pStart-1)) then
                    table.insert(tokens, #tokens, Lexer.__SPECIALCHARS["*"])
                end
    
                -- negative variable?
                if tokens[#tokens-1] and tokens[#tokens-1]:GetType() == "sub" then
                    tokens[#tokens-1] = Token.new("number", -1)
                    table.insert(tokens, #tokens, Lexer.__SPECIALCHARS["*"])                
                end
            end
        end

        ---------------------------------- NUMBERS
        local negativeNumber = code:sub(p,p)=="-" and isIn(Lexer.__NUMBER, code:sub(p+1,p+1)) and not isIn(Lexer.__POINTER, code:sub(p-1,p-1))
        if not done and (isIn(Lexer.__NUMBERSTART, code:sub(p,p)) or negativeNumber) then
            local pStart = p
            while isIn(Lexer.__NUMBER, code:sub(p,p)) and p <= #code do
                p = p + 1
            end

            local numToken = Token.new("number", tonumber(code:sub(pStart, p-1)))

            table.insert(tokens, numToken)

            p = p - 1
            done = true
        end
    end

    return tokens
end

return Lexer