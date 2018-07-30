require 'symbool'
require 'typeer'

function subst(exp, van, naar)
	if isatoom(exp) then
		if exp == van then
			return naar
		else
			return exp
		end
	else
		local r = {}
		for i=1,#exp do
			r[i] = subst(exp[i],van,naar)
		end
		return r
	end
end

function issimpel(t)
	if isatoom(t) and t ~= 'iets' then return true
	elseif t[1] ~= ',' then return false
	else
		for i=2,#t do
			if type(t[i]) ~= 'string' and t[i] ~= 'bit' and t[i] ~= 'int' and t[i] ~= 'getal' then
				return false
			end
		end
		print('issimpel', leed(t))
		return true
	end
end

-- EMIT naam(index) = LOOP_SUBST(val, index)
function loop_subst(val, naam, index, typen, uitgerold)
	local val = kopie(val)
	-- doorloop bronnen, fix ariteit
	for bron in spairs(var(val)) do
		local len = lijstlen(typen[bron])
		uitgerold[naam] = len
		if len then
			local doel
			if uitgerold[bron] then
				doel = bron..index
			else
				doel = {bron, index}
			end
			val = subst(val,bron,doel)
		end
	end
	--local naam = naam .. '_'..(i-1)
	return {'=', naam, val}
end

function uitrol(stroom, typen)
	local r = {}
	local uitgerold = {} -- naam -> uitrol?
	for i,v in ipairs(stroom) do
		local naam,val = v[2],v[3]
		local t = typen[naam]

		if lijstlen(t) then
			local n = tonumber(t[3])
			local fn = val[1]
			local tfn = typen[fn]
			local doeltype = typen[naam]

			if isexp(val) then
				--print('UITROL',naam..'^'..n,leed(tfn),leed(doeltype))
			end

			-- lijst
			if isexp(val) and val[1] == '[]' then
				--[[
				-- uitgerold
				uitgerold[naam] = #val-1
				local stam = naam
				for i=2,#val do
					local naam = stam..''..(i-2)
					r[#r+1] = {'=', naam, val[i]}
				end
				]]
				r[#r+1] = {'=', naam, val}

			-- kleine loopjes
			elseif tfn and isexp(val) and
					issimpel(tfn[2]) and isatoom(tfn[3]) then

				print('ROL')
				
				-- gebounde loop
				if not n or n > 8 then
					local inaam = naam..'_i'

					-- lengte
					local lijst

					if n then
						lijst = {'..', '0', n}
					else
						for bron in spairs(var(val)) do
							local len = lijstlen(typen[bron])
							if tonumber(len) then
								lijst = {'..', '0', tostring(len)}
								break
							else
								lijst = {'..', '0', {'#', bron}}
								break
							end
						end
							
					end

					-- goed
					if lijst then

						r[#r+1] = {'=', inaam, lijst}
						r[#r+1] = loop_subst(val, {naam, inaam}, inaam, typen, uitgerold)

					-- fout
					else
						error(color.red..'kon lengte niet bepalen van '..leed(val)..color.white)
					end

				-- uitgerolde loop
				elseif n and n <= 8 then
					for i=1,n do
						local index = tostring(i-1)
						r[#r+1] = loop_subst(val, naam..'_'..index, index, typen, uitgerold)
					end

					-- collect
					local l = {'[]'}
					for i=1,n do
						l[#l+1] = tostring(naam)..'_'..(i-1)
					end
					r[#r+1] = {'=', naam, l}

				end
					
			else
				print('EMIT normale loop')
				r[#r+1] = v
			end
		else
			r[#r+1] = v
		end
	end

	-- laatste maken
	local doel = stroom[#stroom][2]
	for n,v in spairs(uitgerold) do print(n,v) end
	if uitgerold[doel] then
		-- inrollen
		local a = {'[]'}
		print(uitgerold[doel])
		for i=1,uitgerold[doel] do
			local index = tostring(i-1)
			a[#a+1] = doel..index
		end
		r[#r+1] = {'=', doel, a}
	end
	--if stroom[#stroom]
	return r
end
			
