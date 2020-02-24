require 'func'

local unops = {
	['#'] = '$1.length',
	['√'] = 'Math.sqrt($1)',
	['%'] = '$1 / 100;',
	['-'] = '- $1',
	['¬'] = '! $1',
	['!'] = [[(num => {
  if (num === 0 || num === 1)
    return 1;
  for (var i = num - 1; i >= 1; i--) {
    num *= i;
  }
  return num;})($1)
	]],
	['Σ'] = '(x => {var sum = 0; for (var i = 0; i < $1.length; i++) { sum = sum + $1[i]; }; return sum;})()',
	['|'] = '((alts) => { for (var i=0; i<alts.length; i++) {  var alt = alts[i]; if (alt != null) {return alt;} } })($1)',
	['derdemachtswortel'] = 'Math.pow($1,1/3)',
	['√'] = 'Math.sqrt($1, 0.5)',
}

local fnops = {
	['fn.nul'] = '$1(0)',
	['fn.een'] = '$1(1)',
	['fn.twee'] = '$1(2)',
	['fn.drie'] = '$1(3)',

	['l.eerste'] = '$1[0]',
	['l.tweede'] = '$1[1]',
	['l.derde'] = '$1[2]',
	['l.vierde'] = '$1[3]',
}

local noops = {
	['niets'] = 'null',
	-- niet goed
	['misschien'] = 'Math.random() < 0.5',
	['newindex'] = 'x => {x[0][ x[1] ] = x[2]; return x[0]; }',

	-- functioneel
	['zip'] = '(function(args){ var a = args[0]; var b = args[1]; var c = []; for (var i = 0; i < a.length; i++) { c[i] = [a[i], b[i]]; }; return c;})',
  ['zip1'] = '(function(args){ var a = args[0]; var b = args[1]; var c = []; for (var i = 0; i < a.length; i++) { c[i] = [a[i], b]; }; return c;})',
  ['rzip1'] = '(function(args){ var a = args[0]; var b = args[1]; var c = []; for (var i = 0; i < b.length; i++) { c[i] = [a, b[i]]; }; return c;})',
  ['map'] = '(function(a){ if (Array.isArray(a[1])) return a[0].map(x => a[1][x]); else return a[0].map(a[1]); })',
  ['filter'] = '(function(a){return a[0].filter(a[1]);})',
  ['reduceer'] = '(function(a){return a[0].reduce(a[1]);})',
	['vouw'] = '(function(lf) {var l=lf[0]; var f=lf[1]; var r=l[0] ; for (var i=1; i < l.length; i++) r = f([r, l[i]]); ; return r;})',

	['sincos'] = 'x => [Math.cos(x), Math.sin(x)]',
	['cossin'] = 'x => [Math.sin(x), Math.cos(x)]',

	-- discreet
	['min'] = 'x => Math.min(x[0], x[1])',
	['max'] = 'x => Math.max(x[0], x[1])',


	 ['vanaf'] = 'x => x[0].slice(x[1])',
	 ['canvas.fontsize'] = [[
 (function(_args) {return (function(c){
  var vorm = _args[0];
  var fontsize = _args[1] * SCHAAL;
  var font = fontsize+'px Arial';
  c.font = font;
  vorm(c);
  return c;});
 })]],

	 ['verf'] = [[
 (function(_args) {return (function(c){
  var vorm = _args[0];
  var kleur = _args[1];
  var r = kleur[0]*255;
  var g = kleur[1]*255;
  var b = kleur[2]*255;
  var style = 'rgb('+r+','+g+','+b+')';
  c.fillStyle = style;
  c.strokeStyle = style;
  vorm(c);
  return c;});
 })]],


	['rgb'] = [[ (function(_args) { return _args; }) ]],
	['sorteer'] = '(function(a){ return a[0].sort(function (c,d) { return a[1]([c, d]); }); })',
	['afrond.onder'] = 'Math.floor',
	['afrond']       = 'Math.round',
	['afrond.boven'] = 'Math.ceil',
	['willekeurig'] = 'x => Math.random()*(x[1]-x[0]) + x[0]',
	['int'] = 'Math.floor',
	['abs'] = 'Math.abs',
	['tekst'] = 'x => (typeof(x)=="object" && x.has && "{"+[...x].toString()+"}") || JSON.stringify(x) || (x || "niets").toString()',
	['vierkant'] = [[ args => {
  var r = args[1] * SCHAAL;
  var x = args[0][0] * SCHAAL;
  var y = (100 - args[0][1]) * SCHAAL - r;
  return context => {
    context.fillRect(x,y,r,r);
    return context;
  }
  } ]],

	['label'] = [[ args => {
  var x = args[0][0] * SCHAAL;
  var y = (100 - args[0][1]) * SCHAAL;
  var t = args[1];
	//if (typeof t == "object)
//		t = [...t]
//	alert("t = " + typeof t);
  return context => {
    context.fillText(t,x,y);
    return context;
  }
	} ]],

	['rechthoek'] = [[ args => {
  var x = args[0][0] * SCHAAL;
  var y = (100 - args[0][1]) * SCHAAL;
  var w = args[1][0] * SCHAAL - x;
  var h = (100 - args[1][1]) * SCHAAL - y;
  return context => {
    context.fillRect(x,y,w,h);
    return context;
  }
	} ]],

	['lijn'] = [[ args => {
  var x1 = args[0][0] * SCHAAL;
  var y1 = (100 - args[0][1]) * SCHAAL;
  var x2 = args[1][0] * SCHAAL;
  var y2 = (100 - args[1][1]) * SCHAAL;
  return context => {
		context.moveTo(x1,y1);
		context.lineTo(x2,y2);
		context.stroke();
    return context;
  }
	} ]],

	['cirkel'] = [[ args => {
		return (function(c){
			var x = args[0][0] * SCHAAL;
			var y = (100 - args[0][1]) * SCHAAL;
			var r = args[1] * SCHAAL;
			c.beginPath();
			c.arc(x, y, r, 0, Math.PI * 2);
			c.fill();
			return c;
		});
	}]],


	['boog'] = [[ args => {
		return (function(c){
			var x = args[0][0] * SCHAAL;
			var y = (100 - args[0][1]) * SCHAAL;
			var r = args[1] * SCHAAL;
			var a1 = args[1] * SCHAAL;
			var a2 = args[2] * SCHAAL;
			c.beginPath();
			c.arc(x, y, r, a1, a2);
			c.fill();
			return c;
		});
	}]],

	['canvas.clear'] = '(function(c) { c.clearRect(0,0,1900,1200); return c; })',

	['sign'] = '$1 > 0 and 1 or -1',
	['mod'] = 'x => x[0] % x[1]',

	['int'] = 'Math.floor',
	['sin'] = 'Math.sin',
	['cos'] = 'Math.cos',

	['|'] = '$1 or $2',
	['fn.id'] = 'x => x',
	['fn.constant'] = 'function() return $1 end',
	['fn.merge'] = '{$1(x),$2(x)}',
	['fn.plus'] = 'function(x) return function(y) return x + y end end',
	['-'] = 'function(x) return -x end',
	['log10'] = 'math.log10',
	['⊤'] = 'true',
	['⊥'] = 'false',
	['∅'] = '{}',
	['τ'] = 'Math.PI * 2',
	['π'] = 'Math.PI',
	['_f'] = '$1($2)',
	['l.eerste'] = '$1[0]',
	['l.tweede'] = '$1[1]',
	['l.derde'] = '$1[2]',
	['l.vierde'] = '$1[3]',
	['fn.nul'] = '$1(0)',
	['fn.een'] = '$1(1)',
	['fn.twee'] = '$1(2)',
	['fn.drie'] = '$1(3)',

	-- dynamisch
	['eerste'] = '(typeof($1)=="function") ? $1(0) : $1[0]',
	['tweede'] = '(typeof($1)=="function") ? $1(1) : $1[1]',
	['derde'] = '(typeof($1)=="function") ? $1(2) : $1[2]',
	['vierde'] = '(typeof($1)=="function") ? $1(3) : $1[3]',
}

