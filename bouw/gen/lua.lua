require 'func'

local unops = {
	['abs'] = 'math.abs($1)',
	['-'] = '- $1',
	['Σ'] = 'local sum = 0; for k, v in ipairs($1) do sum = sum + v end; $1 = sum;',
	['log10'] = 'math.log10($1)',
	['log'] = 'math.log',
	['fn.id'] = '$1',
	['|'] = '(function() for i,v in ipairs($1) do if v then return v end end)()',

	['fn.nul'] = '$1(0)',
	['fn.een'] = '$1(1)',
	['fn.twee'] = '$1(2)',
	['fn.drie'] = '$1(3)',

	['l.eerste'] = '$1[1]',
	['l.tweede'] = '$1[2]',
	['l.derde'] = '$1[3]',
	['l.vierde'] = '$1[4]',

	['fn.deel'] = 'function(x) return x / $1 end', 
	['fn.maal'] = 'function(x) return x * $1 end', 
	['fn.constant'] = 'function(x) return $1 end', 
}

local noops = {
	['|'] = '$1 or $2',
	['fn.id'] = 'function(x) return x end',
	['fn.constant'] = 'function() return $1 end',
	['fn.merge'] = 'function(x) return {$1(x),$2(x)} end',
	['fn.plus'] = 'function(x) return function(y) return x + y end end',
	['∘'] = 'function(x) return $1($2(x)) end',
	['-'] = 'function(x) return -x end',
	['log10'] = 'math.log',
	['+'] = 'function(t) return t[1]+t[2] end',
	['fn.plus'] = '$1 = $1 + 2',
	['⊤'] = 'true',
	['⊥'] = 'false',
	['∅'] = '{}',
	['τ'] = 'math.pi * 2',
	['π'] = 'math.pi',
	['fn.eerste'] = '(type($1)=="function") and $1(1) or $1[1]',
	['fn.tweede'] = '(type($1)=="function") and $1(2) or $1[2]',
	['fn.derde'] = '(type($1)=="function") and $1(3) or $1[3]',
	['fn.vierde'] = '(type($1)=="function") and $1(4) or $1[4]',
	['_f'] = '$1($2)',
}

local diops = {
	['+'] = '$1 + $2',
	['-'] = '- $1',
	['·'] = '$1 * $2',
	['/'] = '$1 / $2',
	['^'] = '$1 ^ $2',
	['%'] = '$1 / 100',

	['|'] = '$1 or $2',
	['∘'] = 'function(x) return $2($1(x)) end',
	['mod'] = '$1 % $2',
	['willekeurig'] = 'Math.random()*($2-$1) + $1', -- randomRange[0, 10]
	['fn.merge'] = '$1, $2',--function(x) return {$1(x),$2(x)} end',
	['√'] = 'math.sqrt($1, 0.5)',
	['^'] = 'math.pow($1, $2)',
	['^f'] = [[(function (f,n)
		return function(x)
			local r = x
			for i=1,n do
				r = f(r)
			end
			return r
		end
	end)($1,$2)]],
	['derdemachtswortel'] = 'Math.pow($1,1/3)',
	['_f'] = '$1($2)',
	['_l'] = '$1[$2+1]',

	-- cmp
	['>'] = '$1 > $2',
	['≥'] = '$1 >= $2',
	['='] = '$1 === $2',
	['≠'] = '$1 !== $2',
	['≤'] = '$1 <= $2',
	['<'] = '$1 < $2',

	-- deduct
	['¬'] = '! $1',
	['∧'] = '$1 && $2', 
	['∨'] = '$1 || $2', 
	['⇒'] = '$1 ? $2 : $3', 

	['sin'] = 'Math.sin($1)',
	['cos'] = 'Math.cos($1)',
	['tan'] = 'Math.tan($1)',
	['sincos'] = '[Math.cos($1), Math.sin($1)]',
	['cossin'] = '[Math.sin($1), Math.cos($1)]',

	-- discreet
	['min'] = 'Math.min($1,$2)',
	['max'] = 'Math.max($1,$2)',
	['afrond.onder'] = 'Math.floor($1)',
	['afrond']       = 'Math.round($1)',
	['afrond.boven'] = 'Math.ceil($1)',
	['int'] = 'Math.floor($1)',
	['abs'] = 'Math.abs($1)',
	['sign'] = '($1 > 0 ? 1 : -1)',

	-- exp
	-- concatenate
	['‖'] = 'Array.isArray($1) ? $1.concat($2) : $1 + $2',
	['‖u'] = '$1 + $2',
	['mapuu'] = '(function() { var totaal = ""; for (int i = 0; i < $1.length; i++) { totaal += $2($1[i]); }; return totaal; })() ', -- TODO werkt dit?
	['catu'] = '$1.join($2)',
}

