require 'exp'
require 'util'
require 'graaf'
require 'symbool'
require 'combineer'

require 'bouw.blok'

--[[

f(x) = x + 1
exitcode = f(3)


start:
	a := 3
	b := call f, 3
	ret b
-> f
<- f

f:
	y := arg 0
	ret := y + 1
-> start
<- start
	
]]

-- plet tot een fijne moes
-- dit bevat alleen atomaire functies, die tellen niet mee voor de (((factor)))
local function plet(waarde, maakvar)
	--for exp in boompairs(waarde) do assert(not isfn(exp) or isatoom(exp.fn)) end

	-- bepaal diepte
	local diepte = {}

	for exp in boompairsdfs(waarde) do
		-- bladwaarden krijgen 1
		if isatoom(exp) then
			diepte[exp] = 1
		else
			diepte[exp] = 0
			local gelijk = false
			-- bepaal rec diepte
			for i,v in ipairs(exp) do
				if diepte[v] > diepte[exp] then gelijk = false
				elseif diepte[v] == diepte[exp] then gelijk = true
				end
				diepte[exp] = math.max(diepte[exp], diepte[v])
			end
			-- als ze zelfde zijn is er 1 extra nodig (voor phi?)
			if gelijk
				then diepte[exp] = diepte[exp] + 1
			end
		end
	end

	local vars = {} -- exp2vars
	local stats = {}

	local function r(exp)
		--if isatoom(exp) then return end
		-- diepste tak eerst
		if diepte[exp] == 0 and false then
			return
		else
			-- sorteer op diepte
			local args = {}
			for i,v in ipairs(exp) do
				args[i] = v
			end
			table.sort(args, function (a, b) return diepte[a] < diepte[b] end)

			for i,v in ipairs(args) do
				-- alleen expressiekinderen hoeven berekend te worden
				if isexp(v) then
					--print("SUB", exp2string(args[i]))
					args[i] = r(args[i])
				end
			end

			-- nu al onze kinderen geweest zijn kunnen wij
			for i,v in ipairs(exp) do
				exp[i] = vars[v] or exp[i]
			end

			local var = maakvar()
			vars[exp] = X(var)
			stats[#stats+1] = X(sym.ass, var, exp)
		end
	end

	r(waarde)

	return stats
end

function controle(exp, maakvar)
	local graaf = maakgraaf()
	local maakvar = maakvar or maakvars()
	local procindex = maakindices()
	local procs = {} -- naam → exp

	local function maakproc()
		return 'p'..procindex()
	end

	local function conR(exp, naam)
		if isatoom(exp) then return exp end

		local op = fn(exp)
		if op == '=>' then
			if not exp[3] then exp[3] = X'0' end

			--  cond:
			--
			--     +-  als  -+
			--     |         |
			--     v         v
			--   dan       anders
			--     |         |
			--     |         |
			--     +-> phi <-+
			local als    = maakproc()
			local dan    = maakproc()
			local anders = maakproc()
			local phi    = maakproc()

			-- sprongen
			local keus = X('ga', als, dan, anders)
			local daarna = X('ga', phi)

			-- als 
			local bals = maakblok(X(als), plet(conR(exp[1]), maakvar), keus)
			local bdan = maakblok(X(dan), plet(conR(exp[2]), maakvar), daarna)
			local banders = maakblok(X(anders), plet(conR(exp[3]), maakvar), daarna)

			keus[1] = bals.res
			
			local alsdan = {fn=sym.als, bals.res, bdan.res, banders.res}

			local bphi = maakblok(X(phi), plet(alsdan, maakvar), X'eind')

			-- linken
			graaf:link(bals, banders)
			graaf:link(bals,    bdan)
			graaf:link(bdan,    bphi)
			graaf:link(banders, bphi)
			return conR(exp[1]), maakvar
			--return X(phi)
			--return plet(alsdan, maakvar)
		else
			local e = {}
			e.fn = conR(exp.fn)
			for k,v in ipairs(exp) do 
				e[k] = conR(v)
			end
			return e
			--return plet(e, maakvar)
		end
	end

	local start = maakblok(X'start', plet(conR(exp), maakvar), X'stop')
	--local start = maakblok(X'start', conR(exp), X'stop')

	-- startfix
	local ret = start.stats[#start.stats][1]
	table.insert(start.stats, X(':=', 'ret', ret))

	graaf:punt(start)

	return graaf
end

if test then
	require 'lisp'
	require 'ontleed'
	local E = ontleedexp

	local cfg = controle(E[[
als 2 > 1 dan
	2 * 3 + 4 / (2 + 3)
anders
	2 / 3
]])

	for blok in pairs(cfg.punten) do
		print(blok)
	end

	local graaf2, blokken2 = controle(E[[
;2 * 3 + 8 / 7 ^ 2 - (3 * 2 + 8 / 7)
(8*2/3*4) + (_fn(3, _arg(3) + 1))(2)
]])

	--control(E'_fn(0, _arg(0) + 1 · 3 ^ 2 + 8)')
	--control(E'_fn(0, _arg(0) ⇒ b · c + 3 / 7 ^ 3)')
end

