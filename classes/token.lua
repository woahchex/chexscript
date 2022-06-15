local Token = {Origin = {}}

function Token.new(type, value)
    local token = {type, value}
    setmetatable(token, Token)
    return token
end
Token.__index = Token

local typeMappings = {
    string = "string",
    number = "number",
    boolean = "bool"
}
function Token.generate(value)
    return Token.new(typeMappings[type(value)] or "unknown", value)
end


function Token:GetType()
    return self[1]
end

function Token:GetValue()
    return self[2]
end

function Token:GetPointerValue(namespace)
    return namespace[self:GetValue()] or Token.new("bool", false)
end

return Token