local binops = {
	-- set
	[':'] = '$2.has($1)',
	['∩'] = 'new Set([...$1].filter(x => $2.has(x)))',
	['∪'] = 'new Set([...$1, ...$2])',
	['-s'] = 'new Set([...$1].filter(x => !$2.has(x)))',
	['\\'] = 'new Set([...$1].filter(x => !$2.has(x)))',
	['+v']  = '(x => {var r = []; for (var i = 0; i < $1.length; i++) r.push($1[i] + $2[i]); return r;})()',
	['+v1'] = '$1.map(x => x + $2)',
	['·v']  = '(x => {var r = []; for (var i = 0; i < $1.length; i++) r.push($1[i] * $2[i]); return r;})()',
	['·v1'] = '$1.map(x => x * $2)',
	['+f'] = '$1.map(x => x + $2)',
	['·f1'] = '$1.map(x => x + $2)',
	['/v1'] = '$1.map(x => x / $2)',
	['_f'] = '$1($2)',
	['_l'] = '$1[$2]',
	['_'] = 'typeof($1) == "function" ? $1($2) : $1[$2]',
	['^r'] = '$1 ^ $2',
	['∘'] = '((a,b) => (x => b(a(x))))($1,$2)',
	['+'] = '$1 + $2',
	['·'] = '$1 * $2',
	['/'] = '$1 / $2',
	['^'] = '$1 ^ $2',
	['×'] = '(ab => { var r = []; for (var i = 0; i < $1.length; i++) { for (var j = 0; j < $2.length; j++) { r.push([$1[i],$2[j]]); }} ; return r;})()',
	['..'] = '$1 == $2 ? [] : ($1 <= $2 ? Array.from(new Array(Math.max(0,Math.floor($2 - $1))), (x,i) => $1 + i) : Array.from(new Array(Math.max(0,Math.floor($1 - $2))), (x,i) => $1 - 1 - i))',
	['mod'] = '$1 % $2',

	['|'] = '$1 or $2',

	['^'] = 'Math.pow($1, $2)',
	['^f'] = [[(function (f,n) {
		return function(x) {
			var r = x;
			for (var i = 0; i < n; i++) {
				r = f(r);
			}
			return r;
		}
	})($1,$2)]],

	-- cmp
	['>'] = '$1 > $2',
	['≥'] = '$1 >= $2',
	['='] = 'JSON.stringify($1) == JSON.stringify($2)',
	['≠'] = 'JSON.stringify($1) != JSON.stringify($2)',
	['≤'] = '$1 <= $2',
	['<'] = '$1 < $2',

	-- deduct
	['∧'] = '$1 && $2', 
	['∨'] = '$1 || $2', 
	['⇒'] = '$1 && $2', 

	-- exp
	-- concatenate
	['‖'] = [[typeof($1) == "string" ? $1 + $2 : $1.concat($2)]],
	['‖u'] = '$1 .. $2',
	['‖i'] = '(for i,v in ipairs(b) do a[#+1] = v)($1,$2)',
	['mapuu'] = '(function() { var totaal = ""; for (int i = 0; i < $1.length; i++) { totaal += $2($1[i]); }; return totaal; })() ', -- TODO werkt dit?
	['catu'] = '$1.join($2)',
}

