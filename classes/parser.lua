local Parser = {
    __EXPRESSIONEND = {
        {"pointer", "pointer"},
        {"rparen", "pointer"},
        {"rbrack", "pointer"},
        {"number", "pointer"},
        {"string", "pointer"},
        {"pointer", "return"},
        {"rparen", "return"},
        {"rbrack", "return"},
        {"number", "return"},
        {"string", "return"},
    },

}

function Parser.Parse(tokens)
    local p = 1
    local syntaxTree = {}

    while tokens[p] do

        ------------------------------------------ EMBEDDED POINTERS
        if tokens[p]:GetType() == "at" then
            
        end

        ------------------------------------------ ASSIGN
        if tokens[p]:GetType() == "pointer" and tokens[p+1] and tokens[p+1]:GetType() == "equals" then
            
            local newExpression, endPos = findExpression(tokens, p+2)

            syntaxTree[#syntaxTree+1] = {
                Action = "assign",
                Pointer = tokens[p],
                Expression = newExpression
            }

            p = endPos
        end

        --------------------------------------- RETURN STATEMENTS
        if tokens[p]:GetType() == "return" then
            local newExpression, endPos = findExpression(tokens, p+1)

            syntaxTree[#syntaxTree+1] = {
                Action = "return",
                Expression = newExpression
            }


        end


        --------------------------------------- FUNCTION CALL
        if tokens[p]:GetType() == "pointer" and tokens[p+1] and tokens[p+1]:GetType() == "lparen" then
            local lparen = p+1
            local rparen = findParenBounds(tokens, lparen)
            local buffer = lparen+1
            local arguments = {}
            if rparen-lparen>1 then
                local brackLayer = 0
                for tracker = lparen+1, rparen-1 do
                    if tokens[tracker]:GetType()=="lbrack" then
                        brackLayer=brackLayer+1
                    end
                    if tokens[tracker]:GetType()=="rbrack" then
                        brackLayer=brackLayer-1
                    end
                    if tokens[tracker]:GetType()=="comma" and brackLayer <= 0 then
                        local newExpr = Expression.new(slice(tokens, buffer, tracker-1))
                        buffer = tracker+1
                        arguments[#arguments+1] = newExpr
                    end
                end
                local newExpr = Expression.new(slice(tokens, buffer, rparen-1))
                arguments[#arguments+1] = newExpr
            end

            syntaxTree[#syntaxTree+1] = {
                Action = "call",
                Pointer = tokens[p],
                Arguments = arguments
            }

            p = rparen
        end

        p = p + 1
    end

    return syntaxTree
end

return Parser