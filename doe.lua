require 'lisp'
require 'util'

local log = function() end

local fn = {
	['tau'] = 2 * math.pi;
	['+'] = function(a,b) return a + b end;
	['-'] = function(a,b) if b then return a - b else return -a end end;
	['*'] = function(a,b) return a * b end;
	['/'] = function(a,b) return a / b end;
	['^'] = function(a,b)
		if type(a) == 'function' then
			return function (x)
				for i=1,b do
					x = a(x)
				end
				return x
			end
		else
			return a ^ b
		end
	end;
	['%'] = function(a) return a / 100 end;
	['[]'] = function(...)
		return table.pack(...)
	end,
	['{}'] = function(...)
		local t = {...}
		local s = {is_set=true}
		for _,v in pairs(t) do
			s[v] = true
		end
		return s
	end,

	['@'] = function(a,b)
		return function(...)
			return b(a(...))
		end
	end;
	['|'] = function(a,b)
		local fa = type(a) == 'function'
		local fb = type(b) == 'function'
		if fa ~= fb then return 'fout' end
		if fa and fb then
			return function(...)
				local ta = a(...)
				local tb = b(...)
				if not ta == not tb then
					return nil
				end
				return ta or tb
			end
		end
		return a or b
	end;

	['#'] = function(a) return #a end;
	['='] = function(a,b) return unlisp(a)==unlisp(b) end;
	['!='] = function(a,b) return a ~= b end;
	['~='] = function(a,b) return math.abs(a-b) < 0.00001 end;
	['..'] = function(a,b)
		local r = {}
		for i=a,b-1 do
			r[i-a+1] = i
		end
		return r
	end;

	['||'] = function(a,b)
		local j = 1
		local t = {}
		if isatoom(a) then a = {a} end
		if isatoom(b) then b = {b} end
		for i,v in ipairs(a) do t[j] = v; j=j+1 end
		for i,v in ipairs(b) do t[j] = v; j=j+1 end
		return t
	end;

	-- lib
	['cat'] = function(a,b)
		local r = {}
		for i,v in ipairs(a) do
			for i,v in ipairs(v) do
				r[#r+1] = v
			end
			if b then
				r[#r+1] = b
			end
		end
		return r
	end;

	-- trig
	['sin'] = math.sin;
	['asin'] = math.asin;
	['cos'] = math.cos;
	['acos'] = math.acos;
	['tan'] = math.tan;
	['atan'] = function(a,b)
		if b then return math.atan2(a,b)
			else return math.atan(a)
		end
	end;

	['som'] = function(a)
		local r = 0
		for i,v in ipairs(a) do
			r = r + v
		end
		return r
	end;

	['herhaal'] = function(a,n) -- 10
		local r = {}
		for i=1,n do
			r[i] = a
		end
		return r
	end;

	['tekst'] = function(a)
		if type(a) == 'table' then
			a = unlisp(a)
		end
		return table.pack(string.byte(tostring(a),1,#tostring(a)))
	end;

	['getal'] = function(a)
		return tonumber(string.char(table.unpack(a)))
	end;

	['split'] = function(a,b)
		local r = {}
		local t = {}
		for i,v in ipairs(a) do
			if v == b then
				r[#r+1] = t
				t = {}
			else
				t[#t+1] = v
			end
		end
		return r
	end;

	['unie'] = function(a,b)
		local s = {}
		for v in pairs(a) do s[v] = true end
		for v in pairs(b) do s[v] = true end
		return s
	end;
}

function eval0(env,exp)
	if atom(exp) then
		local v = tonumber(exp) or env[exp]
		if not v then error('onbekend: "'..unlisp(exp)..'"') end
		return v
	else
		if exp[1] == '->' then
			local arg = exp[2]
			local fn = exp[3]
			return function(a)
				-- maplet
				if env[arg] and a ~= env[arg] then
					return nil
				end
				-- misschien overschrijf scoping
				env[arg] = env[arg] or a
				return eval0(env, fn)
			end
		end
		local r = {}
		for i=1,#exp do
			r[i] = eval0(env,exp[i])
		end
		local f,a,b = r[1],r[2],r[3]
		
		-- tabel
		if type(f) == 'table' then
			if isexp(f) and f[1] == '->' then
				local arg,func = f[2],f[3]
				env[arg] = env[arg] or r[2]
				return eval0(env,func)
			else
				return f[a+1]
			end
		end

		-- aanroep
		if type(f) ~= 'function' then
			error('geen functie: '..unlisp(r)..' '..unlisp(exp))
		end

		-- functie
		local t = {}
		for i=2,#r do t[i-1] = r[i] end
		return f(table.unpack(t))
	end
end

function eval(proc)
	log('# Eval')
	log()
	local stdin = ''
	local env = {stdin = table.pack(string.byte(stdin,1,-1))}
	for i,block in ipairs(proc) do
		local header = block[1]
		local dim = tonumber(header[2])

		if dim == 0 then
			local env0 = evalblock(env,block)
			for k,v in spairs(env0) do
				env[k] = v
			end
			log()

		elseif dim == 1 then

			-- laat ons gaan
			for i=2,#block do
				local stat = block[i]
				local name,exp = stat[2],stat[3]
				local res = {}
				local index = 1
				local done = false

				repeat
					local sub = {}
					for i,v in ipairs(exp) do
						v = env[v] or v
						if atom(v) then
							sub[i] = v
						else
							if not v[index] then
								done = true
							else
								sub[i] = v[index]
							end
						end
					end

					if not done then
						res[index] = eval0(env,sub)
						index = index + 1
					end
				until done

				log('',name,':= '..unlisp(res))
				env[name] = res
			end
			log()

		-- tijd
		elseif block[1] == 'sec' then
			for i=1,10 do
				slaap(1)
				log('#'..i)
				evalblock(env,block)
			end
		else
			error('hoe kan ik '..unlisp(block)..' evalueren?')
		end
	end
	return env.stdout
end

function array(block,off)
	off = off or 1
	return function()
		local b = block[off]
		off = off + 1
		return b
	end
end

function evalblock(env,block)
	local env = copy(env)
	local env0 = {}
	for stat in array(block,2) do
		local name,val = stat[2],stat[3]
		env0[name] = eval0(env,val)
		env[name] = env0[name]
		log('',name,':= '..unlisp(env[name]))
	end
	return env0
end

function equals(a,b)
	do return unlisp(a) == unlisp(b) end
	if type(a) == 'table' and type(b) == 'table' then
		if #a ~= #b then return false end
		for i,a0 in ipairs(a) do
			if not equals(a0,b[i]) then
				return false
			end
		end
		return true
	else
		return a == b
	end
end

-- test
if false and test then
	local t = {
		{'((:= stdout 0))', 0},
		{'((:= a 0) (:= stdout a))', 0},
		{'((:= stdout (cat ([] ([] 0) ([] 1 2))) ))', '(0 1 2)'},
		{'((:= stdout (+ 1 1) ))', '2'},
	}
	for i,v in ipairs(t) do
		local q = v[1]
		local a = v[2]
		local r = eval(lisp(q))
		assert(equals(r,a), q .. ' geeft ' .. unlisp(r) .. ', maar hoort te zijn ' .. unlisp(a))
	end
end

function set2tekst(set)
	local t = {'{'}
	set.is_set = nil -- voorkom iteratie (;
	for v in pairs(set) do
		if type(v) == 'number' then
			t[#t+1] = string.format('%.f', v)
		else
			t[#t+1] = tostring(v)
		end
		if next(set,v) then
			t[#t+1] = ', '
		end
	end
	set.is_set = true
	t[#t+1] = '}'
	return table.concat(t)
end


function doe(stroom)
	local io_write = io.write
	local print = print
	if not verboos then
		io_write = function () end
		print = function () end
	end
	local env = kopieer(fn)
	for i,feit in ipairs(stroom) do
		local fn,naam,exp = feit[1],feit[2],feit[3]
		io_write('DOE\t',unlisp(feit),'\t\t= ')
		--print('DOE',leed(noem))

		if fn == '=' or fn == ':=' then

			-- lus
			if type(naam) == 'table' then
				local naam,itnaam = naam[1],naam[2]
				local it = env[itnaam]
				if not it or type(it) ~= 'table' then
					error('ongeldige lus '..itnaam)
				end

				env[naam] = env[naam] or {}
				local naar = env[naam]

				for i = 1,#it do
					env[itnaam] = it[i]
					naar[i] = eval0(env, exp)
				end
				env[it] = nil

			-- geen lus
			else
				env[naam] = eval0(env, exp)

			end
			print(unlisp(env[naam]))
		else
			--print('ok')
			print(unlisp(env[naam]))
		end


	end

	local uit = env['stduit']
	if type(uit) == 'table' and uit.is_set then
		uit = set2tekst(uit)
	elseif type(uit) == 'number' then
		uit = tostring(uit)
	elseif type(uit) == 'table' then
		uit = string.char(table.unpack(uit))
	end
	return uit
end
