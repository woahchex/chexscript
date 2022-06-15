local Namespace = {

}
Namespace.__index = Namespace

function Namespace.new(parent, vars)
    vars = vars or {}
    vars.__index = function (tab, key)
        return vars[key]
    end
    setmetatable(vars, parent or Namespace)
    return vars
end

return Namespace