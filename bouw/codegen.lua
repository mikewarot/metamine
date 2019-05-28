require 'exp'
require 'combineer'
require 'bouw.cfg'

local fmt = string.format

local sysregs = { 'rdi', 'rsi', 'rdx', 'r10', 'r8', 'r9' }
local abiregs = { 'rdi', 'rsi', 'rdx', 'rcx', 'r8', 'r9'} -- r10 is static chain pointer in case of nested functions
local registers = { 'r12', 'r13', 'r14', 'r15', 'r10', 'r9', 'r8', 'rcx', 'rdx', 'rsi', 'rdi', 'rax' }
local cmp = {
	['>'] = 'g',
	['>='] = 'ge',
	['='] = 'e',
	['!='] = 'ne',
	['<='] = 'le',
	['<'] = 'l',
}


local function inlinetekst(exp, opslag, loc, t)
	local min,concat = math.min, table.concat
	assert(fn(exp) == '[]')
	-- lengte
	t[#t+1] = fmt('movq %d[rsp], %d', loc-8, #exp)
	for i=1,#exp,4 do
		local num = {'0x'}
		local s = {}
		for j=min(i+4-1,#exp),i,-1 do
			if tonumber(exp[j].v) then
				num[#num+1] = string.format('%02x', exp[j].v)
			else
				num[#num+1] = '00'
				-- custom pointer
				s[#s+1] = fmt('movb al, %d[rsp]', opslag[exp[j].v])
				s[#s+1] = fmt('movb %d[rsp], al', loc + (j-1))
			end
		end
		-- getal
		-- sla op
		t[#t+1] = fmt('mov eax, %s', concat(num))
		t[#t+1] = fmt('mov %d[rsp], eax', loc + (i-1))
		-- extra's
		for i,v in ipairs(s) do
			t[#t+1] = v
		end
	end
end

function codegen(cfg)
	if verbozeAsm then print(); print('=== ASSEMBLEERTAAL ===') end
	-- naam -> opslag
	local opslag = {}
	-- naam -> # slots
	local slots = {}
	-- naam -> proc
	local labels = {}
	-- stapelgrootte
	local top = 0
	-- instructies
	local t = {}

	if verbozeAsm then
		setmetatable(t, {
				__newindex=function(t,k,v)
					rawset(t,k,v)
					print(v)
			end})
	end

	-- proloog
	t[#t+1] = [[
.intel_syntax noprefix
.text
.global	_start

.section .text
]]

	-- alloceer
	if verbozeOpslag then
		print()
		print('=== OPSLAG ===')
	end
	for blok in spairs(cfg.punten) do
		labels[blok.naam.v] = true
		for i, stat in ipairs(blok.stats) do
			local naam,exp,f = stat[1].v, stat[2], stat[2] and fn(stat[2])
			if not opslag[naam] then
				local len = 8
				-- lijst?
				if f == 'b[]' then
					len = #exp + 8
				elseif f == '[]' then
					len = #exp + 8 + 8 + 0x400-- ptr, len, data
				elseif f == 'd[]' then
					len = 4 * exp + 8
				elseif f == 'q[]' then
					len = 8 * exp + 8
				elseif f == '||' then
					len = 8 + 0x400
				end
				local slot = math.floor(len / 8)
					
				slots[naam] = slot
				top = top - math.ceil(len/8) * 8
				opslag[naam] = top

				if verbozeOpslag then
					print(string.format('%s:\tOffset %d, %d slots, %d bytes', naam, opslag[naam], slot, len))
				end
			end
		end
	end
	if verbozeOpslag then
		print()
	end

	local function laad(reg, val, noot)
		if noot then noot = ' \t# '..noot
		else noot = '' end

		if val == 'ja' then val = 1 end
		if val == 'nee' then val = 0 end
		if tonumber(val) then
			t[#t+1] = fmt('mov %s, %s', reg, val) .. noot
		elseif labels[val] then
			t[#t+1] = fmt('lea %s, %s[rip]', reg, val) .. noot
		else
			assert(opslag[val], 'onbekende waarde: '..tostring(val))
			--t[#t+1] = fmt('mov %s, [rsp-8*%s]', reg, opslag[val])
			t[#t+1] = fmt('mov %s, %d[rsp]', reg, opslag[val]) .. noot
		end
	end

	local function opsla(val, reg, noot)
		if noot then noot = ' \t# '..noot
		else noot = '' end

		assert(opslag[val])
		--t[#t+1] = fmt('mov [rsp-8*%s], %s', opslag[val], reg)
		t[#t+1] = fmt('mov %d[rsp], %s', opslag[val], reg) .. noot
	end

	local maakvar = maakvars()

	-- genereer dan echt
	local function blokgen(blok)
		if blok.naam.v == 'start' then
			t[#t+1] = '_start:'
		else
			t[#t+1] = blok.naam.v .. ':'
		end
		for i,stat in ipairs(blok.stats) do
			local op,naam,val,exp = fn(stat),
				stat[1].v,
				stat[2] and stat[2].v,
				stat[2]
			local f = exp and fn(stat[2])
			t[#t+1] = '# '..combineer(stat)

			-- vertakkingsvrije keus
			if op == ':=' and f == '=>' then
				local c,d,a = exp[1],exp[2],exp[3]
				--local lc = #
				laad('rcx', c.v, c.v)
				laad('rax', a.v, a.v)
				laad('rdx', d.v, d.v)
				t[#t+1] = 'cmp rcx, 1'
				t[#t+1] = 'cmove rax, rdx \t# rax = rcx ? rdx : rax'
				opsla(naam, 'rax', naam)

			elseif op == ':=' and f == '!' then
				laad('rax', exp[1].v)
				t[#t+1] = 'cmp rax, 0'
				t[#t+1] = 'mov rax, 0'
				t[#t+1] = 'mov rbx, 1'
				t[#t+1] = 'cmove rax, rbx'
				opsla(naam, 'rax', naam)

			elseif f == '_arg' then
				opsla(naam, abiregs[1])-- + tonumber(atoom(exp, 1))])

			elseif f == '..' then
				laad('rax', exp[1].v) -- onder
				laad('rbx', exp[2].v) -- boven
				-- rcx = count
				t[#t+1] = 'mov rcx, rbx'
				t[#t+1] = 'sub rcx, rax'
				t[#t+1] = 'add rcx, 8'
				-- malloc!
				t[#t+1] = 'mov rdi, rcx'
				t[#t+1] = 'call malloc'
				t[#t+1] = 'add rax, 8'
				opsla(naam, 'rax', 'malloc lijst')

				local label = 'itot'..maakvar()
				laad('rbx', exp[1].v) -- onder
				laad('rcx', exp[2].v) -- boven
				t[#t+1] = 'sub rcx, rbx'
				t[#t+1] = 'mov -8[rax], rcx'

				t[#t+1] = label..'_begin:'
				t[#t+1] = fmt('cmp rcx, 0')
				t[#t+1] = fmt('je %s_eind', label)

				-- doe
				t[#t+1] = fmt("movb [rax], bl")
				t[#t+1] = fmt('inc bl')
				t[#t+1] = fmt('inc rax')
				t[#t+1] = fmt('dec rcx')

				t[#t+1] = fmt('jmp %s_begin', label)

				t[#t+1] = label..'_eind:'
				laad('rax', naam)

			elseif f == 'map' then
				laad('rax', exp[1].v) -- lijst
				opsla(naam, 'rax') -- lijst
				laad('rbx', exp[2].v) -- functie
				t[#t+1] = fmt('mov rcx, -8[rax]') -- lengte

				-- start
				local label = 'map'..maakvar()
				t[#t+1] = fmt('%s_start:', label)

				-- lus
				t[#t+1] = fmt('dec rcx')
				t[#t+1] = fmt('cmp rcx, 0')
				t[#t+1] = fmt('jl %s_eind', label)

				-- 
				t[#t+1] = fmt('movb dil, [rax+rcx]')
				t[#t+1] = fmt('push rax')
				t[#t+1] = fmt('push rbx')
				t[#t+1] = fmt('push rcx')
				t[#t+1] = 'call rbx'
				t[#t+1] = 'mov dl, al'
				t[#t+1] = fmt('pop rcx')
				t[#t+1] = fmt('pop rbx')
				t[#t+1] = fmt('pop rax')
				t[#t+1] = fmt('movb [rax+rcx], dl')
				t[#t+1] = fmt('jmp %s_start', label)


				t[#t+1] = fmt('%s_eind:', label)


			elseif f == 'log2' then
				laad('rax', exp[1].v)
				t[#t+1] = 'bsr rax, rax'
				opsla(naam, 'rax')

			elseif op == ':=' and val then
				laad('rax', val)
				opsla(naam, 'rax', naam)

			elseif f == '*' then
				laad('rax', exp[1].v)
				laad('rbx', exp[2].v)
				t[#t+1] = 'mul rbx'
				opsla(naam, 'rax')

			elseif f == '/' then
				laad('rax', exp[1].v)
				laad('rbx', exp[2].v)
				t[#t+1] = 'cdq'
				t[#t+1] = 'idivq rbx'
				opsla(naam, 'rax', naam)

			elseif f == 'mod' then
				laad('rax', exp[1].v)
				laad('rbx', exp[2].v)
				t[#t+1] = 'cdq'
				t[#t+1] = 'idivq rbx'
				opsla(naam, 'rdx', naam)

			elseif f == '+' then
				laad('rax', exp[1].v)
				laad('rbx', exp[2].v)
				t[#t+1] = 'add rax, rbx'
				opsla(naam, 'rax', naam)

			--t[#t+1] = 'cvtsi2sd xmm0, rax' -- m := float(b)

			elseif f == 'wortel' then
				--laad('rax', naam)
				t[#t+1] = fmt('fildd %s[rsp]', opslag[val]) -- load int
				t[#t+1] = 'fsqrt' -- a := int(m)
				t[#t+1] = fmt('fistpd %s[rsp]', opslag[naam]) -- a := int(m)

			elseif op == '^=' then
				laad('rax', naam)
				t[#t+1] = 'bsr rcx, rax' -- b := log2 a
				t[#t+1] = fmt('mov %d[rsp], rcx', opslag[naam]) -- b := log2 a

				t[#t+1] = fmt('fildd %s[rsp]', opslag[naam]) -- load int
				if not opslag[val] then
					t[#t+1] = fmt('movq %d[rsp], %s', opslag[naam], val)
					opslag[val] = opslag[naam]
				end
				t[#t+1] = fmt('fildd %s[rsp]', opslag[val]) -- load int
				if not opslag[val] then
					opsla(naam, 'rax')
				end
				t[#t+1] = 'fyl2x'

				t[#t+1] = fmt('fistpd %s[rsp]', opslag[naam]) -- a := int(m)
				t[#t+1] = fmt('mov rax, %d[rsp]', opslag[naam]) -- b := log2 a
				t[#t+1] = fmt('sal eax, cl', opslag[naam]) -- b := log2 a
				t[#t+1] = fmt('sal eax, cl', opslag[naam]) -- b := log2 a
				t[#t+1] = fmt('mov %d[rsp], rax', opslag[naam]) -- b := log2 a

			elseif op == '-=' then
				laad('rax', naam)
				laad('rbx', val)
				t[#t+1] = 'sub rax, rbx'
				opsla(naam, 'rax', naam)

			elseif op == '||=' then
				laad('rax', naam) -- a.ptr
				laad('rcx', val) -- b.ptr
				t[#t+1] = fmt('mov rbx, -8[rax]') -- a.len
				t[#t+1] = fmt('mov rdx, -8[rcx]') -- b.len
				t[#t+1] = fmt('inc rbx')
				t[#t+1] = fmt('inc rdx')

				-- lengte
				t[#t+1] = fmt('add rbx, rdx') -- b.len
				t[#t+1] = fmt('dec rbx')
				t[#t+1] = fmt('dec rbx')
				t[#t+1] = fmt('mov -8[rax], rbx') -- b.len
				t[#t+1] = fmt('sub rbx, rdx') -- b.len
				t[#t+1] = fmt('dec rcx') -- b.len

				-- zet klaar aan einde
				t[#t+1] = fmt('add rax, rdx')
				t[#t+1] = fmt('add rax, rbx')
				t[#t+1] = fmt('add rcx, rdx')

				-- cat lus
				local label = 'cat'..maakvar()
				t[#t+1] = fmt('%s_start:', label)

				-- rdx-- ; rdx? ga eind
				t[#t+1] = fmt('dec rdx')
				t[#t+1] = fmt('dec rcx')
				t[#t+1] = fmt('dec rax')
				t[#t+1] = fmt('cmp rdx, 0')
				t[#t+1] = fmt('je %s_eind', label)

				t[#t+1] = fmt('mov bl, [rcx]')
				t[#t+1] = fmt('mov [rax], bl')
				t[#t+1] = fmt('jmp %s_start', label)


				t[#t+1] = fmt('%s_eind:', label)

			elseif cmp[f] then
				laad('rax', exp[1].v)
				laad('rbx', exp[2].v)
				t[#t+1] = 'cmp rax, rbx'
				t[#t+1] = 'mov rax, 0'
				t[#t+1] = 'mov rbx, 1'
				t[#t+1] = fmt('cmov%s rax, rbx', cmp[f])
				opsla(naam, 'rax', naam)

			elseif f == '#' then
				laad('rbx', exp[1].v)
				t[#t+1] = 'mov rax, -8[rbx]'
				opsla(naam, 'rax', naam)

			elseif f == '[]' then
				--t[#t+0] = fmt('movq %d[rsp], %d', opslag[naam], #exp)
				-- ptr, len, data...
				local ptr = opslag[naam] + 16
				t[#t+1] = fmt('lea rax, %d[rsp]', ptr) -- rax := ptr
				t[#t+1] = fmt('mov %d[rsp], rax', opslag[naam]) -- array := ptr
				inlinetekst(exp, opslag, ptr, t)
				t[#t+1] = fmt('lea rax, %d[rsp]', opslag[naam])
				--opsla(naam, 'rax')

			elseif f == '||2' then
				local a,b = naam, exp[2].v
				-- rax: i: #a..#b
				local label = 'catlus'..maakvar()
				t[#t+1] = fmt('lea r8, %d[rsp]', opslag[b]+8) -- b.dat
				t[#t+1] = fmt('mov rcx, %d[rsp]', opslag[b]) -- b.len
				t[#t+1] = 'mov r9, r8'
				t[#t+1] = 'dec rcx'
				t[#t+1] = fmt('lea rbx, %d[rsp]', opslag[a]+8) -- a.dat
				t[#t+1] = fmt('mov rax, %d[rsp]', opslag[a]) -- a.len
				t[#t+1] = 'mov rdx, rbx'
				t[#t+1] = 'add r9, rax'
				t[#t+1] = 'add rbx, rax' -- a + a.len
				t[#t+1] = label..':'
				t[#t+1] = fmt('mov rax, [rbx]') -- 
				t[#t+1] = fmt('mov [r12], rax')
				t[#t+1] = 'dec rcx'
				t[#t+1] = 'dec r12'
				t[#t+1] = 'cmp rcx, -1'
				t[#t+1] = 'jne '..label

				-- nieuwe lengte
				t[#t+1] = 'mov [rdx], rbx'
				t[#t+1] = 'mov rax, rdx'
				opsla(naam, 'rax')

			-- index
			-- = a[b]
			elseif opslag[f] then
				-- TODO bounds check
				local a = f
				local b = exp[1].v
				t[#t+1] = fmt('lea rbx, %d[rsp]', opslag[a] + 16)
				laad('rcx', b)
				--t[#t+1] = fmt('lea rcx, %d[rsp]', tonumber(b) or opslag[b])
				t[#t+1] = fmt('add rbx, rcx')
				t[#t+1] = 'movb al, [rbx]'
				opsla(naam, 'rax')

			elseif f == 'syscall' then
				laad('rax', exp[1].v)
				for i=2,#exp do
					laad(sysregs[i-1], exp[i].v)
				end
				t[#t+1] = 'syscall'
				opsla(naam, 'rax')

			elseif f == '@' then
				error('dynamische functies nog niet ondersteund')

			else
				error('onbekende pseudo ass: '..combineer(stat))
			end
		end

		-- dit is de nageboorte
		local epiloog = blok.epiloog
		t[#t+1] = '# '..combineer(epiloog)

		if atoom(epiloog) == 'eind' then
			t[#t+1] = 'ret'

		elseif atoom(epiloog) == 'stop' then
			local naam = blok.stats[#blok.stats][1]

			--[[
			t[#t+1] = "mov rax, 1" -- write
			t[#t+1] = "mov rdi, 1" -- stdout
			t[#t+1] = fmt("movq rsi, %d[rsp]", opslag[naam.v]) -- ptr
			t[#t+1] = fmt("movq rdx, -8[rsi]") -- len = *(ptr - 8)
			t[#t+1] = "syscall"
			]]

			t[#t+1] = '# exit(0)'
			t[#t+1] = "mov rdi, 0\nmov rax, 60\nsyscall\nret\n"


		elseif fn(epiloog) == 'ga' then
			-- simpele sprong
			if #epiloog ~= 3 and fn(epiloog[1]) ~= ',' then
				laad('rax', epiloog[1].v)
				t[#t+1] = 'jmp rax'
			end

			if #epiloog == 3 then
				laad('rax', epiloog[1].v)
				laad('rbx', epiloog[2].v)
				laad('rdx', epiloog[3].v)
				t[#t+1] = 'cmp rax, 0'
				t[#t+1] = 'jnz '..epiloog[2].v
				t[#t+1] = 'jmp rdx'
			end

		elseif fn(epiloog) == 'ret' then
			laad('rax', epiloog[1].v)
			t[#t+1] = 'ret'
		
		else
			error('onbekende epiloog: '..exp2string(epiloog))

		end
	end

	for blok in pairs(cfg.punten) do
		if blok.naam == 'start' then
			blokgen(blok)
		end
	end
	for blok in spairs(cfg.punten) do
		if blok.naam ~= 'start' then
			blokgen(blok)
		end
	end
	t[#t+1] = ''

	return table.concat(t, '\n')
end


if test then
	require 'ontleed'
	require 'bouw.blok'

	local code = [[
start:
	c := 1
	d := 2
	a := 3
	e := (als c dan d anders a)
	ga klaar

klaar:
	stop
]]
	local cfg = leescfg(code)
	local asm = codegen(cfg)
	print(asm)

end

