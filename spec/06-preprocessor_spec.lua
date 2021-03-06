require 'busted.runner'()

local assert = require 'spec.tools.assert'

describe("Nelua preprocessor should", function()

it("evaluate expressions", function()
  assert.ast_type_equals([=[
    local a = #['he' .. 'llo']#
    local b = #[math.sin(-math.pi/2)]#
    local c = #[true]#
    local d, d2, d3 = #[1.5e-30]#, #[1.5]#, #[1e-30]#
    local e = #[aster.Number{'dec','1'}]#
  ]=], [[
    local a = 'hello'
    local b = -1
    local c = true
    local d, d2, d3 = 1.5e-30, 1.5, 1e-30
    local e = 1
  ]])
  assert.ast_type_equals([=[
    local a: [10]integer
    a[#[0]#] = 1
  ]=], [[
    local a: [10]integer
    a[0] = 1
  ]])
  assert.analyze_error("local a = #[function() end]#", "unable to convert preprocess value of lua type")
end)

it("evaluate names", function()
  assert.ast_type_equals([[
    #|'print'|# 'hello'
  ]], [[
    print 'hello'
  ]])
  assert.ast_type_equals([[
    local a <#|'codename'|# 'a'>
    local b <codename 'b'>
    local c <#|'codename'|##['c']#>
  ]], [[
    local a <codename 'a'>
    local b <codename 'b'>
    local c <codename 'c'>
  ]])
end)

it("parse if", function()
  assert.ast_type_equals("##[[ if true then ]] local a = 1 ##[[ end ]]", "local a = 1")
  assert.ast_type_equals("##[[ if false then ]] local a = 1 ##[[ end ]]", "")
  assert.ast_type_equals(
    "local function f() ##[[ if true then ]] return 1 ##[[ end ]] end",
    "local function f() return 1 end")
  assert.ast_type_equals([[
    local function f()
      ## if true then
        return 1
      ## else
        return 0
      ## end
    end
  ]], [[
    local function f()
      return 1
    end
  ]])
  assert.analyze_error("##[[ if true then ]]", "'end' expected")
end)

it("parse loops", function()
  assert.ast_type_equals([[
    local a = 2
    ## for i=1,4 do
      a = a * 2
    ## end
  ]], [[
    local a = 2
    a = a * 2
    a = a * 2
    a = a * 2
    a = a * 2
  ]])
  assert.ast_type_equals([[
    local a = 0
    ## for i=1,3 do
      do
        ## if i == 1 then
          a = a + 1
        ## elseif i == 2 then
          a = a + 2
        ## elseif i == 3 then
          a = a + 3
        ## end
      end
    ## end
  ]], [[
    local a = 0
    do a = a + 1 end
    do a = a + 2 end
    do a = a + 3 end
  ]])
  assert.ast_type_equals([[
    local a = 0
    ## for i=1,3 do
      a = a + #[i]#
      for i=1,4,2 do end
    ## end
  ]], [[
    local a = 0
    a = a + 1
    for i=1,4,2 do end
    a = a + 2
    for i=1,4,2 do end
    a = a + 3
    for i=1,4,2 do end
  ]])
end)

it("inject other symbol type", function()
  assert.ast_type_equals([[
    local a: uint8 = 1
    local b: #[context.scope.symbols['a'].type]#
  ]], [[
    local a: uint8 = 1
    local b: uint8
  ]])
end)

it("check symbols inside functions", function()
  assert.analyze_ast([=[
    local function f(x: integer)
      ## assert(x.type == require 'nelua.typedefs'.primtypes.integer)
    end
  ]=])
end)

it("print symbol", function()
  assert.ast_type_equals([=[
    local a: integer <comptime> = 1
    local b: integer <const> = 2
    print #[tostring(a)]#
    print #[tostring(b)]#
  ]=], [[
    local a <comptime> = 1
    local b <const> = 2
    print 'a: int64 <comptime> = 1'
    print 'b: int64 <const>'
  ]])
  assert.ast_type_equals([=[
    for i:integer=1,2 do
      print(i, #[tostring(i)]#)
    end
  ]=], [[
    for i=1,2 do
      print(i, 'i: int64')
    end
  ]])
  assert.ast_type_equals([[
    ## local aval = 1
    ## if true then
      local #|'a'|#: #|'integer'|# <comptime> = #[aval]#
      print #[tostring(context.scope.symbols['a'])]#
    ## end
  ]], [[
    local a <comptime> = 1
    print 'a: int64 <comptime> = 1'
  ]])
end)

it("print enums", function()
  assert.ast_type_equals([[
    local Weekends = @enum { Friday=0, Saturday, Sunda }
    ## Weekends.value.fields[3].name = 'Sunday'
    ## for i,field in ipairs(Weekends.value.fields) do
      print(#[field.name .. ' ' .. tostring(field.value)]#)
    ## end
  ]], [[
    local Weekends = @enum { Friday=0, Saturday, Sunday }
    print 'Friday 0'
    print 'Saturday 1'
    print 'Sunday 2'
  ]])
end)

it("inject fields", function()
  assert.ast_type_equals([[
    local R = @record{x: integer, z: integer}
    ## R.value:add_field('y', primtypes.integer, 2)
    local U = @union{b: boolean, i: integer}
    ## U.value:add_field('n', primtypes.number, 2)
  ]], [[
    local R = @record{x: integer, y: integer, z: integer}
    local U = @union{b: boolean, y: number, i: integer}
  ]])
end)

it("print ast", function()
  assert.ast_type_equals([[
    local a = #[tostring(ast)]#
  ]], [=[
    local a = [[Block {
  {
  }
}]]
  ]=])
end)

it("print types", function()
  assert.ast_type_equals([[
    local n: float64
    local s: stringview
    local b: boolean
    local a: [2]int64
    local function f(a: int64, b: int64): (int64, int64) return 0,0 end
    local R: type = @record{a: integer, b: integer}
    function R:foo() return 1 end
    global R.v: integer = 1
    local r: R
    local tn = #[tostring(n.type)]#
    local ts = #[tostring(s.type)]#
    local tb = #[tostring(b.type)]#
    local ta = #[tostring(a.type)]#
    local tf = #[tostring(f.type)]#
    local tR = #[tostring(R.type)]#
    local tr = #[tostring(r.type)]#
  ]], [=[
    local n: float64
    local s: stringview
    local b: boolean
    local a: [2]int64
    local function f(a: int64, b: int64): (int64, int64) return 0,0 end
    local R: type = @record{a: integer, b: integer}
    function R:foo() return 1 end
    global R.v: integer = 1
    local r: R
    local tn = 'float64'
    local ts = 'stringview'
    local tb = 'boolean'
    local ta = 'array(int64, 2)'
    local tf = 'function(int64, int64): (int64, int64)'
    local tR = 'type'
    local tr = 'R'
  ]=])
end)

it("generate functions", function()
  assert.ast_type_equals([=[
    ## local function make_pow(N)
      local function #|'pow' .. N|#(x: integer)
        local r = 1
        ## for i=1,N do
          r = r*x
        ## end
        return r
      end
    ## end

    ##[[
    make_pow(2)
    make_pow(3)
    ]]
  ]=], [[
    local function pow2(x: integer)
      local r = 1
      r = r * x
      r = r * x
      return r
    end
    local function pow3(x: integer)
      local r = 1
      r = r * x
      r = r * x
      r = r * x
      return r
    end
  ]])
end)

it("print symbol", function()
  assert.ast_type_equals([=[
    ## local a = 1
    do
      do
        print #[a]#
      end
    end
  ]=], [[
    do do print(1) end end
  ]])
  assert.ast_type_equals([=[
    ## local MIN, MAX = 1, 2
    for i:integer=#[MIN]#,#[MAX]# do
      print(i, #[tostring(i)]#)
    end
  ]=], [[
    for i:integer=1,2 do
      print(i, 'i: int64')
    end
  ]])
end)

it("print config", function()
  assert.ast_type_equals([=[
    ## config.test = 'test'
    local a = #[config.test]#
  ]=], [[
    local a = 'test'
  ]])
end)

it("global preprocessor variables", function()
assert.ast_type_equals([=[
    ## TEST = 'test'
    local a = #[TEST]#
  ]=], [[
    local a = 'test'
  ]])

  assert.ast_type_equals([=[
    print(#[tostring(unitname)]#)
    ## unitname = 'unit'
    print(#[tostring(unitname)]#)
  ]=], [[
    print 'nil'
    ## strict = true
    print 'unit'
  ]])
end)

it("function pragmas", function()
  assert.analyze_ast("## cinclude '<stdio.h>'")
  assert.analyze_error("## cinclude(false)", "invalid arguments for preprocess")
end)

it("call codes after inference", function()
  assert.analyze_ast("## after_inference(function() end)")
  assert.analyze_error("## after_inference(false)", "invalid arguments for preprocess")
end)

it("call codes after analyze pass", function()
  assert.analyze_ast("## after_analyze(function() end)")
  assert.analyze_error("## after_analyze(function() error 'errmsg' end)", "errmsg")
  assert.analyze_error("## after_analyze(false)", "invalid arguments for preprocess")
end)

it("inject nodes", function()
  assert.ast_type_equals([=[
    ## inject_astnode(aster.Call{{aster.String{"hello"}}, aster.Id{'print'}})
  ]=], [[
    print 'hello'
  ]])
end)

it("nested preprocessing", function()
  assert.ast_type_equals([[
    ## if true then
      if true then
        ## cinclude 'lala'
        local a =1
      end
    ## end
  ]], [[
    if true then
      ## cinclude 'lala'
      local a = 1
    end
  ]])
end)

it("check function", function()
  assert.analyze_ast([[ ## static_assert(true) ]])
  assert.analyze_error([[ ## static_error() ]], 'static error!')
  assert.analyze_error([[ ## static_error('my fail') ]], 'my fail')
  assert.analyze_error([[ ## static_assert(false) ]], 'static assertion failed')
  assert.analyze_error([[ ## static_assert(false, 'myfail') ]], 'myfail')

  assert.analyze_ast([[
    local a = 1
    local b = 1.0
    ## after_inference(function() static_assert(a.type == primtypes.integer) end)
    ## after_inference(function() static_assert(b.type == primtypes.number) end)
  ]])
end)

it("auto type", function()
  assert.analyze_ast([[
    local a: auto = 1
    ## assert(a.type == primtypes.integer)
  ]])
end)

it("multiple blocks", function()
  assert.analyze_ast([[
    ## assert(true)
    local function f(a: auto)
      ## assert(true)
      for i=1,4 do
        local a: #[primtypes.integer]# <comptime> = 2
        ## assert(a.type == primtypes.integer)
      end
    end
  ]])
end)

it("poly function", function()
  assert.analyze_ast([[
    local function f(a: auto)
      ## assert(a.type == primtypes.integer)
    end
    f(1)
  ]])
  assert.analyze_ast([[
    local function f(T: type, x: usize)
       ## assert(x.type == primtypes.usize and T.value == primtypes.integer)
       return x
    end

    f(@integer, 1)
  ]])
  assert.analyze_ast([[
    ## local counter = 0
    local function f() <polymorphic,alwayseval>
       ## counter = counter + 1
    end
    local x = 1
    f()
    f()
    ## after_inference(function() assert(counter == 2) end)
  ]])
  assert.analyze_ast([[
    local function f(x: auto)
      local r = 1.0 + x
      r = r + x
      ## after_inference(function() assert(r.type == primtypes.number) end)
      return r
    end

    local x = f(1.0)
    ## after_inference(function() assert(x.type == primtypes.number) end)
  ]])
  assert.analyze_ast([[
    local function f(T: type)
      return (@pointer(T))(nilptr)
    end

    do
      local p = f(@integer)
      ## after_inference(function() assert(p.type.is_pointer) end)
      p = nilptr
    end
  ]])
  assert.analyze_ast([=[
    local function inc(x: auto)
      local y = x + 1
      return y
    end
    assert(inc(0) == 1)
    assert(inc(1) == 2)
    assert(inc(2.0) == 3.0)

    ## local printtypes = {}
    local function printtype(x: auto)
      ## table.insert(printtypes, x.type.name)
      return x
    end
    assert(printtype(1) == 1)
    assert(printtype(3.14) == 3.14)
    assert(printtype(true) == true)
    assert(printtype(false) == false)
    local a: uint64 = 1
    assert(printtype(a) == 1)
    local b: uint64 = 1
    assert(printtype(b) == 1)
    ##[[ after_inference(function()
      local types = table.concat(printtypes, ' ')
      static_assert(types == 'int64 float64 boolean uint64', types)
    end) ]]
  ]=])
end)

it("report errors", function()
  assert.analyze_error("##[[ invalid() ]]", "attempt to call")
  assert.analyze_error("##[[ for ]]", "expected near")
  assert.analyze_error("##[[ ast:raisef('ast error') ]]", "ast error")
end)

it("preprocessor replacement", function()
  assert.ast_type_equals([=[
  local s = #[symbols.stringview]#
  local t = #[primtypes.table]#
  local ty = #[primtypes.type]#
  local n = #[primtypes.number]#
]=],[=[
  local s = @stringview
  local t = @table
  local ty = @type
  local n = @number
]=])
  assert.ast_type_equals([=[
  local int = @integer
  local a: #[int]#
]=],[=[
  local int = @integer
  local a: int
]=])
end)

it("preprocessor functions", function()
  assert.ast_type_equals([=[
    ## function f(name, tyname)
      global #|name|#: #|tyname|#
    ## end
    ## f('i', 'integer')
    ## f('n', 'number')
  ]=],[=[
    global i: integer
    global n: number
  ]=])
end)

it("macros", function()
  assert.ast_type_equals([=[
  ## function increment(a, amount)
    #|a.name|# = #|a.name|# + #[amount]#
  ## end
  local x = 0
  ## increment(x, 4)
  print(x)
]=],[=[
  local x = 0
  x = x + 4
  print(x)
]=])

  assert.ast_type_equals([=[
  ##[[
  function unroll(count, block)
    for i=1,count do
      block()
    end
  end
  ]]

  local counter = 1
  ## unroll(4, function()
    print(counter) -- outputs: 1 2 3 4
    counter = counter + 1
  ## end)
]=],[=[
  local counter = 1
  print(counter)
  counter = counter + 1
  print(counter)
  counter = counter + 1
  print(counter)
  counter = counter + 1
  print(counter)
  counter = counter + 1
]=])

  assert.ast_type_equals([=[
  ## local function gettype(T)
    local t = @#|T|#
    ## return t
  ## end

  local T: type = @#[gettype('byte')]#
  local v: T = 0
]=],[=[
  local t = @byte
  local T: type = @t
  local v: T = 0
]=])
end)

it("expression macros", function()
  assert.analyze_ast([=[
    ## local f = exprmacro(function(x, a, b)
      return (#[x]# << #[a]#) >> #[b]#
    ## end)

    local y <comptime> = #[f(0xff, 2, 3)]#
    ## assert(y.value:tonumber() == 127)
  ]=])
end)

it("non hygienic macros", function()
  assert.ast_type_equals([=[
## local function inc()
  a = a + 1
## end
local a = 1
## inc()
]=],[=[
local a = 1
a = a + 1
]=])
end)

it("hygienic macros", function()
  assert.ast_type_equals([=[
## local point = hygienize(function(T)
  print('start')
  local T = #[T]#
  local Point = @record {x: T, y: T}
  print('end')
  ## return Point
## end)

do
  local PointInt = #[point(primtypes.integer)]#
  local a: PointInt = {1,2}
end
]=],[=[
print('start')
local T = @integer
local Point = @record {x: T, y: T}
print('end')

do
  local PointInt = @Point
  local a: PointInt = {1,2}
end
]=])
  assert.analyze_error([=[
## local inc = hygienize(function()
  a = a + 1
## end)
local a = 1
## inc()
]=], "undeclared symbol 'a'")
end)

it("generalize macro", function()
  assert.analyze_ast([=[
    ## local make_record = generalize(function(T)
      local RecordT = @record { x: #[T]# }
      ## return RecordT
    ## end)
    local Foo = #[make_record(primtypes.integer)]#
    local foo: Foo
    ## assert(foo.type.fields.x.type == primtypes.integer)
]=])
  assert.analyze_ast([=[
    ## local make_record = generalize(function(T)
      local RecordT = @record { x: #[T]# }
      ## return RecordT
    ## end)
    local Record = #[make_record]#
    local foo: Record(integer)
    ## assert(foo.type.fields.x.type == primtypes.integer)
]=])
  assert.analyze_error([=[
    ## local make_record = generalize(function(T)
      local RecordT = @record { x: #[T]# }
    ## end)
    local Record = #[make_record]#
    local foo: Record(integer)
]=], "expected a type or symbol in generic return")
  assert.analyze_error([=[
    ## local make_record = generalize(function(T)
      local RecordT = @record { x: #[T]# }
      ## return 1
    ## end)
    local Record = #[make_record]#
    local foo: Record(integer)
]=], "expected a type or symbol in generic return")
end)

it("compiler information", function()
  assert.analyze_ast([=[##[[
    local compiler = require 'nelua.ccompiler'
    assert(compiler.get_cc_info())
    local defs = compiler.get_cc_defines('<stdbool.h>')
    assert(defs.bool == '_Bool')
  ]]]=])
end)

it("run brainfuck", function()
  assert.run('--generator c examples/brainfuck.nelua', 'Hello World!')
end)

end)
