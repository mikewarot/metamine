

read2magic = {}
write2magic = {}
isserver = {}
write2data = {}
cid2accept = {}

function onaccept(id, cid)
	print("onaccept")
	local server = read2magic[id]
	cid2accept[cid] = server
	server:accept(cid)
	trigger(server)
end

function onread(id, data)
	print('onread')
	local client = read2magic[id]
	client:read(data)
	trigger(client)
end

function onwrite(id, written)
	print('onwrite')
	local client = write2magic[id]
	client:write(written)
	write2magic[id] = nil
	write2data[id] = nil
	trigger(client)
end

function read(id, magic)
	read2magic[id] = magic
	print("READ", sas.read(id))
end

function write(id, magic, data)
	write2magic[id] = magic
	write2data[id] = data
	print("WRITE", sas.write(id))
end

function accept(id, magic)
	read2magic[id] = magic
	isserver[id] = true
	print("ACCEPT", sas.read(id))
end

function onclose(id)
	local server = cid2accept[id]
	if server then
		server:close(id)
	end
	cid2accept[id] = nil
	read2magic[id] = nil
	write2magic[id] = nil
	write2data[id] = nil
	isserver[id] = nil
	do return end
end