local triops = {
	--['_f2'] = '$1($2,$3)',
}

function luagen(sfc)

	local focus = 1
	local maakvar = maakindices()
	local L = {}
	local tabs = ''

	local function emit(fmt, ...)
		local args = {...}
		uit[#uit+1] = fmt:gsub('$(%d)', function(i) return args[tonumber(i)] end)
	end

	function ins2lua(ins)
		if fn(ins) == 'push' or fn(ins) == 'put' then
			if fn(ins) == 'push' then
				focus = focus + 1
			end
			local naam = atoom(arg(ins))
			assert(naam, unlisp(ins))
			naam = noops[naam] or naam
			L[#L+1] = string.format('%slocal %s = %s', tabs, varnaam(focus), naam), focus

		elseif atoom(ins) == 'fn.id' then
			-- niets

		elseif tonumber(atoom(ins)) then
			L[#L+1] = tabs..'local '..varnaam(focus) .. " = " .. atoom(ins)
			focus = focus + 1

		elseif fn(ins) == 'rep' then
			local res = {}
			local num = tonumber(atoom(arg(ins)))
			assert(num, unlisp(ins))
			for i = 1, num-1 do
				L[#L+1] = tabs..string.format('local %s = %s', varnaam(focus+i), varnaam(focus))
				focus = focus + 1
			end

		elseif fn(ins) == '∘' then
			local funcs = arg(ins)
			L[#L+1] = tabs..string.format('function %s(x)')
			for i, func in ipairs(funcs) do
				local naam = varnaam(focus - i + 1)
				L[#L+1] = tabs..'  x = '..naam
			end
			L[#L+1] = tabs..string.format('function %s(x)')

		elseif fn(ins) == 'wissel' then
			local naama = varnaam(focus)
			local num = atoom(arg(ins))
			local naamb = varnaam(focus + num)
			L[#L+1] = tabs..string.format('local %s,%s = %s,%s', naama, naamb, naamb, naama)

		elseif unops[atoom(ins)] then
			local naam = varnaam(focus)
			local di = unops[atoom(ins)]:gsub('$1', naam)
			L[#L+1] = tabs..string.format('local %s = %s', naam, di)

		elseif fn(ins) == 'fn.plus' then
			local naam = varnaam(focus)
			local c = atoom(arg(ins))
			L[#L+1] = tabs..string.format('local %s = %s + %s', naam, naam, c)

		elseif diops[atoom(ins)] then
			local naama = varnaam(focus-2)
			local naamb = varnaam(focus-1)
			local di = diops[atoom(ins)]:gsub('$1', naama):gsub('$2', naamb)
			L[#L+1] = tabs..string.format('local %s = %s', naama, di)
			focus = focus - 1

		elseif triops[atoom(ins)] then
			local naama = varnaam(focus-3)
			local naamb = varnaam(focus-2)
			local naamc = varnaam(focus-1)
			local di = triops[atoom(ins)]:gsub('$1', naama):gsub('$2', naamb):gsub('$3', naamc)
			L[#L+1] = tabs..string.format('local %s,%s = %s', naama, naamb, di)
			focus = focus - 2

		elseif atoom(ins) == 'eind' then
			local naama = varnaam(focus-1)
			local naamb = varnaam(focus-2)
			L[#L+1] = tabs.."return "..naama
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."end"
			focus = focus - 1

		elseif fn(ins) == 'tupel' then
			local tupel = {}
			local num = tonumber(atoom(arg(ins)))
			local naam = varnaam(focus - num)
			for i=1,num do
				tupel[i] = varnaam(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("local %s = {%s}", naam, table.concat(tupel, ","))
			focus = focus - num + 1

		elseif fn(ins) == 'arg' then
			local var = varnaam(tonumber(atoom(arg(ins))))
			local naam = varnaam(focus)
			L[#L+1] = tabs..'local '..naam..' = arg'..var
			focus = focus + 1

		elseif fn(ins) == 'fn' then
			local naam = varnaam(focus)
			local var = varnaam(tonumber(atoom(arg(ins))))
			L[#L+1] = tabs..string.format("function %s(%s) ", naam, "arg"..var)
			focus = focus + 1
			tabs = tabs..'  '

		else
			error('onbekende instructie: '..unlisp(ins))
		end
	end

	L[#L+1] = 'local A = ...'

	for i,ins in ipairs(sfc) do
		ins2lua(ins)
	end

	L[#L+1] = 'return A'
	return table.concat(L, '\n')
end
