local tau = math.pi * 2
local ja = true
local nee = false
local pack = pack or table.pack
local unpack = unpack or table.unpack
local _pow = function(a,b)
    if type(a) == 'number' then
        return a ^ b
    else
        return function(c)
            for i=1,b do
                c = a(c)
            end
            return c
        end
    end
end
local lijst = 'lijst'
local getal = function(a)
    return tonumber(string.char(table.unpack(a)))
end
local int = function(a)
    local getal
    if type(a) == 'number' then
        getal = a
    else
        getal = tonumber(string.char(table.unpack(a)))
    end
    if not getal then return false end
    return math.floor(getal)
end;
local _iinterval = function(a,b)
    local t = {}
    for i = 1,b-1 do
        t[#t+1] = i
    end
    return t
end;
local waarvoor = function(l,fn)
    local r = {}
    for i,v in ipairs(l) do
        if fn(v) then
            r[#r+1] = v
        end
    end
    return r
end

local som = function(t)
    local som = 0
    for i,v in ipairs(t) do
        som = som + v
    end
    return som
end;
local _istype = function(a,b)
    if b == getal then return type(a) == 'number' end
    if b == int then return type(a) == 'number' and a%1 == 0 end
    if b == lijst then return type(a) == 'table' end
    -- set dan maar
    return not not b[a]
    --return false
end
local _procent = function(n) return n / 100 end
local _comp = function(a,b)
    return function(...)
        return b(a(...))
    end
end
local javascript = function(broncode)
    -- ^_^
    require 'bieb'
    return bieb.javascript(broncode)
end
local tabel = function(t)
    local t = t or {is={lijst=true}}
    local mt = {}
    function mt:__call(i)
        return t[i+1]
    end
    setmetatable(t, mt)
    return t
end
local vanaf = function(a,van)
    local t = tabel{}
    for i=van+1,#a do
        t[#t+1] = a[i]
    end
    return t
end

local tot = function(a,tot)
    local t = tabel{}
    for i=1,tot do
        t[#t+1] = a[i]
    end
    return t
end

local deel = function(a,b)
    local van,tot = b[1],b[2]
    local t = tabel{}
    for i=van+1,tot do
        t[#t+1] = a[i]
    end
    return t
end

local _kies = function(a,b)
    local fa = type(a) == 'function'
    local fb = type(b) == 'function'
    if a and b then return 'fout' end
    return a or b
end

local cat = function(a,b)
    local r = tabel{}
    for i,v in ipairs(a) do
        for i,v in ipairs(v) do
            r[#r+1] = v
        end
        if b and i ~= #a then
            for i,b in ipairs(b) do
                r[#r+1] = b
            end
        end
    end
    return r
end

local vind = function(a,b)
    for i=1,#a-#b+1 do
        local gevonden = true
        for j=i,i+#b-1 do
            if a[j] ~= b[j-i+1] then
                gevonden = false
                break
            end
        end
        if gevonden then
            return i-1
        end
    end
    return false
end

local function tekstR(a,t)
    if type(a) == 'table' then
        if a.is and a.is.tupel then t[#t+1] = '('
        elseif a.is and a.is.lijst then t[#t+1] = '['
        elseif a.is and a.is.set then t[#t+1] = '{'
        end

        if a.is and a.is.set then
            for k in pairs(a.set) do
                tekstR(k,t)
                if next(a.set,k) then
                    t[#t+1] = ','
                end
            end
        else
            for i,v in ipairs(a) do
                tekstR(v,t)
                if i < #a then
                    t[#t+1] = ','
                end
            end
        end

        if a.is and a.is.tupel then t[#t+1] = ')'
        elseif a.is and a.is.lijst then t[#t+1] = ']'
        elseif a.is and a.is.set then t[#t+1] = '}'
        end
    else
        t[#t+1] = tostring(a)
    end
            
end

local function tekst(a)
    local t = {}
    tekstR(a, t)
    local t = table.concat(t)
    return {string.byte(t,1,#t)}
end

local xx = function(a,b)
    if type(a) == 'table' and a.is and a.is.set then
        if type(b) == 'table' and b.is and b.is.set then
            local res = {is={set=true},set={}}
            for sa in pairs(a.set) do
                for sb in pairs(b.set) do
                    res.set[{is={tupel=true}, sa, sb}] = true
                end
            end
            return res
        end
    end
            
    if type(a) == 'table' and a.is and a.is.tupel then
        if type(b) == 'table' and b.is and b.is.tupel then
            for i=1,#b do
                a[#a+1] = b[i]
            end
        else
            a[#a+1] = b
        end
    else
        if type(b) == 'table' and b.is and b.is.tuple then
            table.insert(b, 1, a)
            a = b
        else
            a = {is={tupel=true}, a, b}
        end
    end
    return a
end

local herhaal = function(f)
    return function(a)
        local r = a
        while a do
            r = a
            a = f(a)
        end
        return r
    end
end

local function _len(t)
    if type(t) == 'table' and t.is and t.is.set then
        local len = 0
        for _ in pairs(t.set) do len = len + 1 end
        return len
    end
    if type(t) == 'table' and t.is and (t.is.tupel or t.is.lijst) then
        return #t
    end
end
local B = tabel{2,3}
local C = function (_B)
    local D = _A + _B
    return D
end
local A = C(B)
return A