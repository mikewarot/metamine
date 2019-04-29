require 'exp'
require 'func'
local fmt = string.format

local sysregs = { 'rdi', 'rsi', 'rdx', 'r10', 'r8', 'r9' }
local abiregs = { 'rdi', 'rsi', 'rdx', 'rcx', 'r8', 'r9'} -- r10 is static chain pointer in case of nested functions
local registers = { 'r12', 'r13', 'r14', 'r15', 'rbx', 'rdx', 'rsi', 'rdi', 'r8', 'r9', 'r10', 'rax' }
for i, register in pairs(registers) do
	registers[register] = i
end

local syscalls = {}
local f = io.open('data/syscalls')
for syscall in f:lines() do
	syscalls[#syscalls+1] = syscall
	syscalls[syscall] = #syscalls-1
end


local cmpops = {
	['='] = 'je', ['!='] = 'jne',
	['>'] = 'jg', ['<'] = 'jl',
	['>='] = 'jge', ['<='] = 'jle',
}

function assembleer(stats)
	local regs = {} -- reg -> var, var -> reg
	local tijd = {} -- reg -> vanaf
	local stapel = {} -- var -> offset
	local hstapel = 0 -- stapelhoogte
	for i,reg in ipairs(registers) do tijd[reg] = 0 end

	local d = {} -- data
	local t = {} -- code

	local function opstapel(reg)
		if stapel[reg] then
			t[#t+1] = fmt('mov -%s[%s], %s', tostring(hstapel), 'rbp', reg)
			return
		end
		t[#t+1] = 'push '..reg
		local var = regs[reg]
		regs[var] = nil
		regs[reg] = nil
		stapel[var] = hstapel
		hstapel = hstapel - 8
	end

	local function maakvrij(reg)
		if not regs[reg] then
			-- hij is al vrij
			return nil
		end
		--assert(reg, error('geen reg'))
		for i,ander in ipairs(registers) do
			if not regs[ander] then
				-- hij is vrij! hernoem
				t[#t+1] = fmt('mov %s, %s', ander, reg)
				local var = regs[reg]
				--regs[andervar] = ander -- dit hoeft dus niet
				regs[ander] = var
				regs[var] = ander
				regs[reg] = nil
				return ander
			end
		end
		-- pak een willekeurige
		local reg = registers[math.random(1, #registers)]
		opstapel(reg)
		return reg
		--error "te weinig registers"
	end

	local function herstel(reg, waarde)
		if waarde then
			t[#t+1] = fmt('mov %s, %s', reg, waarde)
		end
	end

	local i = 0
	function regalloc()
		print('ALLOC '..i)
		local reg = registers[i + 1]
		i = (i + 1) % #registers
		maakvrij(reg)
		return reg
	end

	local cmp
	for i,stat in ipairs(stats) do
		-- wat moet er berekent worden
		local naam,exp
		if stat.fn and stat.fn.v == ':=' then
			naam,exp = stat[1],stat[2]
		else
			exp = stat
		end

		if false and naam then
			local doelreg = regalloc()
		end

		-- b(0) := 'O'
		if naam and isfn(naam) then
			assert(exp.v, "kan alleen atomaire waarden in lijsten stoppen")
			local addr = regalloc()
			maakvrij('rax')
			t[#t+1] = fmt('mov rax, %s', regs[exp.v] or exp.v)
			t[#t+1] = fmt('lea %s, [%s+%s]', addr, regs[naam.fn.v], regs[naam[1].v] or naam[1].v)
			t[#t+1] = fmt('movb [%s], al', addr, regs[exp.v] or exp.v)

		-- compare
		elseif exp.fn and cmpops[exp.fn.v] then
			print(exp2string(exp))
			assert(regs[exp[1].v], exp[1].v)
			assert(regs[exp[2].v], exp[2].v)
			local a = regs[exp[1].v]
			local b = regs[exp[2].v]
			t[#t+1] = string.format('cmp %s, %s', a, b)
			cmp = cmpops[exp.fn.v]

		-- label
		elseif exp.fn and exp.fn.v == 'label' then
			local lbl = exp[1].v
			if lbl == 'start' then lbl = '_start' end
			t[#t+1] = lbl .. ':'

		-- functie einde
		elseif exp.v == 'eind' then
			t[#t+1] = 'ret'

		-- data
		elseif exp.fn and exp.fn.v == '[]' then
			assert(naam, 'data heeft geen naam')
			local t = {}
			for i=1,#exp do t[i] = exp[i].v end
			d[#d+1] = naam.v..': '..'.byte '..table.concat(t, ',')

		-- stack
		elseif exp.fn and exp.fn.v == 'data' then
			t[#t+1] = 'sub rsp, '..exp[1].v
			local reg = regalloc()
			t[#t+1] = fmt('lea %s, [rsp]', reg)
			regs[reg] = assert(naam.v)
			regs[naam.v] = assert(reg)

		-- syscall
		elseif exp.fn and syscalls[exp.fn.v] then
			local r = maakvrij('rax')
			t[#t+1] = string.format('mov rax, %d', syscalls[exp.fn.v])
			regs.rax = syscalls[exp.fn.v]
			local args = exp[1]
			if isatoom(args) then
				args = {args}
			end
			local a = {}
			for i,arg in ipairs(args) do
				-- in gebruik?
				a[i] = maakvrij(sysregs[i])
				if regs[arg.v] then 
					t[#t+1] = string.format('mov %s, %s', sysregs[i], regs[arg.v])
				elseif tonumber(arg.v) then
					t[#t+1] = string.format('mov %s, %s', sysregs[i], arg.v)

				elseif false and labels[arg.v] then
					--t[#t+1] = string.format('lea %s, %s[rip]', sysregs[i], labels[arg.v])
				else
				print('ARG',exp2string(arg))
					t[#t+1] = string.format('lea %s, %s[rip]', sysregs[i], regs[arg.v] or arg.v)
					--error(arg.v..' is onbekend')
				end
			end
			print(exp2string(exp))
			--for i,v in pairs(exp
			t[#t+1] = 'syscall\n'

			herstel('rax', r)
			for i,w in ipairs(a) do
				herstel(sysregs[i], w)
			end

		elseif exp.fn and exp.fn.v == '+=' then
			if exp[2].v == '1' then
				t[#t+1] = fmt('inc %s', regs[exp[1].v])
			else
				t[#t+1] = fmt('add %s, %s', regs[exp[1].v], regs[exp[2].v] or exp[2].v)
			end

		elseif exp.fn and exp.fn.v == '*=' then
			if exp[2].v == '2' then
				t[#t+1] = fmt('shl %s', regs[exp[1].v])
			else
				t[#t+1] = fmt('mul %s', regs[exp[1].v], regs[exp[2].v] or exp[2].v)
			end

		elseif exp.fn and exp.fn.v == '/=' then
			maakvrij('rdx')
			maakvrij('rax')
			t[#t+1]= fmt('mov rax, %s', regs[exp[1][1].v])
			t[#t+1]= fmt('xor rdx, rdx')
			t[#t+1] = fmt('idivq %s',  regs[exp[2].v])
			if isfn(exp[1]) and exp[1].fn.v == ',' then
				local a = exp[1][1].v
				local b = exp[1][2].v
				--regs[a] = 'rax'
				regs[b] = 'rdx'
				--regs['rax'] = a
				regs['rdx'] = b
			end
			t[#t+1]= fmt('mov %s, rax', regs[exp[1][1].v])

		-- jump
		elseif exp.fn and exp.fn.v == 'ga' then
			if exp[1].v == 'start' then exp[1].v = '_start' end
			t[#t+1] = 'jmp '..exp[1].v

		-- argument
		elseif exp.fn and exp.fn.v == 'arg' then
			local i = exp[1].v
			local reg = abiregs[i+1] or error('ongeldig register')
			regs[reg] = naam.v
			regs[naam.v] = reg

		elseif exp.fn and exp.fn.v == '=>' then
			assert(cmp)
			assert(exp[2].fn.v == 'ga')
			t[#t+1] = string.format('%s %s', cmp, exp[2][1].v)
			cmp = nil

		elseif tonumber(exp.v) or tonumber(regs[exp.v]) then
			assert(naam, "nutteloze opdracht gevonden: "..exp2string(stat))
			local doel = regalloc()
			regs[doel] = exp.v
			regs[naam.v] = doel
			tijd[doel] = #t + 1
			t[#t+1] = string.format('mov %s, %s', doel, exp.v)

		-- call!
		elseif exp.fn and exp.fn.v then
			local args = exp[1]
			if exp[2] then args = exp end
			local abis = {}
			for i,n in ipairs(args) do
				abis[#abis+1] = maakvrij(abiregs[i])
				t[#t+1] = fmt('mov %s, %s  # argument', abiregs[i], regs[n.v] or n.v)
			end
			t[#t+1] = 'call '..exp.fn.v
			regs['rax'] = naam.v
			regs[naam.v] = 'rax'

		else
			t[#t+1] = fmt('mov rax, %s', regs[exp.v])
			t[#t+1] = fmt('ret')
		end
	end

	local header = [[
.intel_syntax noprefix
.text
.global	_start

.section .text

]]

	return header .. table.concat(t, '\n') .. '\n' .. table.concat(d, '\n') .. '\n'
end

--[[
a := 3
	sub rsp, 4
	rax(a) =
		mov rax, 3

a := data(4)
	sub rsp, 4
	a = start.rbp + 4
	rax(a) =
		lea rax, [start.rbp - 4]

a := "hoi\n"
	.a: .string "hoi\n"
	rax(a) =
		lea rax, .a[rip]

]]

-- swagolienja
function elf(asm)
	local naam = os.tmpname()
	local bd = io.open(naam..'.s', 'w')
	bd:write(asm)
	bd:close()
	os.execute(string.format('as -g %s.s -o %s.o --no-pad-section -R', naam, naam))
	os.execute(string.format('ld -g %s.o -o %s -n --build-id=none -static', naam, naam))
	--os.execute(string.format('strip %s', naam))
	local elf = file(naam)
	--os.remove(naam..'.s')
	--os.remove(naam..'.o')
	--os.remove(naam)
	return elf
end

if true or test then
	require 'ontleed'
	local O = ontleed
	local rtl = O[[

d0 := data(1000)
d1 := "hoi\n"
r0 := read(0, d0, 1000)
r1 := write(1, d1, 4)
r2 := write(1, d0, r0)
r3 := exit(0)

]]
	require 'util'
	local b = file 'b.rtl'
	b = b:gsub('\t','')
	b = b:gsub('(%w+):[^=]', function(lbl) return '\nlabel '.. lbl..'\n' end)
	print(b)
	local rtl = O(b)
	print(exp2string(rtl))

	require 'exp'
	local asm = assembleer(rtl)
	print(asm)
	local elf = elf(asm)
	file('a.s', asm)
	file('a.elf', elf)
	os.execute('chmod +x a.elf')
	os.execute('./a.elf')
end
