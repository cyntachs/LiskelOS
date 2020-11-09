_osname='Liskel OS'_osversion='2.2.1'function require(a)if type(a)~='string'then return nil end;return _ENV[a]or _G[a]end;setmetatable(component,{__index=function(b,c)return component.getPrimary(c)end})fsaddr=component.invoke(component.list("eeprom")(),"getData")local d={}d['filesystem']=component.proxy(fsaddr)function component.setPrimary(e,h)for c,i in component.list()do if c==h and i==e then d[e]=component.proxy(h)end end end;function component.getPrimary(e)if d[e]==null then for c,i in component.list()do if i==e then component.setPrimary(i,c)break end end end;return d[e]end;g={bind=function()local j=component.list('screen')()return component.gpu.bind(j)end,available=function()local k,j=component.list('gpu')(),component.list('screen')()return k and j end,copy=component.gpu.copy,getResolution=component.gpu.getResolution,setResolution=component.gpu.setResolution,getDepth=component.gpu.maxDepth,setBG=component.gpu.setBackground,setFG=component.gpu.setForeground,fill=function(l,m,n,o)return component.gpu.fill(l,m,n,o,' ')end,fillc=component.gpu.fill,drawText=component.gpu.set}local n,o=g.getResolution()local p,q=n/2,o/2;f={addr=fsaddr,setBootAddress=function(h)f.addr=h end,open=component.filesystem.open,read=function(r)return component.filesystem.read(r,math.huge)end,write=component.filesystem.write,close=component.filesystem.close,list=function(s)return component.filesystem.list(s or'/')end,mkdir=component.filesystem.makeDirectory,rename=component.filesystem.rename,remove=component.filesystem.remove,readfile=function(t)local u,v=f.open(t,'r')if not u then error(v)end;local w=''repeat local x,y=f.read(u)if not x and y then error(y)end;w=w..(x or'')until not x;f.close(u)return w end,loadfile=function(t)return load(f.readfile(t),'='..t)end,runfile=function(t,z,A)local B,v=f.loadfile(t..".lua")if B then local C=table.pack(xpcall(B,function(...)return debug.traceback()end,z,A))if C[1]then return table.unpack(C,2,C.n)else error(C[2])end else error(v)end end}f.load=f.loadfile;f.run=f.runfile;std_error=error;function error(D)g.setFG(0xFFFFFF)g.setBG(0x000000)g.fill(1,1,n,o)local E=1;local F=1;for n in string.gmatch(D,'()\n')do g.drawText(1,E,D:sub(F,n-1))F=n+1;E=E+1 end;g.drawText(1,E,D:sub(F))local u,G=f.open('error_log.txt','w')if u then f.write(u,D..'\n')end;f.close(u)repeat local H,h,I,J=computer.pullSignal()until H=='key_down'and J==28;computer.shutdown(true)end;console={}function console.Serialize(K,L)local function M(K,L,N)N=N or 1;L=L or 3;L=L-1;local O=0;local P=''while O<N do P=P..'  'O=O+1 end;local Q=''if type(K)=="number"then Q=Q..K..''elseif type(K)=="boolean"then Q=Q..tostring(K)elseif type(K)=="string"then Q=Q..string.format("%q",K)..''elseif type(K)=="table"then if L<=0 then return'<'..type(K)..'>'end;Q=Q..'{\n'for c,i in pairs(K)do Q=Q..P..''..c..'='Q=Q..M(i,L,N+1)Q=Q..',\n'end;Q=Q..P:sub(1,P:len()-2)..'}'else Q=Q..'<'..type(K)..'>'end;return Q end;return M(K,L)end;function console.ArrayToStr(R)local S=''for T=1,#R do S=S..R[T]end;return S end;function console.StrToArray(U)local S={}for T=1,#U do table.insert(S,U:sub(T,T))end;return S end;function console.lineout(U,E)g.fill(1,E,n,1)g.drawText(1,E,U)end;function console.lineoutoff(U,E,V)V=V or 1;g.fill(V,E,n,1)g.drawText(V,E,U)end;console.history={mem={},cmdmem={},size=o*10,viewheight=o-1,viewbottom=1,prevbottom=1,recallptr=1,printoffset=1,lnum=1,scrspeed=5,scrdir=0}function console.history.PrintAll()if next(console.history.mem)==nil then return end;for T=1,console.history.viewheight-1 do local W=console.history.viewbottom-(T-1)if W<=0 then return end;local X=console.history.mem[W]local Y=console.history.viewheight-(T-1)console.lineoutoff(X,Y,console.history.printoffset)end end;function console.history.Update()if next(console.history.mem)==nil then return end;if console.history.scrdir==0 then console.history.PrintAll()elseif console.history.scrdir>0 then g.copy(1,2,n,o-console.history.scrspeed-2,0,console.history.scrspeed)for T=1,console.history.scrspeed do local W=console.history.viewbottom-console.history.viewheight+1+console.history.scrspeed-(T-1)if W<=0 then return end;local X=console.history.mem[W]local Y=1+console.history.scrspeed-(T-1)console.lineoutoff(X,Y,console.history.printoffset)end elseif console.history.scrdir<0 then g.copy(1,2+console.history.scrspeed,n,o-console.history.scrspeed-2,0,-console.history.scrspeed)for T=1,console.history.scrspeed do local W=console.history.viewbottom-(T-1)if W<=0 then return end;local X=console.history.mem[W]local Y=console.history.viewheight-(T-1)console.lineoutoff(X,Y,console.history.printoffset)end end;console.history.scrdir=0 end;function console.history.ScrollEnd()console.history.prevbottom=console.history.viewbottom;console.history.viewbottom=#console.history.mem;console.history.PrintAll()end;function console.history.ScrollTop()console.history.prevbottom=console.history.viewbottom;console.history.viewbottom=o-2;console.history.PrintAll()end;function console.history.ScrollUp(Z)Z=Z or 1;if#console.history.mem<console.history.viewheight then return end;console.history.prevbottom=console.history.viewbottom;console.history.viewbottom=console.history.viewbottom-Z;console.history.scrdir=1;if console.history.viewbottom<=console.history.viewheight-1 then console.history.scrdir=0;console.history.viewbottom=console.history.viewheight-1 end;console.history.Update()end;function console.history.ScrollDown(Z)Z=Z or 1;console.history.prevbottom=console.history.viewbottom;console.history.viewbottom=console.history.viewbottom+Z;console.history.scrdir=-1;if console.history.viewbottom>=#console.history.mem then console.history.scrdir=0;console.history.viewbottom=#console.history.mem end;console.history.Update()end;function console.history.MoveRecall(_)if next(console.history.cmdmem)==nil then return end;_=_ or 0;console.history.recallptr=console.history.recallptr+_;if console.history.recallptr>=#console.history.cmdmem then console.history.recallptr=#console.history.cmdmem elseif console.history.recallptr<=1 then console.history.recallptr=1 end end;function console.history.ResetRecall()console.history.recallptr=#console.history.cmdmem end;function console.history.Recall()if next(console.history.cmdmem)==nil then return""end;return console.history.cmdmem[console.history.recallptr]end;function console.history.Add(U)U=" "..tostring(console.history.lnum).."  | "..U;table.insert(console.history.mem,U)console.history.viewbottom=#console.history.mem;console.history.recallptr=#console.history.cmdmem+1;console.history.Update()console.history.lnum=console.history.lnum+1 end;function console.history.AddInp(U)table.insert(console.history.cmdmem,U)console.history.Add(U)end;console.input={buffer={},col=1,printoffset=1}function console.input.Print()local a0=console.ArrayToStr(console.input.buffer)console.lineoutoff(a0,o,console.input.printoffset)end;function console.input.SetPrintOffset(V)console.input.printoffset=V end;function console.input.Append(U)table.insert(console.input.buffer,U)console.input.Print()end;function console.input.Insert(U,_)_=_ or console.input.col;table.insert(console.input.buffer,_,U)console.input.Print()end;function console.input.SetPos(_)_=_ or#console.input.buffer;if _<1 then _=1 end;if _>#console.input.buffer then _=#console.input.buffer+1 end;console.input.col=_ end;function console.input.MovePos(a1)local _=console.input.col+a1;console.input.SetPos(_)end;function console.input.GetCharAtPos()return console.input.buffer[console.input.col]end;function console.input.GetString()return console.ArrayToStr(console.input.buffer)end;function console.input.DelChar()table.remove(console.input.buffer,console.input.col)console.input.Print()end;function console.input.Clear()console.input.buffer={}console.input.col=1;console.input.Print()end;function console.input.SetBuffer(U)console.input.buffer=console.StrToArray(U)console.input.col=#console.input.buffer+1;console.input.Print()end;function console.print(U)if type(U)=='table'then U=console.Serialize(U)else U=tostring(U)end;local F=1;for n in string.gmatch(U,'()\n')do console.history.Add(U:sub(F,n-1))F=n+1 end;console.history.Add(U:sub(F))end;function console.Run()g.fill(1,2,n,o)g.setFG(0x000000)g.setBG(0xFFFFFF)g.fill(1,1,n,1)g.drawText(1,1,"  ".._osname.." ".._osversion)g.setFG(0xFFFFFF)g.setBG(0x000000)local a2="#> "local a3=true;local a4=console.history;local a5=console.input;print=console.print;console.lineout(a2,o)a5.SetPrintOffset(#a2+1)print("* F12 to restart  *")print("* F10 to shutdown *")while true do local a6=table.pack(computer.pullSignal(0.4))if a6[1]=='key_down'then if a6[4]==88 then computer.shutdown(true)end;if a6[4]==68 then computer.shutdown()end;if a6[4]==28 then a4.AddInp(a5.GetString())console.lineout(a2,o)local a7=a5.GetString()local a8,a9=load(a7,'=cinput')if a8 then local C,v=xpcall(a8,function(D)return D..'\n'..debug.traceback()end)if not C and v then print(v)end elseif not a8 and a9 then print(a9)else print('Unknown Command')end;a5.Clear()elseif a6[4]==14 then if a5.col>1 then a5.MovePos(-1)a5.DelChar()a4.ResetRecall()end elseif a6[4]==200 then a4.MoveRecall(-1)a5.SetBuffer(a4.Recall())elseif a6[4]==208 then a4.MoveRecall(1)a5.SetBuffer(a4.Recall())elseif a6[4]==203 then a5.MovePos(-1)elseif a6[4]==205 then a5.MovePos(1)elseif a6[4]==199 then a5.MovePos(-99999)elseif a6[4]==207 then a5.MovePos(99999)elseif a6[3]~=0 then local I=string.char(a6[3])a5.Insert(I)a5.MovePos(1)end elseif a6[1]=='scroll'then if a6[5]>0 then a4.ScrollUp(a4.scrspeed)elseif a6[5]<0 then a4.ScrollDown(a4.scrspeed)end end;if a3 then local aa=console.input.col+console.input.printoffset-1;g.setBG(0xFFFFFF)g.fill(aa,o,1,1)g.setBG(0x000000)a3=false else a5.Print()a3=true end end end;local function ab()console.Run()end;if component.filesystem.exists('autorun.lua')then f.runfile('autorun')end;local C,v=xpcall(ab,function(D)return D..'\n'..debug.traceback()end)if not C and v then error(v)end;computer.shutdown()