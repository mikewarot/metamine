require 'util'

local remove = table.remove

local function link(graaf,a,b)
	if not graaf.punten[a] or not graaf.punten[b] then
		if not graaf.punten[a] then
			error('zit niet in de graaf: '..unlisp(a))
		end
		if not graaf.punten[b] then
			error('zit niet in de graaf: '..unlisp(b))
		end
	end

	graaf.van[a][b] = true
	graaf.naar[b][a] = true
end

local function ontlink(graaf,a,b)
	graaf.van[a][b] = nil
	graaf.naar[b][a] =  nil
end

local function voegtoe(graaf, ...)
	for i,v in ipairs({...}) do
		graaf.punten[v] = true
		graaf.van[v] = {}
		graaf.naar[v] = {}
	end
end

local function bevat(graaf,a,b)
	return graaf.van[a] and graaf.van[a][b]
end

local function tekst(graaf)
	local t = {}
	for bron in spairs(graaf.van) do
		t[#t+1] = bron
		if not next(graaf.van[bron]) then
			t[#t+1] = '.'
		else
			t[#t+1] = ' -> '

			for doel in spairs(graaf.van[bron]) do
				t[#t+1] = doel
				t[#t+1] = ' '
			end

		end
		t[#t+1] = '\n'
	end
	return table.concat(t)
end

local function cyclisch(graaf)
	local indices = {}
	local index = 0
	local nieuw = {}
  local grootte = 0
	
	for punt in spairs(graaf.punten) do
    grootte = grootte + 1
		if not next(graaf.naar[punt]) then
			nieuw[#nieuw+1] = punt
			indices[punt] = index
			index = index + 1
		end
	end

	-- geen begin
	if index == 0 then
		return true
	end

	while #nieuw > 0 do
		local bron = remove(nieuw, 1)
		for doel in pairs(graaf.van[bron]) do
			if indices[doel] and indices[doel] < indices[bron] then
        return true
			elseif not indices[doel] then
        -- alle vertices klaar?
        local zeker = true
        for bron in pairs(graaf.naar[doel]) do
          if not indices[bron] then
            zeker = false
          end
        end
        if zeker then
          indices[doel] = index
          index = index + 1
          nieuw[#nieuw+1] = doel
        end
			end
		end
	end

  if index ~= grootte then
    return true
  end
	return false
end

function graaf()
	local punten = {}
	local randen = {}
	return {
		punten, randen;
		punten = punten,
		randen = randen,
		van = {}, naar = {};
		link = link,
		ontlink = ontlink,
		cyclisch = cyclisch,
		bevat = bevat,
		voegtoe = voegtoe,
		tekst = tekst,
	}
end

-- test
do
	local a = graaf()
	a:voegtoe('a')
	a:voegtoe('b')
	a:link('a', 'b')
	assert(not a:cyclisch())
	a:link('b', 'a')
	assert(a:cyclisch())

	local b = graaf()
	b:voegtoe('a')
	b:voegtoe('b')
	b:voegtoe('c')
	b:link('a','b')
	b:link('b','c')
	assert(not b:cyclisch())
	b:link('c','b')
	assert(b:cyclisch())

	-- bug 10/6
	local c = graaf()
	c:voegtoe('a')
	c:voegtoe('t')
	c:voegtoe('uit')
	c:voegtoe('getal')
	c:link('a', 'uit')
	c:link('t', 'uit')
	assert(not c:cyclisch(), c:tekst())

	local d = graaf()
	d:voegtoe('a')
	d:voegtoe('b')
	d:voegtoe('uit')
	d:voegtoe('toets-links')
	d:link('a', 'uit')
	d:link('b', 'uit')
	d:link('toets-links', 'b')
	assert(not d:cyclisch(), d:tekst())

	local a = graaf()
	a:voegtoe('f', 'a', 'x', 'tekst', 'uit')
	a:link('f', 'x')
	a:link('f', 'a')
	a:link('x', 'a')
	a:link('a', 'uit')
	a:link('tekst', 'uit')

	assert(not a:cyclisch())
end