function jsgen(sfc)

	local maakvar = maakindices()
	local L = {}
	if opt and opt.L then
		setmetatable(L, {__newindex = function (t,k,v) rawset(L, k, v); print(v); end })
	end
	local tabs = ''
	local focus = 1

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
			L[#L+1] = string.format('%svar %s = %s;', tabs, varnaam(focus), naam), focus

		elseif atoom(ins) == 'fn.id' then
			-- niets

		elseif tonumber(atoom(ins)) then
			L[#L+1] = tabs..'var '..varnaam(focus) .. " = " .. atoom(ins) .. ';'
			focus = focus + 1

		elseif fn(ins) == 'rep' then
			local res = {}
			local num = tonumber(atoom(arg(ins)))
			assert(num, unlisp(ins))
			for i = 1, num-1 do
				L[#L+1] = tabs..string.format('var %s = %s;', varnaam(focus+i), varnaam(focus))
				focus = focus + 1
			end

		elseif fn(ins) == '∘' then
			local funcs = arg(ins)
			L[#L+1] = tabs..string.format('function %s(x) {')
			for i, func in ipairs(funcs) do
				local naam = varnaam(focus - i + 1)
				L[#L+1] = tabs..'  x = '..naam
			end
			L[#L+1] = tabs..string.format('function %s(x) {')

		elseif fn(ins) == 'wissel' then
			local naama = varnaam(focus)
			local num = atoom(arg(ins))
			local naamb = varnaam(focus + num)
			L[#L+1] = tabs..string.format('var %s,%s = %s,%s;', naama, naamb, naamb, naama)

		elseif unops[atoom(ins)] then
			local naam = varnaam(focus-1)
			local di = unops[atoom(ins)]:gsub('$1', naam)
			L[#L+1] = tabs..string.format('var %s = %s;', naam, di)

		elseif binops[atoom(ins)] then
			local naama = varnaam(focus-2)
			local naamb = varnaam(focus-1)
			local di = binops[atoom(ins)]:gsub('$1', naama):gsub('$2', naamb)
			L[#L+1] = tabs..string.format('var %s = %s;', naama, di)
			focus = focus - 1

		elseif atoom(ins) == 'eind' then
			local naama = varnaam(focus-1)
			local naamb = varnaam(focus-2)
			L[#L+1] = tabs..'return '..naama..';'
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."}"
			focus = focus - 1

		elseif atoom(ins) == 'einddan' then
			local naam = varnaam(focus-1)
			local tempnaam = 'tmp'
			L[#L+1] = tabs .. tempnaam .. " = " .. naam .. ';'
			tabs = tabs:sub(3)
			L[#L+1] = tabs.."} else tmp = null;"
			L[#L+1] = tabs..'var ' .. naam .. " = " .. tempnaam .. ';'
			focus = focus

		-- biebfuncties?
		elseif noops[atoom(ins)] then
			L[#L+1] = tabs..'var '..varnaam(focus) .. " = " .. noops[atoom(ins)] .. ';'
			focus = focus + 1

		elseif fn(ins) == 'set' then
			local set = {}
			local num = tonumber(atoom(arg(ins)))
			local naam = varnaam(focus - num)
			for i=1,num do
				set[i] = varnaam(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("var %s = new Set([%s]);", naam, table.concat(set, ","))
			focus = focus - num + 1


		elseif fn(ins) == 'tupel' or fn(ins) == 'lijst' then
			local tupel = {}
			local num = tonumber(atoom(arg(ins)))
			local naam = varnaam(focus - num)
			for i=1,num do
				tupel[i] = varnaam(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("var %s = [%s];", naam, table.concat(tupel, ","))
			focus = focus - num + 1

		elseif fn(ins) == 'string' then
			local text = {}
			local num = tonumber(atoom(arg(ins)))
			local naam = varnaam(focus - num)
			for i=1,num do
				text[i] = varnaam(i + focus - num - 1)
			end
			L[#L+1] = tabs..string.format("var %s = String.fromCharCode(%s);", naam, table.concat(text,  ","))
			focus = focus - num + 1

		elseif fn(ins) == 'arg' then
			local var = varnaam(tonumber(atoom(arg(ins))))
			local naam = varnaam(focus)
			L[#L+1] = tabs..'var '..naam..' = arg'..var..';'
			focus = focus + 1

		elseif fn(ins) == 'fn' then
			local naam = varnaam(focus)
			local var = varnaam(tonumber(atoom(arg(ins))))
			L[#L+1] = tabs..string.format("var %s = (%s) => {", naam, "arg"..var)
			focus = focus + 1
			tabs = tabs..'  '

		elseif atoom(ins) == 'dan' then
			focus = focus-1
			local naam = varnaam(focus)
			L[#L+1] = tabs..string.format("if (%s) {", naam)
			tabs = tabs..'  '

		else
			error('onbekende instructie: '..unlisp(ins))

		end
		--L[#L+1] = 'print("'..L[#L]..'")'
		--L[#L+1] = 'print('..varnaam(focus)..')'
	end

	for i = 1, #sfc do
		local ins = sfc[i]
		ins2lua(ins)
	end

	L[#L+1] = 'return A;'

	return table.concat(L, '\n')
end
