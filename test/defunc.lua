require 'ontleed'
require 'defunc'

-- id
local a = X('_arg', '0')
local b = defunc(a, '0')
assert(atoom(b) == 'fn.id')

-- kruid R
local a = X('+', '2', X('_arg', '0'))
local b = defunc(a, '0')
print(fn(arg0(b)) == 'kruid', combineer(b))

-- kruid L
local a = X('+', X('_arg', '0'), '2')
local b = defunc(a, '0')
print(fn(arg0(arg0(b))) == 'kruidL', combineer(b))

-- merge L
local a = X('+', X('_arg', '1'), X('_arg', '2'))
local b = defunc(a, '0')
print(fn(b) == 'kruidL', combineer(b))
