require 'typegraaf'
require 'ontleed'
require 'symbool'
require 'func'
require 'fout'
require 'exp'

local obj2sym = {
	[','] = symbool.tupel,
	['[]'] = symbool.lijst,
	['{}'] = symbool.set,
	['[]u'] = X('_', 'lijst', 'letter'),
	--['[]u'] = symbool.tekst,
}

local stdbron = ontleed(file('bieb/std.code'), 'bieb/std.code')
local std = {}

for i,feit in ipairs(stdbron.a) do
	if fn(feit) == ':' then
		local t,s = arg0(feit), arg1(feit)
		std[moes(t)] = s
	end
end

function linkbieb(typegraaf)
	local stdbron = ontleed(file('bieb/std.code'), 'bieb/std.code')
	for i,feit in ipairs(stdbron.a) do
		if fn(feit) == ':' then
			local t,s = arg0(feit), arg1(feit)
			local t = kopieer(t)
			local s = kopieer(s)
			typegraaf:maaktype(t, s)
		end
	end
	return typegraaf
end

-- makkelijke types (getallen & standaardatomen)
local function eztypeer(exp)
	if isatoom(exp) then
		if tonumber(exp.v) then
			if exp.v % 1 == 0 then
				return kopieer(symbool.int)
			else
				return kopieer(symbool.getal)
			end
		elseif std[moes(exp)] then
			return kloon(std[moes(exp)])
		end
	elseif isobj(exp) then
		return obj2sym[obj(exp)]
	end
end

