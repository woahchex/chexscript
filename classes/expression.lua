local Expression = {
    __MATHOPS = {
        add = function(a, b)
            --print(type(a), type(b))
            if type(a) == "string" and type(b) == "string" then
                return a .. b
            end
            return (a or 0) + (b or 0)
        end,
        sub = function(a, b) return (a or 0) - (b or 0) end,
        div = function(a, b) return (a or 0) / (b or 0) end,
        mul = function(a, b) return (a or 0) * (b or 0) end,
        pow = function(a, b) return (a or 0) ^ (b or 0) end,
        mod = function(a, b) return (a or 0) % (b or 0) end
    },

    __LOGICOPS = {
        lessthan = function(a, b) return a < b end,
        greaterthan = function(a, b) return a > b end,
        ilessthan = function(a, b) return a <= b end,
        igreaterthan = function(a, b) return a >= b end,
        identical = function(a, b) return a == b end,

        AND = function(a, b) return a and b end,
        OR = function(a, b) return a or b end,

        NOT = function(a) return not a end
    }
}

--[[
    -Token types reminder:
    MATH [add sub div mul mod pow]
    BRACKETS [lparen rparen lbrack rbrack]
    POINTERS [pointer]
    LOGIC [and or not identical lessthan greaterthan ilessthan igreaterthan]
]]


function Expression.new(tokens)
    tokens = tokens and clone(tokens) or {}
    setmetatable(tokens, Expression)
    return tokens
end
Expression.__index = Expression

