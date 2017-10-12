function file(name, data)
	if not data then
		local f = io.open(name, 'r')
		if not f then error('file-not-found ' .. name) end
		data = f:read("*a")
		f:close()
		return data
	else
		local f = io.open(name, 'w')
		f:write(data)
		f:close()
	end
end

local printOld = print
function print2(...)
	local res = {}
	for i,v in ipairs({...}) do
		if type(v)=='table' then
			res[i] = unparse(v)
		else
			res[i] = v
		end
	end
	printOld(table.unpack(res))
end

-- hex
function hex_encode(txt)
	local res = {}
	for i=1,#txt do
		table.insert(res, string.format("%02x", string.byte(txt:sub(i,i))))
	end
	return table.concat(res)
end

function hex_decode(hex)
	local res = {}
	for i=1,#hex-1,2 do
		local sub = hex:sub(i,i+1)
		local num = tonumber(sub, 16)
		table.insert(res, string.char(num))
	end
	return table.concat(res)
end

-- network int
function ntoh(num)
    local mul = 0x1
    local res = 0
    for i=1,#num do
        res = res + mul * string.byte(num:sub(i,i))
        mul = mul * 0x100
    end
    
    return res
end

function hton(num, len)
	local n = {}
	for i=1,len do
		n[i] = num % 0x100
		num = math.floor(num / 0x100)
	end
	return string.char(table.unpack(n))
end

function set(list)
	local s = {}
	for i,v in ipairs(list) do
		s[v] = true
	end
	return s
end

color = {
	red = '\x1B[31m',
	green = '\x1B[32m',
	yellow = '\x1B[33m',
	blue = '\x1B[34m',
	purple = '\x1B[35m',
	cyan = '\x1B[36m',
	white = '\x1B[37m',
}