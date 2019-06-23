require 'busted.runner'()

local config = require 'nelua.configer'.get()
local assert = require 'spec.tools.assert'

describe("Nelua should parse and generate Lua", function()

it("empty file", function()
  assert.generate_lua("", "")
end)
it("return", function()
  assert.generate_lua("return")
  assert.generate_lua("return 1")
  assert.generate_lua("return 1, 2")
end)
it("number", function()
  assert.generate_lua("return 1, 1.2, 1e2, 0x1f, 0b10",
                      "return 1, 1.2, 1e2, 0x1f, 0x2")
  assert.generate_lua("return 0x3p5, 0x3.5, 0x3.5p7, 0xfa.d7p-5, 0b11.11p2",
                      "return 0x60, 3.3125, 0x1a8, 7.8387451171875, 0xf")
  assert.generate_lua("return 0x0, 0xffffp4",
                      "return 0x0, 0xffff0")
  assert.generate_lua("return 0xffffffffffffffff.001",
                      "return 18446744073709551615.000244140625")
end)
it("string", function()
  assert.generate_lua([[return 'a', "b", [=[c]=] ]], [[return "a", "b", "c"]])
  assert.generate_lua([[return "'", '"']])
  assert.generate_lua([[return "'\1", '"\1']])
end)
it("boolean", function()
  assert.generate_lua("return true, false")
end)
it("nil", function()
  assert.generate_lua("return nil")
end)
it("varargs", function()
  assert.generate_lua("return ...")
end)
it("table", function()
  assert.generate_lua("return {}")
  assert.generate_lua('return {a, "b", 1}')
  assert.generate_lua('return {a = 1, [1] = 2}')
end)
it("function", function()
  assert.generate_lua("return function() end")
  assert.generate_lua("return function()\n  return\nend")
  assert.generate_lua("return function(a, b, c) end")
end)
it("indexing", function()
  assert.generate_lua("return a.b")
  assert.generate_lua("return a[b], a[1]")
  assert.generate_lua('return ({})[1]', 'return ({})[1]')
  assert.generate_lua('return ({}).a', 'return ({}).a')
end)
it("call", function()
  assert.generate_lua("f()")
  assert.generate_lua("return f()")
  assert.generate_lua("f(g())")
  assert.generate_lua("f(a, 1)")
  assert.generate_lua("f 'a'", 'f("a")')
  assert.generate_lua("f {}", 'f({})')
  assert.generate_lua('a.f()')
  assert.generate_lua('a.f "s"', 'a.f("s")')
  assert.generate_lua("a.f {}", "a.f({})")
  assert.generate_lua("a:f()")
  assert.generate_lua("return a:f()")
  assert.generate_lua("a:f(a, 1)")
  assert.generate_lua('a:f "s"', 'a:f("s")')
  assert.generate_lua("a:f {}", 'a:f({})')
  assert.generate_lua('("a"):len()', '("a"):len()')
  assert.generate_lua('g()()', 'g()()')
  assert.generate_lua('({})()', '({})()')
  assert.generate_lua('("a"):f()', '("a"):f()')
  assert.generate_lua('g():f()', 'g():f()')
  assert.generate_lua('({}):f()', '({}):f()')
end)
it("if", function()
  assert.generate_lua("if a then\nend")
  assert.generate_lua("if a then\nelseif b then\nend")
  assert.generate_lua("if a then\nelseif b then\nelse\nend")
end)
it("switch", function()
  assert.generate_lua("switch a case b then else end", [[
local __switchval1 = a
if __switchval1 == b then
else
end]])
  assert.generate_lua("switch a case b then f() case c then g() else h() end",[[
local __switchval1 = a
if __switchval1 == b then
  f()
elseif __switchval1 == c then
  g()
else
  h()
end]])
end)
it("do", function()
  assert.generate_lua("do\n  return\nend")
end)
it("while", function()
  assert.generate_lua("while a do\nend")
end)
it("repeat", function()
  assert.generate_lua("repeat\nuntil a")
end)
it("for", function()
  assert.generate_lua("for i=1,10 do\nend")
  assert.generate_lua("for i=1,10,2 do\nend")
  assert.generate_lua("for i in a, f() do\nend")
  assert.generate_lua("for i, j, k in f() do\nend")
end)
it("break", function()
  assert.generate_lua("while true do\n  break\nend")
end)
it("goto", function()
  assert.generate_lua("::mylabel::\ngoto mylabel")
end)
it("variable declaration", function()
  assert.generate_lua("local a")
  assert.generate_lua("local a = 1")
  assert.generate_lua("local a, b, c = 1, 2, nil")
  assert.generate_lua("local a, b, c = 1, 2, 3")
  assert.generate_lua("var a", "local a")
  assert.generate_lua("var a, b = 1", "local a, b = 1, nil")
  assert.generate_lua("var a, b = 1, 2", "local a, b = 1, 2")
  assert.generate_lua("function f() var a end", "function f()\n  local a\nend")
end)
it("assignment", function()
  assert.generate_lua("a = 1")
  assert.generate_lua("a, b = 1, 2")
  assert.generate_lua("a.b, a[1] = x, y")
end)
it("function definition", function()
  assert.generate_lua("local function f()\nend")
  assert.generate_lua("function f()\nend")
  assert.generate_lua("function f(a)\nend")
  assert.generate_lua("function f(a, b, c)\nend")
  assert.generate_lua("function a.f()\nend")
  assert.generate_lua("function a.b.f()\nend")
  assert.generate_lua("function a:f()\nend")
  assert.generate_lua("function a.b:f()\nend")
  assert.generate_lua(
    "function f(a: integer): integer\nreturn 1\nend",
    "function f(a)\n  return 1\nend")
end)
it("unary operators", function()
  assert.generate_lua("return not a")
  assert.generate_lua("return -a")
  assert.generate_lua("return ~a")
  assert.generate_lua("return #a")
end)
it("binary operators", function()
  assert.generate_lua("return a or b, a and b")
  assert.generate_lua("return a ~= b, a == b")
  assert.generate_lua("return a <= b, a >= b")
  assert.generate_lua("return a < b, a > b")
  assert.generate_lua("return a | b, a ~ b, a & b")
  assert.generate_lua("return a << b, a >> b")
  assert.generate_lua("return a + b, a - b")
  assert.generate_lua("return a * b, a / b, a // b")
  assert.generate_lua("return a % b")
  assert.generate_lua("return a ^ b")
  assert.generate_lua("return a .. b")
end)
it("lua 5.1 compat operators", function()
  config.lua_version = '5.1'
  assert.generate_lua("return ~a", "return bit.bnot(a)")
  assert.generate_lua("return a // b", "return math.floor(a / b)")
  assert.generate_lua("return a ^ b", "return math.pow(a, b)")
  assert.generate_lua("return a | b", "return bit.bor(a, b)")
  assert.generate_lua("return a & b", "return bit.band(a, b)")
  assert.generate_lua("return a ~ b", "return bit.bxor(a, b)")
  assert.generate_lua("return a << b", "return bit.lshift(a, b)")
  assert.generate_lua("return a >> b", "return bit.rshift(a, b)")
  config.lua_version = '5.3'
end)

end)