function Expression:Evaluate(namespace)
    namespace = namespace or {}
    ---------------------------------- SINGLE TOKEN
    if #self == 1 then
        
        if self[1]:GetType()=="pointer" and self[1]:GetPointerValue(namespace):GetValue() then
            return self[1]:GetPointerValue(namespace)
        else
            return self[1]
        end
    end
    
    --print(tabstring(self))

    ---------------------------------- FUNCTIONS
    local constructor = self:Find("constructor")
    if constructor then
        local parameters = {}
        local lbrack = self:Find("lbrack", constructor)
        local rbrack = findBracketBounds(self, lbrack)

        for track = constructor+1, lbrack-1 do
            if self[track]:GetType() == "pointer" then
                table.insert(parameters, self[track]:GetValue())
            end
        end

        local funcTokens = slice(self, lbrack+1, rbrack-1)
        local funcSyntax = Parser.Parse(funcTokens)
        
        local newFuncToken = Token.new("function",
            Function.new(funcSyntax, namespace, parameters)
        )
        
        local leftSlice = slice(self, 1, constructor-1)
        local rightSlice = slice(self, rbrack+1, #self)

        local finalExpression = concat{leftSlice, {newFuncToken}, rightSlice}

        return finalExpression:Evaluate(namespace)
    end

    -- also could be the shorthand function
    -- brackets search time
    local lbrack = self:Find("lbrack", constructor)
    local rbrack
    if lbrack then
        --bracket finding time again
        rbrack = findBracketBounds(self, lbrack)

        
        local funcTokens = slice(self, lbrack+1, rbrack-1)
        
        local funcSyntax = Parser.Parse(funcTokens)

        

        local newFuncToken = Token.new("function",
            Function.new(funcSyntax, namespace)
        )
        
        local leftSlice = slice(self, 1, lbrack-1)
        local rightSlice = slice(self, rbrack+1, #self)

        local finalExpression = concat{leftSlice, {newFuncToken}, rightSlice}


        
        return finalExpression:Evaluate(namespace)
    end



    ---------------------------------- POINTERS
    local at = self:Find("at")
    if at then
        local func = self[at-1]:GetPointerValue(namespace):GetValue()
        local varName = self[at+1]:GetValue()

        if func.Calls == 0 then func:Call({}, true) end

        local leftSlice = slice(self, 1, at-2)
        local rightSlice = slice(self, at+2, #self)

        local newVal = rawget(func.Namespace, varName)

        local finalExpression = concat{leftSlice, {newVal}, rightSlice}


        return finalExpression:Evaluate(namespace)
    end

    local pointer = self:Find("pointer")
    if pointer then
        local newExpression = clone(self)
        while pointer do
            newExpression[pointer] = newExpression[pointer]:GetPointerValue(namespace)
            pointer = newExpression:Find("pointer")
        end
        return newExpression:Evaluate(namespace)
    end
   
    ---------------------------------- EMBEDDED FUNCTION CALLS
    local func = self:Find("function")
    if func and self[func+1] and self[func+1]:GetType() == "lparen" then
        
        local lparen = func+1
        local rparen = findParenBounds(self, lparen)

        local buffer = lparen+1
        local arguments = {}
        
        if rparen-lparen>1 then
            for tracker = lparen+1, rparen-1 do
                
                if self[tracker]:GetType()=="comma" then
                    local newExpr = Expression.new(slice(self, buffer, tracker-1))
                    buffer = tracker+1
                    arguments[#arguments+1] = newExpr
                end
            end
            local newExpr = Expression.new(slice(self, buffer, rparen-1))
            arguments[#arguments+1] = newExpr
        end

        local evalArgs = {}
        for _, arg in ipairs(arguments) do
            evalArgs[#evalArgs+1] = arg:Evaluate(namespace)
        end

        local evalToken = self[func]:GetValue():Call(evalArgs)
        
        local leftSlice = slice(self, 1, func-1)
        local rightSlice = slice(self, rparen+1, #self)

        local finalExpression = concat{leftSlice, {evalToken}, rightSlice}

        return finalExpression:Evaluate(namespace)
    end

    ----------------------------------- PARENTHESES
    local lparen = self:Find("lparen")
    if lparen then
        local rparen
        
        -- parentheses search time
        local count = 1
        for tracker = lparen+1, #self do
            if self[tracker]:GetType() == "lparen" then
                count = count + 1
            elseif self[tracker]:GetType() == "rparen" then
                count = count - 1
                if count == 0 then rparen = tracker break end
            end
        end

        local newExpression = slice(self, lparen+1, rparen-1)

        local insertToken = newExpression:Evaluate(namespace)
        local leftSlice = slice(self, 1, lparen-1)
        local rightSlice = slice(self, rparen+1, #self)

        local finalExpression = concat{leftSlice, {insertToken}, rightSlice}
        
        return finalExpression:Evaluate(namespace)
    end

    --------------------------------- MATH
    local mathOperators = {"pow", "mul", "div", "mod", "sub", "add"}
    
    for _, op in ipairs(mathOperators) do
        local pos = self:Find(op)
        if pos then
            local mathResult = Token.generate(
                self.__MATHOPS[op](self[pos-1]:GetValue(), self[pos+1]:GetValue())
            )

            local leftSlice = slice(self, 1, pos-2)
            local rightSlice = slice(self, pos+2, #self)

            local finalExpression = concat{leftSlice, {mathResult}, rightSlice}

            return finalExpression:Evaluate(namespace)
        end
    end


        --------------------------------- LOGIC
        -- NOT needs a little bit of extra care
        local notPos = self:Find("NOT")
        if notPos then
            local result = Token.generate(self.__LOGICOPS["NOT"](self[notPos+1]:GetValue()))
            local leftSlice = slice(self, 1, notPos-1)
            local rightSlice = slice(self, notPos+2, #self)
            
            local finalExpression = concat{leftSlice, {result}, rightSlice}
            return finalExpression:Evaluate(namespace)
        end


        local logicOperators = {"identical", "lessthan", "ilessthan", "greaterthan", "igreaterthan", "AND", "OR"}
    
        for _, op in ipairs(logicOperators) do
            local pos = self:Find(op)
            if pos then
                local logicResult = Token.generate(
                    self.__LOGICOPS[op](self[pos-1]:GetValue(), self[pos+1]:GetValue())
                )
    
                local leftSlice = slice(self, 1, pos-2)
                local rightSlice = slice(self, pos+2, #self)
    
                local finalExpression = concat{leftSlice, {logicResult}, rightSlice}
    
                return finalExpression:Evaluate(namespace)
            end
        end
    


    -- why would it get here?
    
    return 0
end

function Expression:Find(typ, start)
    --print(tabstring(self))
    for i = start or 1, #self do
        if type(self[i]) == "table" and self[i]:GetType() == typ then
            return i
        end
    end
    return false
end


function Expression:Insert(token)
    self[#self+1] = token
end

return Expression