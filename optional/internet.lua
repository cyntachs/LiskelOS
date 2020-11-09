local a=require("buffer")local b=require("component")local c=require("event")local d={}function d.request(e,f,g,h)checkArg(1,e,"string")checkArg(2,f,"string","table","nil")checkArg(3,g,"table","nil")checkArg(4,h,"string","nil")local i=b.internet;local j;if type(f)=="string"then j=f elseif type(f)=="table"then for k,l in pairs(f)do j=j and j.."&"or""j=j..tostring(k).."="..tostring(l)end end;local m,n=i.request(e,j,g,h)if not m then error(n,2)end;return setmetatable({["()"]="function():string -- Tries to read data from the socket stream and return the read byte array.",close=setmetatable({},{__call=m.close,__tostring=function()return"function() -- closes the connection"end})},{__call=function()while true do local f,n=m.read()if not f then m.close()if n then error(n,2)else return nil end elseif#f>0 then return f end end end,__index=m})end;local o={}function o:close()if self.socket then self.socket.close()self.socket=nil end end;function o:seek()return nil,"bad file descriptor"end;function o:read(p)if not self.socket then return nil,"connection is closed"end;return self.socket.read(p)end;function o:write(q)if not self.socket then return nil,"connection is closed"end;while#q>0 do local r,n=self.socket.write(q)if not r then return nil,n end;q=string.sub(q,r+1)end;return true end;function d.socket(s,t)checkArg(1,s,"string")checkArg(2,t,"number","nil")if t then s=s..":"..t end;local i=b.internet;local u,n=i.connect(s)if not u then return nil,n end;local v={inet=i,socket=u}local w={__index=o,__metatable="socketstream"}return setmetatable(v,w)end;function d.open(s,t)local v,n=d.socket(s,t)if not v then return nil,n end;return a.new("rwb",v)end;return d