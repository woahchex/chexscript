function _G.clone(tab)
    local nt = {}
    for k, v in pairs(tab) do
        nt[k] = v
    end
    setmetatable(nt, getmetatable(tab))
    return nt
end

function _G.concat(tabs)
    local nt = {}

    for _, tab in ipairs(tabs) do
        for k, v in ipairs(tab) do
            nt[#nt+1] = v
        end
    end

    setmetatable(nt, getmetatable(tabs[1]))
    return nt
end


function _G.tabstring(tab, indent)
    if not tab then return end
    indent = indent or 0
    if indent > 30 then return "" end
    local output = ""
    for k, v in pairs(tab) do
        if k ~= "Origin" then
            local vVal = type(v) == "table" and "\n" .. tabstring(v, indent + 2) or tostring(v)
            output = output .. string.rep(" ", indent) .. tostring(k) .. ": " .. vVal .. "\n"
        end
    end
    return output:sub(1, #output-1)
end

function _G.slice(tab, i, j)
    local nt = {}
    local x = 1
    for v = i, j do
        nt[x] = tab[v]
        x = x + 1
    end
    setmetatable(nt, getmetatable(tab))
    return nt
end

function _G.checkForToken(type, expression)
    for i, v in pairs(expression) do
        if v[1] == type then
            return i
        end
    end
    return false
end


function _G.isIn(str, substr)
    -- make a better implementation later idk
    substr = type(substr) == "table" and substr or {substr}

    for pos = 1, #str do

        for _, sub in ipairs(substr) do
            if str:sub(pos, pos+#sub-1) == sub then
                return true
            end
        end
    end

    return false
end


function _G.strip(text)
    return text:gsub("^%s*(.-)%s*$", "%1")
end


function _G.findParenBounds(tokens, lparen)
    -- parentheses search time
    local count = 1
    local rparen = false
    for tracker = lparen+1, #tokens do
        if tokens[tracker]:GetType() == "lparen" then
            count = count + 1
        elseif tokens[tracker]:GetType() == "rparen" then
            count = count - 1
            if count == 0 then rparen = tracker break end
        end
    end
    return rparen
end

function _G.findBracketBounds(tokens, lbrack)
    -- parentheses search time
    local count = 1
    local rbrack = false
    for tracker = lbrack+1, #tokens do
        if tokens[tracker]:GetType() == "lbrack" then
            count = count + 1
        elseif tokens[tracker]:GetType() == "rbrack" then
            count = count - 1
            if count == 0 then rbrack = tracker break end
        end
    end
    return rbrack
end


function _G.findExpression(tokens, p)
    local startPos = p
    local endPos

    local newExpression = Expression.new()

    local endSeq = {
        pointer = true,
        number = true,
        string = true,
        rparen = true,
        rbrack = true
    }

    local endSeq2 = {
        ["pointer"] = true,
        ["return"] = true
    }
    
    -- This bit is for detecting the end of expressions
    local makingFunc = 0
    local tracker = startPos
    while tracker <= #tokens do
        newExpression:Insert(tokens[tracker])

        if tokens[tracker]:GetType()=="lparen" then
            local rparen = findParenBounds(tokens, tracker)
            local lparen = tracker

            for p2 = lparen+1, rparen-1 do
                newExpression:Insert(tokens[p2])
                tracker = p2
            end
        end

        if tokens[tracker]:GetType()=="constructor" then
            makingFunc = makingFunc + 1
        end

        if tokens[tracker]:GetType()=="lbrack" then
            local rbrack = findBracketBounds(tokens, tracker)
            local lbrack = tracker

            for p2 = lbrack+1, rbrack-1 do
                newExpression:Insert(tokens[p2])
                tracker = p2
            end
        end

        if tokens[tracker]:GetType()=="rbrack" then
            makingFunc = makingFunc - 1
        end

        if endSeq[tokens[tracker]:GetType()] and tokens[tracker+1] and endSeq2[tokens[tracker+1]:GetType()] and makingFunc<=0 then
            endPos = tracker
            break
        end

        tracker = tracker + 1
    end
    endPos = endPos or #tokens

    return newExpression, endPos
end