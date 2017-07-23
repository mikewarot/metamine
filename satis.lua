#!/usr/bin/lua
require 'sexp'
require 'infix'
require 'eval'
require 'util'

local args = {...}
local files = {}
local flags = {}

for i,arg in ipairs(args) do
	if string.sub(arg,1,1) == '-' then
		flags[arg] = true
	else
		table.insert(files, arg)
	end
end

local color = {
	red = '\x1B[31m',
	green = '\x1B[32m',
	yellow = '\x1B[33m',
	blue = '\x1B[34m',
	purple = '\x1B[35m',
	cyan = '\x1B[36m',
	white = '\x1B[37m',
}
if not flags['-c'] then
	for k,v in pairs(color) do
		color[k] = ''
	end
end

print(color.green..'satis versie 0.1.0'..color.white)

function shell(txt)
	local ok, sexp = pcall(parseInfix, txt)
	if not ok then
		print(color.red..sexp)
	else
		print(color.cyan..unparse(eval(sexp)))
	end
end

-- eval file
if #files > 0 then
	local txt = file((files))
	shell(txt)
	return
end

-- interactive mode
while true do
	io.write(color.yellow..'$ '..color.white)
	local line = io.read()
	if not line then
		break
	end
	shell(line)
end
