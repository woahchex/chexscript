local Function = {
    Namespace = {},
    Syntax = {},
    Parameters = {},

    __TYPE = "function"
}
Function.__index = Function

function Function.new(syntax, parentNamespace, parameters)
    local nf = {
        Namespace = Namespace.new(parentNamespace),
        Syntax = syntax or {},
        Parameters = parameters,
        Calls = 0
    }

    if not parentNamespace then
        nf.Namespace.print = Token.new("function", Function.new(
            {{Action = "print"},{Action = "return", Expression = Expression.new{Token.new("pointer", "text")}}},
            nf.Namespace,
            {"text"}
        ))

        nf.Namespace.strlen = Token.new("function", Function.new(
            {{Action = "strlen"}},
            nf.Namespace,
            {"text"}
        ))

        nf.Namespace.tostr = Token.new("function", Function.new(
            {{Action = "tostr"}},
            nf.Namespace,
            {"value"}
        ))

        nf.Namespace["if"] = Token.new("function", Function.new(
            {{Action = "if"}},
            nf.Namespace,
            {"__condition__", "__ifTrue__", "__ifFalse__"}
        ))

        nf.Namespace["for"] = Token.new("function", Function.new(
            {{Action = "for"}},
            nf.Namespace,
            {"__var__", "__start__", "__end__", "__func__"}
        ))
    end

    for _, parameter in pairs(parameters or {}) do
        nf.Namespace[parameter] = false
    end

    setmetatable(nf, Function)
    return nf
end


function Function:Call(arguments, forceScope)

    self.Calls = self.Calls + 1
    arguments = arguments or {}

    for index, arg in ipairs(arguments) do
        if self.Parameters[index] then
            self.Namespace[self.Parameters[index]] = arg
        end
    end

    local syntax = self.Syntax
    for i, command in ipairs(syntax) do
        
        if command.Action == "assign" then
            if not self.Namespace[command.Pointer:GetValue()] or forceScope then
                self.Namespace[command.Pointer:GetValue()] = command.Expression:Evaluate(self.Namespace)

                self.Namespace[command.Pointer:GetValue()].Origin = self.Namespace
            else
                local origin = self.Namespace[command.Pointer:GetValue()].Origin
                origin[command.Pointer:GetValue()] = command.Expression:Evaluate(self.Namespace)
                origin[command.Pointer:GetValue()].Origin = origin
            end
        end

        if command.Action == "call" then
            -- we have to evaluate the arguments before passing them in
            local evalArgs = {}
            for _, arg in ipairs(command.Arguments) do
                evalArgs[#evalArgs+1] = arg:Evaluate(self.Namespace)
            end
            local func = self.Namespace[command.Pointer:GetValue()]:GetValue()
            func:Call(evalArgs)
        end

        if command.Action == "return" then
            return command.Expression:Evaluate(self.Namespace)
        end


        ---------------------------------- LUA HELP FUNCS
        if command.Action == "print" then
            if type(self.Namespace.text:GetValue()) == "table" and self.Namespace.text:GetValue().__TYPE == "function" then
                self.Namespace.text = Token.generate("Function")
            end
            
            if self.Namespace.text:GetType()=="pointer" then
                print("null")
            else
                print(tostring(self.Namespace.text:GetValue()))
            end
            
        end

        if command.Action == "if" then
            local condition = self.Namespace.__condition__:GetValue()
            local ifTrue = self.Namespace.__ifTrue__ and self.Namespace.__ifTrue__:GetValue()
            local ifFalse = self.Namespace.__ifFalse__ and self.Namespace.__ifFalse__:GetValue()
            
            if condition then
                return ifTrue:Call()
            elseif ifFalse then
                return ifFalse:Call()
            end
        end

        if command.Action == "for" then
            local pointer = self.Namespace.__var__:GetValue()
            local fstart = self.Namespace.__start__:GetValue()
            local fend = self.Namespace.__end__:GetValue()
            local ffunc = self.Namespace.__func__:GetValue()

            table.insert(ffunc.Parameters, pointer)

            for z = fstart, fend do
                ffunc:Call{Token.generate(z)}
            end
        end

        if command.Action == "strlen" then
            return Token.generate(#self.Namespace.text:GetValue())
        end

        if command.Action == "tostr" then
            return Token.new("string", tostring(self.Namespace.value:GetValue()))
        end
    end

    for _, var in pairs(self.Parameters) do
        self.Namespace[var] = false
    end
end


return Function