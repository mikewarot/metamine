function server_client(clients, cid)
	print('server accepted '.. cid)
	local c = magic()
	c.group = {'client'}
	c.id = cid
	
	-- input
	local input = magic()
	input.group = {'text'}
	input.val = ''
	c.input = input
	
	read(cid, input)

	function input:read(data)
		self.val = self.val .. data
		print('server reads '..#data)
	end

	-- output
	local output = magic()
	output.group = {'text'}
	output.val = ''
	local last = 1
	local pending = false
	
	function output:update()
		local data = self.val
		
		if #data >= last and not pending then
			pending = true
			local todo = data:sub(last)
			write(cid, output, todo)
			print('server writes '..#todo)
		end
	end
	
	function output:write(len)
		pending = false
		last = last + len
	end
	
	getmetatable(c).__newindex = function (t,k,v)
		if k == 'output' then
			output.val = v
			trigger(output)
			--output.ref = v
			--triggers(v, output)
		else
			rawset(t,k,v)
		end
	end
	getmetatable(c).__index = function (t,k)
		if k == 'output' then
			return output
		else
			return rawget(t,k)
		end
	end
	
	return c
end

local servers = {}

function server(port)
	if servers[port] then
		return servers[port]
	end
	
	local id = sas.server(port)
	if not id then
		error("bind failed")
	end
	
	local server = magic()
	server.group = {'server'}
	server.val = {
		id = id,
		port = port,
	}
	
	-- clients!
	local clients = magic()
	local input = magic()
	local output = magic()
	server.clients = clients
	clients.group = {'set', 'client'}
	clients.val = {}
	clients.name = 'clients'
	clients.input = input
	clients.ids = {}
	accept(id,clients)
	
	-- client input
	input.group = {'client', 'text'}
	input.name = 'input'
	
	function input:update()
		self.val = {}
		for client in pairs(clients.val) do
			self.val[client] = client.input.val -- store pure
		end
	end
	
	-- client output
	output.ref = magic()
	output.ref.val = {}
	
	function output:update()
		for client in pairs(clients.val) do
			--print(output.ref.val)
			--see(output.ref.val)
			
			if output.ref.val and output.ref.val[client] then
				client.output = output.ref.val[client]
			end
		end
	end
	
	getmetatable(clients).__newindex = function(t,k,v)
		if k == 'output' then
			t.output2 = output --/
			output.ref = v
			triggers(output.ref, output)
		else
			rawset(t,k,v)
		end
	end
	
	function clients:accept(cid)
		local client = server_client(self, cid)
		
		self.val[client] = client
		self.ids[cid] = client
		
		triggers(client.input, input)
		triggers(output, client.output)
	end

	function clients:close(cid)
		local client = self.ids[cid]
		untriggers(client.input, input)
		untriggers(output, client.output)
		self.val[client] = nil
		self.ids[cid] = nil
	end
	
	servers[port] = server
	return server
end

function client(address)
	local ip,port = address:match('(.*):(.*)')
	local cli = magic()
	cli.group = {'client'}
	local id = sas.client(ip, port)
	cli.text = address
	cli.val = {id=id}
	
	-- input
	local input = magic()
	input.group = {'text'}
	input.val = ''
	cli.input = input
	
	read(id, input)
	
	function input:read(data)
		print('client reads ' .. data)
		self.val = self.val .. data
	end
	
	-- output
	local output = magic()
	local offset = 1
	local pending = false
	output.group = {'text'}
	output.ref = magic()
	output.ref.val = ''
	
	function output:write(num)
		offset = offset + num
		pending = false
	end
	
	function output:update()
		self.val = self.ref.val
		local data = self.val
		
		-- send output
		if #data >= offset and not pending then
			local sub = data:sub(offset)
			print('client writes '..#sub)
			write(id, self, sub)
			pending = true
		end
	end
	
	-- metamagic
	getmetatable(cli).__newindex = function(t,k,v)
		if k == 'output' then
			output.ref = v
			triggers(output.ref, output)
		else
			rawset(t,k,v)
		end
	end
	
	getmetatable(cli).__index = function(t,k)
		if k == 'output' then
			return output
		else
			return rawget(t,k)
		end
	end
	
	return cli
end