-- exp → type, fouten
function typeer(exp)
	local typegraaf = linkbieb(maaktypegraaf())
	local types = {} -- moes → type
	local permoes = permoes(exp) -- moes → moezen
	local fouten = {}
	local maakvar = maakvars()

	-- track
	local track = verbozeTypes
	local _types
	if track then
	_types = {}
	setmetatable(types, {
		__index = function(t,k) return _types[k] end;
		__newindex = function(t,k,v)
			v.var = v.var or maakvar()
			print('Typeer', k, combineer(v), v.var)
			if false and k == 'uit' and moes(v) ~= 'iets' then
				assert(false)
			end
			_types[k] = v end
	})
	end

	-- ta := ta ∩ tb
	function moetzijn(ta, tb, exp)
		assert(ta)
		assert(tb)

		if ta == tb then return ta end

		ta.var = ta.var or maakvar()

		local intersectie,fout = typegraaf:intersectie(ta, tb, exp)

		if not intersectie then
			fouten[#fouten+1] = fout
		elseif intersectie then
			ta = intersectie
		end

		return ta
	end

	function typeerrec(exp)
		local ez = eztypeer(exp)

		for k,sub in subs(exp) do
			typeerrec(sub)
		end

		if obj(exp) == ',' then
			local m = moes(exp)
			local t = {o=X','}
			for i,sub in ipairs(exp) do
				local subtype = assert(types[moes(sub)], 'geen type voor kind '..moes(sub))
				t[i] = subtype
			end
			types[m] = t

		elseif obj(exp) == '[]' then
			local lijsttype = exp[1] and types[moes(exp[1])] or X'iets'
			for i,sub in ipairs(exp) do
				local subtype = assert(types[moes(sub)], 'geen type voor kind '..moes(sub))
				local fout
				lijsttype,fout = typegraaf:intersectie(lijsttype, subtype, sub) --moetzijn(lijsttype, subtype, sub)
				if not lijsttype then
					lijsttype = X'iets'
					fouten[#fouten+1] = fout
				end
				types[moes(sub)] = lijsttype
			end
			local type
			if lijsttype then
				type = typegraaf:maaktype(X('_', 'lijst', lijsttype))
			else
				type = typegraaf:maaktype(X'lijst')
			end
			if atoom(lijsttype) == 'iets' then
				assign(type, X'lijst')
			end
			types[moes(exp)] = type

		-- concatenatie
		elseif fn(exp) == '‖' then
			local A = moes(arg0(exp))
			local B = moes(arg1(exp))

			moetzijn(types[A], X'lijst', arg0(exp))
			moetzijn(types[B], X'lijst', arg1(exp))

			local lijsttypeA = types[A]
			local lijsttypeB = types[B]
			local lijsttype = typegraaf:intersectie(lijsttypeA, lijsttypeB, exp)

			--print("CAT", combineer(lijsttypeA), combineer(lijsttypeB), combineer(lijsttype))

			types[moes(exp)] = lijsttype

		elseif fn(exp) == '=' or fn(exp) == ':=' then
			local A = moes(arg0(exp))
			local B = moes(arg1(exp))
			assert(types[A])
			assert(types[B])
			-- verandert types[A] -- bewust!! dit voorkomt substitutie
			--error(C(exp))
			local T = moetzijn(types[A], types[B], arg0(exp))
			types[A] = T
			types[B] = T
			types[moes(exp)] = symbool.bit
			types[moes(arg(exp))] = typegraaf:maaktype(X(',', T, T))
			types[fn(exp)] = X'ja'

		elseif fn(exp) == '⋀' then
			types[moes(exp)] = symbool.bit

		elseif fn(exp) == '⇒' then
			local A = types[moes(arg0(exp))]
			local B = types[moes(arg1(exp))]

			moetzijn(A, symbool.iets, arg0(exp)) -- TODO bit
			types[fn(exp)] = X'functie'
			types[moes(exp)] = B

		elseif fn(exp) == "'" then
			local A = types[moes(exp.a)]
			types[moes(exp)] = A
			types["'"] = X'functie'

		-- compositie
		elseif fn(exp) == '∘' then
			local A = types[moes(arg0(exp))]
			local B = types[moes(arg1(exp))]
			local anyfuncA = X('→', 'iets', 'iets')
			local anyfuncB= X('→', 'iets', 'iets')

			moetzijn(A, anyfuncA, arg0(exp))
			moetzijn(B, anyfuncB, arg1(exp))

			local  inA = arg0(A)
			local uitA = arg1(A)
			local  inB = arg0(B)
			local uitB = arg1(B)
				
			if not (inA and uitA and inB and uitB) then
				local fout = typeerfout(exp.loc,
					"compositiefout in {code}: kan {exp} en {exp} niet componeren",
					bron(exp), A, B)
				fouten[#fouten+1] = fout
				types[moes(exp)] = kopieer(symbool.iets)
				return
			end

			-- compo
			local compositie = X('→', inA, uitB)

			local inter = moetzijn(uitA, inB, arg1(exp))
			--assign(A.a[2], inter)
			--assign(B.a[1], inter)
			--moetzijn(arg1(A), inter)
			--moetzijn(arg0(B), inter)
			A.a[2] = inter
			B.a[1] = inter

			types[moes(exp)] = compositie

		elseif false and fn(exp) == '_' and atoom(arg0(exp)) == 'vouw' then
			types['vouw'] = X'functie'
			types[moes(exp)] = X'iets'

		---------- linq
		-- vouw: lijst(A), (A,A → B) → lijst(B)
		elseif fn(exp) == '_' and atoom(arg0(exp)) == 'vouw' then
			local expargs = types[moes(arg1(exp))]

			--print('expargs1', combineer(expargs))
			local anya = X'iets'
			local anyb = X'iets'
			local lijsta = X('_', 'lijst', anya)
			local anyfunc = X('→', X(',', anya, anya), anyb)

			-- A,A → B
			local anyargs = X(',', lijsta, anyfunc)

			local expargs = moetzijn(expargs, anyargs, arg1(exp))

			-- (A,A → B), lijst(A)   ⇒   lijst(A) = A, lijst(B) = B
			-- lijst, fn
			--print('expargs2', combineer(expargs))

			-- vouw: lijst(A), (A,A → B)
			local lijst = expargs[1]
			local func  = expargs[2]
			local funcargs = arg0(func)

			--funcargs.a[1] = moetzijn(funcargs.a[1], expargs
			--print(combineer(arg(lijst)), combineer((funcargs)))
			moetzijn(arg1(lijst), funcargs[1], exp)

			--[[
			print('VOUW')
			print(combineer(funcargs[1]))
			print(combineer(funcargs[2]))
			print(combineer(lijst))
			]]

			funcargs[1] = moetzijn(funcargs[1], arg1(lijst), exp)
			funcargs[2] = moetzijn(funcargs[2], funcargs[1], exp)
			lijst.a[2] = funcargs[1]
			--error(C(anya))

			moetzijn(arg1(lijsta), anya, exp)
			local sub = X('resultaat van '..C(arg1(exp)[2]))
			sub.loc = exp.loc
			moetzijn(arg1(lijsta), arg1(func), sub) -- TODO

			-- A,A → B  ⇒ arg₀ = arg₁ 
			moetzijn(arg0(anyfunc)[1], arg0(anyfunc)[2], exp)

			types['vouw'] = X'functie'
			types[moes(exp)] = arg1(func)


		-- indexeer
		-- a _ b ⇒ ((X→Y) _ X) : Y
		elseif fn(exp) == '_' then
			local functype = types[moes(arg0(exp))]
			local argtype = types[moes(arg1(exp))]
			assert(functype)
			assert(argtype)

			--print('____', combineer(argtype), combineer(functype), combineer(exp), combineer(argtype))

			local funcarg, returntype

			if fn(functype) == '→' then

				--print('voor', C(functype), C(anyfunc))

				if fn(functype) ~= '→' then
					local anyfunc = typegraaf:maaktype(X('→', 'iets', 'iets'))
					functype = moetzijn(functype, anyfunc, arg0(exp))
				end

				--print('na', C(functype), C(anyfunc))

				funcarg = moetzijn(argtype, arg0(functype), arg1(exp))
				functype.a[1] = funcarg
				returntype = functype.a[2]

				--error(C(arg0(functype)))

			elseif obj(functype) == ',' then
				returntype = X'iets' --{f=X'|', a=functype}
			elseif obj(functype) == '[]' then
				returntype = moetzijn(argtype, arg1(functype), exp)
			elseif fn(functype) == '_' and arg0(functype) == 'lijst' then
				moetzijn(argtype, X'int', exp)
				returntype = arg1(argtype) or X'iets'
			else
				local fout = typeerfout(exp.loc or nergens,
					"{code}: ongeldig functieargument {exp} voor {exp}",
					bron(exp), argtype, functype
				)
				--fouten[#fouten+1] = fout
				--error(C(functype))
				--returntype = typegraaf:maaktype(X'fout')
				returntype = X'iets'
			end

			types[moes(exp)] = returntype

		elseif fn(exp) == '→' then
			local f = arg0(exp)
			local a = arg1(exp)

			local F = moes(f)
			local A = moes(a)

			-- tf : A → B
			-- tg : B → C
			local tf = types[F]
			local ta = types[A]
			
			-- a → b
			local ftype = X('→', tf, ta)
			-- TODO
			--types[moes(exp)] = types[moes(exp)] or kopieer(arg1(std.functie))
			--moetzijn(types[moes(exp)], ftype, exp)
			types[moes(exp)] = ftype

		elseif fn(exp) == ':' then
			local doel,type = arg0(exp), arg1(exp)
			local type = typegraaf:maaktype(type)
			--moetzijn(doel, type, arg0(exp)) -- TODO
			types[moes(exp)] = symbool.bit
			types[fn(exp)] = symbool.bit
 
		elseif ez then
			types[moes(exp)] = ez

		-- standaardtypes
		elseif std[fn(exp)] then
			local stdtype = kloon(std[fn(exp)])
			local argtype = types[moes(exp.a)]
			local inn, uit = arg0(stdtype), arg1(stdtype)

			-- typeer arg
			--types[moes(exp.a)] = types[moes(exp.a)] or inn
			--print('ARGTYPE voor', combineer(argtype), combineer(inn), combineer(exp.a))
			local sub = exp.a
			if not sub then
				sub = X('argument van '..combineer(exp))
				sub.loc = exp.loc
			end
			moetzijn(argtype, inn, sub)
			--print('ARGTYPE na', combineer(argtype))

			-- typeer exp
			types[moes(exp)] = uit

		else
			local m = moes(exp)
			types[m] = types[m] or X'iets'
		end

	end

	typeerrec(exp)

	--do return types[moes(exp)], fouten, types end

	-- is alles getypeerd?
	for moes,exps in pairs(permoes) do
		if false and (not types[moes] or _G.moes(types[moes]) == 'iets')
				and not std[moes]
				and not typegraaf.types[moes]
				then
				--and moes:sub(1,1) ~= ',' then
			local exp = exps[1]
			local fout = typeerfout(exp.loc or nergens,
				"kon type niet bepalen van {code}",
				isobj(exp) and combineer(exp) or locsub(exp.code, exp.loc)
			)
			fouten[#fouten+1] = fout
		end
	end

	if verbozeTypes then
		print '# Eindtypes'
		for moes,type in pairs(_types or types) do
			print('EINDTYPE', type.var, moes, combineer(type))
		end
	end

	if track then
		types = _types or types
	end

	return types[moes(exp)], fouten, types
end

