local tel = { X'fn.eerste', X'fn.tweede', X'fn.derde', X'fn.vierde' }
local id = X'fn.id'
local dup = X'fn.dup'
local merge = X'fn.merge'
local constant = X'fn.constant'
local inc = X'fn.inc'
local dec = X'fn.dec'

-- defunctionaliseer (maak er een gebonden functie van)
function defunc(exp, argindex, klaar)
	klaar = klaar or {}
	if klaar[exp] then return klaar[exp] end
	local res
	local num = isfn(exp) and arg1(exp) and isatoom(arg1(exp)) and tonumber(atoom(arg1(exp)))

	if not bevat(exp, X'_arg') then
		res = X('_', constant, exp)

	elseif fn(exp) == '_' and atoom(arg0(exp)) == '_arg' and atoom(arg1(exp)) == argindex then
		res = id

	-- fn.eerste t/m fn.vierde
	elseif fn(exp) == '_' and num and num >= 0 and num < 4 and num % 1 == 0 then
		local sel = tel[num + 1]
		local A = defunc(arg0(exp), argindex, klaar)
		if atoom(A) == 'fn.id' then
			res = X(sel) 
		else
			res = X('∘', A, X(sel))
		end

	-- fn.inc
	elseif fn(exp) == '+' and isobj(arg(exp)) and #obj(arg(exp)) == 2
			and (arg0(exp).v == '1' or arg1(exp).v == '1') then
		if arg0(exp).v == '1' then
			res = X('_', inc, arg0(exp).v)
		else
			res = X('_', inc, arg1(exp).v)
		end

	-- f(a)  ->  c(a) ∘ f
	elseif isfn(exp) then
		local A = defunc(arg(exp), argindex, klaar)
		if atoom(A) == 'fn.id' then
			res = fn(exp)
		else
			res = X('∘', A, fn(exp))
		end

	elseif isobj(exp) then
		local mergeval = {o=exp.o}
		for k, sub in subs(exp) do
			mergeval[k] = defunc(sub, argindex, klaar)
		end


		-- special case: merge(id, id) = dup
		if atoom(mergeval[1]) == 'fn.id' and atoom(mergeval[2]) == 'fn.id' and not mergeval[3] then
			res = dup
		elseif #mergeval == 0 then
			res = X'∅'
		elseif #mergeval == 1 then
			res = X('_', merge, mergeval[1])
		else
			res = X('_', merge, mergeval)
		end
	elseif atoom(exp) then
		res = exp
	end

	klaar[exp] = res
	return res
end