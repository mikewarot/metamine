local function unparse_atom(atom)
  atom = string.format('%q', atom)
  atom = string.gsub(atom, '\n', '\\n')
  atom = atom:sub(2,-2)
  return atom
end

local function unparse_len(sexp)
  local len
  if atom(sexp) then
    len = #unparse_atom(sexp)
  else
    len = 2 + #sexp-1 -- (A B C)
    for i,sub in ipairs(sexp) do
      len = len + unparse_len(sub)
    end
  end
  return len
end

function atom(sexp)
	return type(sexp) == 'string'
end

local function unparse_work(sexpr, maxlen, tabs, res)
  tabs = tabs or 0
  res = res or {}
  if atom(sexpr) then
    len = #sexpr
    table.insert(res, unparse_atom(sexpr))
  else
    local split = unparse_len(sexpr) > maxlen
    table.insert(res, '(')
    for i,sub in ipairs(sexpr) do
      if split then
        table.insert(res, '\n')
        table.insert(res, string.rep('  ', tabs+1))
      end
      unparse_work(sub, maxlen, tabs+1, res)
      if next(sexpr, i) then
        table.insert(res, ' ')
      end
    end
    if split then
      table.insert(res, '\n')
      table.insert(res, string.rep('  ', tabs))
    end
    table.insert(res, ')')
  end
  return res
end

function unparseSexp(sexpr)
  if not sexpr then return 'none' end
  return table.concat(unparse_work(sexpr, 40))
end
unlisp = unparseSexp

function lispNeq(self,other)
	if atom(self) ~= atom(other) then return false end
	if atom(self) and atom(other) then return self ~= other end
	if type(self) ~= 'table' or type(other) ~= 'table' then
		error('ongeldig type '..type(self)..', '..type(other))
	end
	if #self ~= #other then return true end
	for i,v in ipairs(self) do
		if lispNeq(self[i], other[i]) then
			return true
		end
	end
	return false
end

function parseSexp2(sexpr)
	local stack = {}
	local i = 1
	local line = 1
	local ch = 1

	function get()
		local char
		repeat
			char = sexpr:sub(i,i)
			if char == '' then
				char = nil
			end
			if char == ';' then
				i = sexpr:find('\n', i)
				line = line + 1
				ch = 1
			end
		until char ~= ';'
		return char
	end

	function consume()
		if sexpr[i] == '\n' then
			line = line + 1
			ch = 1
		else
			ch = ch + 1
		end
		i = i + 1
		return i > #sexpr
	end
	
	local blank = {[' ']=true, ['\r']=true, ['\n']=true, ['\t']=true}
	
	while i <= #sexpr do
		-- skip space
		while blank[get()] do
			consume()
		end
		
		-- bracket?
		if get() == '(' then
			table.insert(stack, new())
			consume()
		
		-- close?
		elseif get() == ')' then
			if #stack == 1 then
				return stack[1]
				--error(line..':'..ch..'\tclosing too much')
			end
			table.insert(stack[#stack-1], stack[#stack])
			table.remove(stack, #stack)
			consume()

		-- error?
		elseif not get() then
			break
	
		-- list?
		else
			local id = {}
			-- string
			if get() == "'" then
				while get() and get() ~= "'" do
					if get() == '\\' then
						table.insert(id, '\\')
						consume()
						table.insert(id, get())
						consume()
					elseif get() == "'" then
						table.insert(id, get())
						consume()
						break
					else
						consume()
						table.insert(id, get())
					end
				end

			-- normal token
			else
				while get() and not blank[get()] and get()~=')' and get()~='(' do
					table.insert(id, get())
					consume()
				end
			end
			id = table.concat(id)
			if #stack == 0 then
				table.insert(stack, id)
			elseif type(stack[#stack]) ~= 'table' then
				error(line..':'..ch..'\tteveel delen')
			else
				table.insert(stack[#stack], id)
			end
		end
	end
	
	if #stack > 1 then
		error('te weinig sluitende haakjes')
	elseif #stack < 1 then
		error('niets meer over')
		return 
	end
	
	return stack[1]
end

require 'lex'
function lisp(t)
	local i = 1
	local noise = {[';']=true, [' ']=true,
	['\r']=true, ['\n']=true, ['\t']=true}
	local tokens = lex(t)
	local stack = {{}}
	if not tokens then
		error('parse-error')
	end

	function peek()
		-- skip comments
		while tokens[i] and
		noise[tokens[i]:sub(1,1)] do
			i = i + 1
		end
		return tokens[i]
	end

	function pop()
		local v = peek()
		i = i + 1
		return v
	end

	while true do
		local token = pop()

		if token == '(' then
			stack[#stack+1] = {}

		elseif token == ')' then
			if #stack == 1 then
				error('teveel sluitende haakjes')
			end
			table.insert(stack[#stack-1], stack[#stack])
			stack[#stack] = nil
		
		elseif not token then
			break
		
		else
			table.insert(stack[#stack], token)
		end
	end

	-- samenvoeg
	for i=#stack,2,-1 do
		table.insert(stack[i-1], stack[i])
	end

	if #stack[1] > 1 then
		error('ruis na data')
	end
	return stack[1][1]
end