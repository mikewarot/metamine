-- registers voor argumenten van syscalls
local sysregs = { 'rdi', 'rsi', 'rdx', 'r10', 'r8', 'r9' }
-- registers voor argumenten van abicalls
local abiregs = { 'rdi', 'rsi', 'rdx', 'rcx', 'r8', 'r9'} -- r10 is static chain pointer in case of nested functions
-- registers op volgorde van bruikbaarheid (~6 general purpose registers)
--local registers = { 'r12', 'r13', 'r14', 'r15', 'r10', 'r9', 'r8', 'rcx', 'rdx', 'rsi', 'rdi', 'rax' }
local registers = { 'rax', 'rbx', 'rcx', 'rdx', 'r10', 'r9', 'r8', 'rcx', 'rdx', 'rsi', 'rdi', 'rax' }

local cmp = {
	['>'] = 'g',
	['>='] = 'ge',
	['='] = 'e',
	['!='] = 'ne',
	['<='] = 'le',
	['<'] = 'l',
}

local op2asm = {
	['+'] = [[  mov rax, 8[rsp]	# (+)
  mov rbx, [rsp]
  add rax, rbx
  mov 8[rsp], rax
  add rsp, 8]],

	['-'] = [[  mov rax, [rsp]	# (-)
	neg rax
	mov [rsp], rax]],

	['·'] = [[  mov rax, 8[rsp]	# (·)
  mov rbx, [rsp]
  imul rax, rbx
  mov 8[rsp], rax
  add rsp, 8]],

	['/'] = [[  mov rax, 8[rsp]	# (/)
  mov rbx, [rsp]
  idiv rax, rbx
  mov -8[rsp], rax
  add rsp, 8]],

	-- [... fn arg] -> [... arg] -> [... res]
	-- rax: fn, rbx: arg
	['_f'] = [[  mov rax, 8[rsp]	# (_f)
  mov rbx, [rsp]
  mov 8[rsp], rbx
  add rsp, 8
	call rax]],
}

function asmgen(im)
	focus = 1
	local arg2focus = {} -- int → int
	local L = {}
	local lstack = {}

	local function asmnaam(focus)
		if focus <= 6 then
			return registers[focus]
		else
			return 'de stack ofzo?'
		end
	end

	local function ins2asm(ins)
		if fn(ins) == 'fn' then
			local label = 'fn'..atoom(arg(ins))
			lstack[#lstack+1] = label
			L[#L+1] = '  jmp '..label..'_eind'
			local res = label..': \t#'..combineer(ins)

			L[#L+1] = res

		elseif tonumber(atoom(ins)) then
			L[#L+1] = '  sub rsp, 8 \t#'..combineer(ins)
			L[#L+1] = '  mov rax, '..atoom(ins)
			L[#L+1] = '  mov [rsp], rax'

		elseif op2asm[atoom(ins)] then
			L[#L+1] = op2asm[atoom(ins)]

		elseif atoom(ins) == 'eind' then
			L[#L+1] = '  mov rax, [rsp]'
			L[#L+1] = '  ret'
			local label = lstack[#lstack]
			lstack[#lstack] = nil
			L[#L+1] = label..'_eind:'

		else
			L[#L+1] = '  nop\t# '..combineer(ins)
		end
	end

	--assert(fn(im[1]) == 'fn', 'main moet een functie zijn')

	L[#L+1] = [[
  .intel_syntax noprefix
  .text
  .global	start

.section .text

start: ]]


	for i = 1, #im do
		local ins = im[i]
		ins2asm(ins)
	end

	L[#L+1] = [[

  # Exit
  mov rax, 60
  mov rdi, [rsp]
  syscall
  ret

.section .rodata

.groet:
  .string "hoi.txt"
]]

	return table.concat(L,"\n")
end
