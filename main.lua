require("classes/helpers")
_G.Token = require("classes/token")
_G.Expression = require("classes/expression")
_G.Parser = require("classes/parser")
_G.Namespace = require("classes/namespace")
_G.Function = require("classes/function")
_G.Lexer = require("classes/lexer2")

--- write code here
local testCode = [[
    print("hello world!")

    .. some code samples


    .................. SORT-OF CLASSES

    Person = {
        new = fun age name {
            ret {Age = age   name = name}
        }
    }

    myPerson1 = Person:new(20, "John")
    myPerson2 = Person:new(25, "Jane")


    .................. FIZZBUZZ

    FizzBuzz = fun n {
        for(i, 1, n, {
            out = {ret i%3==0 and "Fizz"or""}() + {ret i%5==0 and "Buzz"or""}()
            if(strlen(out)==0, {out=tostr(i)})
            print(out)
        })
    }

    .. FizzBuzz(100)

]]



local testTokens = Lexer.Process(testCode)
local testSyntax = Parser.Parse(testTokens)
local testFunc = Function.new(testSyntax)


testFunc:Call()
