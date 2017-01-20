function server_client(clients, cid, addr)
	local c = magic()
	c.text = '%'..cid
	c.group = {'client'}
	c.val = {
		id = cid,
		addr = addr,
	}
	c.input = ''
	
	-- events
	read(cid, c)
	function c:read(data)
		self.input = self.input .. data
	end
	
	-- input
	--[[local input = magic(c.name .. '.input')
	c.input = input
	input.val = ''
	input.text = '<empty>'
	function input:update()
		self.text = encode(self.val)
	end
	
	triggers(input, c)
	]]

	local output
	local last = 1

	function c:update()
		if output and output.val then
			local data = output.val
			if #data >= last then
				local todo = data:sub(self.last)
				write(c.val.id, c, todo)
			end
		end
	end
	
	function c:write(len)
		last = last + len
		
		-- are we done sending?
		if last > #output.val then
			write2data[c.val.id] = nil
			write2magic[c.val.id] = nil
		end
	end
	
	getmetatable(c).__newindex = function (t,key,any)
		if key == 'output' then
			output = any
			triggers(output, c)
		else
			rawset(t,key,any)
		end
	end
	
	function c:close()
		close(cid, self)
		self.text = '<closing>'
		clients:close(self)
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
	server.text = 'p'..port
	server.group = {'server'}
	server.val = {
		id = id,
		port = port,
	}
	
	-- clients!
	local clients = magic()
	local output
	server.clients = clients
	clients.group = {'set', 'client'}
	clients.val = {}
	clients.name = 'clients'
	clients.text = '()'
	accept(id,clients)
	
	function clients:update()
		local tt = { '(' }
		for client in pairs(self.val) do
			table.insert(tt, client.text)
			if next(self.val, client) then
				table.insert(tt, ' ')
			end
		end
		table.insert(tt, ')')
		
		self.text = table.concat(tt)

		-- output
		for client in pairs(self.val) do
			if output then
				client.output = output[client]
			end
		end
	end
	
	-- client input
	local input = magic()
	input.group = {'client', 'text'}
	input.name = 'input'
	input.text = '{}'
	triggers(clients, input)
	
	function input:update()
		self.val = {}
		local tt = {'{'}
		for client in pairs(clients.val) do
			self.val[client] = client.input
			table.insert(tt, client.name)
			table.insert(tt, ' -> ')
			table.insert(tt, (encode(client.input)))
			
			if next(clients.val, client) then
				table.insert(tt, '  ')
			end
		end
		table.insert(tt, '}')
		self.text = table.concat(tt)
	end
	clients.input = input
	
	function clients:close(client)
		self.val[client] = nil
	end

	-- client output
	getmetatable(clients).__newindex = function(t,k,v)
		if k == 'output' then
			output = v	
		else
			rawset(t,k,v)
		end
	end
	
	function clients:accept(cid, addr)
		local client = server_client(self, cid, addr)
		
		self.val[client] = true
		triggers(client, self)
	end
	servers[port] = server
	return server
end

function client(address)
	local ip,port = address:match('(.*):(.*)')
	local cli = magic()
	cli.group = {'client'}
	cli.val = sas.client(ip, port)
	cli.text = address
	
	local output = ''
	local offset = 1
	
	function cli:update()
		-- send output
		if #output >= offset then
			local data = output:sub(offset)
			write(self.val, self, data)
		end
	end
	
	function cli:write(num)
		offset = offset + num
		
		-- are we done sending?
		if offset > #output then
			write2data[cli.val] = nil
			write2magic[cli.val] = nil
		end
	end
	
	-- metamagic
	getmetatable(cli).__newindex = function(t,k,v)
		if k == 'output' then
			output = v
			trigger(cli)
		end
	end
	
	return cli
end
