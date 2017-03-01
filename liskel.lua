--[[
===========
 Liskel OS
===========

Description:
A barebones operating system that is
designed to give the programs full
control over the system. Boots up to
a lua interpreter if autorun.lua
does not exist.
]]
_osname = 'Liskel OS'
_osversion = '1.8'
--+-+-+-+-+ Require +-+-+-+-+--
function require(pkg)
  if type(pkg) ~= 'string' then return nil end
  return _ENV[pkg] or _G[pkg]
end
--+-+-+-+-+ Component +-+-+-+-+--
setmetatable(component,{__index = function(_,k) return component.getPrimary(k) end})
function component.getPrimary(dev)
  if dev == 'filesystem' then
    return component.proxy(computer.getBootAddress())
  end
  for k,v in component.list() do
    if v == dev then
      return component.proxy(k)
    end
  end
end
--+-+-+-+-+ Graphics +-+-+-+-+--
g = {}
function g.bind()
  local screen = component.list('screen')()
  return component.gpu.bind(screen)
end
function g.available()
  local gpu,screen = component.list('gpu')(),component.list('screen')()
  return (gpu and screen)
end
function g.copy(x,y,w,h,a,b)
  component.gpu.copy(x,y,w,h,a,b)
end
function g.getResolution()
  return component.gpu.getResolution()
end
function g.setResolution(w,h)
  return component.gpu.setResolution(w,h)
end
function g.getDepth()
  return component.gpu.maxDepth()
end
function g.setBG(color)
  return component.gpu.setBackground(color)
end
function g.setFG(color)
  return component.gpu.setForeground(color)
end
function g.fill(x,y,w,h)
  return component.gpu.fill(x,y,w,h,' ')
end
function g.fillc(x,y,w,h,ch)
  return component.gpu.fill(x,y,w,h,ch)
end
function g.drawText(x,y,str)
  return component.gpu.set(x,y,str)
end
local w,h = g.getResolution()
local cx,cy = (w/2),(h/2)
--+-+-+-+-+ Filesystem +-+-+-+-+--
f = {}
f.addr = computer.getBootAddress()
function f.setBootAddress(addr)
  f.addr = addr
end
function f.open(file,mode)
  return component.filesystem.open(file,mode)
end
function f.read(handle)
  return component.filesystem.read(handle,math.huge)
end
function f.write(handle,str)
  return component.filesystem.write(handle,str)
end
function f.close(handle)
  return component.filesystem.close(handle)
end
function f.list(dir)
  return component.filesystem.list(dir or '/')
end
function f.mkdir(dir)
  return component.filesystem.makeDirectory(dir)
end
function f.rename(name1,name2)
  return component.filesystem.rename(name1,name2)
end
function f.remove(dir)
  return component.filesystem.remove(dir)
end
function f.loadfile(file)
  local hdl,err = f.open(file,'r')
  if not hdl then error(err) end
  local buffer = ''
  repeat
    local data, err_read = f.read(hdl)
    if not data and err_read then error(err_read) end
    buffer = buffer .. (data or '')
  until not data
  f.close(hdl)
  return load(buffer,'='..file)
end
function f.runfile(file,argc,args)
  local prog,err = f.loadfile(file)
  if prog then
    local res = table.pack(xpcall(prog,function(...) return debug.traceback() end,argc,args))
    if res[1] then
      return table.unpack(res,2,res.n)
    else
      error(res[2])
    end
  else
    error(err)
  end
end
f.load = f.loadfile
f.run = f.runfile
--+-+-+-+-+ Error +-+-+-+-+--
std_error = error
function error(msg)
  g.setFG(0xFFFFFF)
  g.setBG(0x000000)
  g.fill(1,1,w,h)
  -- write to screen
  local line = 1
  local prev = 1
  for w in string.gmatch(msg,'()\n') do
    g.drawText(1,line,msg:sub(prev,w-1))
    prev = w+1
    line = line+1
  end
  g.drawText(1,line,msg:sub(prev))
  -- write to log
  local hdl,errf = f.open('error_log.txt','w')
  if hdl then
    f.write(hdl,msg..'\n')
  end
  f.close(hdl)
  repeat
    local e,addr,char,code = computer.pullSignal()
  until e == 'key_down' and code == 28
  computer.shutdown(true)
end
--+-+-+-+-+ Shell +-+-+-+-+--
g.fill(1,1,w,h)
--- helper functions
function tabletostr(tabl)
  local retval = ''
  for i=1, #tabl do
    retval = retval .. tabl[i]
  end
  return retval
end
function strtotable(str)
  local retval = {}
  for i = 1, #str do
    table.insert(retval,str:sub(i,i))
  end
  return retval
end
function serialize (o, ind)
  ind = ind or 1
  local indn = 0
  local indent = ''
  while indn < ind do
    indent = indent .. '  '
    indn =  indn + 1
  end
  local retstr = ''
    if type(o) == "number" then
      retstr = retstr .. o .. ''
    elseif type(o) == "boolean" then
      retstr = retstr .. tostring(o)
    elseif type(o) == "string" then
      retstr = retstr .. string.format("%q", o) .. ''
    elseif type(o) == "table" then
      retstr = retstr .. '{\n'
      for k,v in pairs(o) do
        retstr = retstr .. indent .. '' .. k .. '='
        retstr = retstr .. serialize(v,ind+1)
        retstr = retstr .. ',\n'
      end
      retstr = retstr .. indent:sub(1,indent:len()-2) .. '}'
    else
      retstr = retstr .. '<'..type(o)..'>'
    end
    return retstr
end
-- console
local console_header = '#>'
--- output buffer
local out = {} -- output system
out.history = {} -- output lines history
out.historysize = h*10 -- history size
out.coutl = {} -- current output line
out.line = 1 -- current line
out.lptr = 1 -- line pointer to history table
out.col = 1 -- current column
out.topline = 0 -- last line in history
local function outl()
  if out.topline ~= 0 then return end
  g.fill(out.col,out.line,w,1)
  local strout = tabletostr(out.coutl)
  g.drawText(1,out.line,strout)
end
function cout(str)
  str = tostring(str)
  if #str > 1 then
    local atab = strtotable(str)
    for i=1, #atab do
      table.insert(out.coutl,out.col,atab[i])
      out.col = out.col + 1
    end
  else
    table.insert(out.coutl,out.col,str)
    out.col = out.col + 1
  end
  outl()
end
local function backspace()
  if out.col <= #console_header+1 then
    out.col = #console_header+1
    return
  end
  table.remove(out.coutl,out.col-1)
  out.col = out.col - 1
  outl()
end
local function scrollUp()
  if #out.history >= h then
    if out.topline == 0 then outl() end
    out.topline = out.topline + 1
    if out.topline+(h-1) > #out.history then
      out.topline = #out.history - h+1
      return false
    end
    g.copy(1,1,w,h-1,0,1)
    g.fill(1,1,w,1)
    g.drawText(1,1,out.history[out.topline + (h-1)])
    return true
  end
end
local function scrollDown()
  if #out.history >= h then
    out.topline = out.topline - 1
    if out.topline < 0 then
      out.topline = 0
      return false
    end
    if out.topline == 0 then
      g.copy(1,2,w,h-1,0,-1)
      g.fill(1,h,w,1)
      outl()
    else
      g.copy(1,2,w,h-1,0,-1)
      g.fill(1,h,w,1)
      g.drawText(1,h,out.history[out.topline])
    end
    return true
  end
end
local function newline()
  local atab = tabletostr(out.coutl)
  table.insert(out.history,1,atab)
  if #out.history > out.historysize then
    table.remove(out.history)
  end
  out.line = out.line + 1
  out.lptr = out.lptr + 1
  if out.line > h then
    out.line = h
    if out.topline == 0 then
      g.copy(1,2,w,h-1,0,-1)
      g.fill(1,h,w,1)
    end
  end
  out.col = 1
  out.coutl = {}
end
function print(str)
  if type(str) == 'table' then
    str = serialize(str)
  else
    str = tostring(str)
  end
  local prev = 1
  for w in string.gmatch(str,'()\n') do
    cout(str:sub(prev,w-1))
    prev = w+1
    newline()
  end
  cout(str:sub(prev))
  newline()
end
local function main()
  local curloc = 1
  local curstate = false
  local function blinkcursor()
    if out.topline ~= 0 then return end
    if curstate then
      g.drawText(out.col,out.line,unicode.char(0x2588))
    else
      outl()
    end
    curstate = not curstate
  end
  --- cmd history
  local cmdhistory = {}
  local cmdhlen = 20
  local cmdhbrowse = 0
  -- TODO
  print(_osname..' '.._osversion..'\n\n')
  cout(console_header)
  while true do
    local evt = table.pack(computer.pullSignal(0.4))
    if evt[1] == 'key_down' then
      if evt[4] == 88 then computer.shutdown(true) end -- F12 to restart
      if evt[4] == 68 then computer.shutdown() end -- F10 to shutdown
      -- command
      if evt[4] == 28 then -- enter key
        outl()
        -- convert to string
        local cinput = tabletostr(out.coutl)
        cinput = cinput:sub(#console_header+1)
        -- add to history
        if cinput ~= '' then
          table.insert(cmdhistory,1,cinput)
        end
        if #cmdhistory > cmdhlen then table.remove(cmdhistory) end
        -- parse command
        local luacmd = cinput
        --[[local args = {}
        local argc = 0
        local cmdget = false
        local command = ''
        cinput = string.gsub(cinput,'%s',unicode.char(0x2591))
        for p in string.gmatch(cinput,'(.-)'..unicode.char(0x2591)) do
          if not cmdget then
            command = p
            cmdget = true
          else
            table.insert(args,p)
            argc = argc + 1
          end
        end]]
        -- execute
        newline()
        cmdhbrowse = 0
        local loaded,lderr = load(luacmd,'=cinput')
        if loaded then
          local res,err = xpcall(loaded,function(msg) return msg ..'\n'.. debug.traceback() end)
          if not res and err then
            print(err)
          end
        elseif not loaded and lderr then
          print(lderr)
        else
          print('Unknown Command')
        end
        -- done
        cout(console_header)
      elseif evt[4] == 14 then -- backspace
        curstate = true -- keep cursor displayed
        backspace()
      elseif evt[4] == 200 then -- up key
        out.coutl = {}
        out.col = 1
        if cmdhbrowse >= #cmdhistory then cmdhbrowse = #cmdhistory else
        cmdhbrowse = cmdhbrowse + 1 end
        local hval = cmdhistory[cmdhbrowse]
        cout(console_header)
        cout(hval)
      elseif evt[4] == 208 then -- down key
        out.coutl = {}
        out.col = 1
        if cmdhbrowse <= 1 then cmdhbrowse = 1 else
        cmdhbrowse = cmdhbrowse - 1 end
        local hval = cmdhistory[cmdhbrowse]
        cout(console_header)
        cout(hval)
      elseif evt[4] == 203 then -- left key
        curstate = true -- keep cursor displayed
        out.col = out.col - 1
        if out.col < #console_header+1 then
          out.col = #console_header+1
        end
        outl()
      elseif evt[4] == 205 then --  right key
        curstate = true -- keep cursor displayed
        out.col = out.col + 1
        if out.col > #out.coutl+1 then
          out.col = #out.coutl+1
        end
        outl()
      elseif evt[4] == 199 then -- home
        curstate = true
        out.col = #console_header+1
        outl()
      elseif evt[4] == 207 then -- end
        curstate = true
        out.col = #out.coutl+1
        outl()
      elseif evt[3] ~= 0 then -- printable keys
        curstate = true -- keep cursor displayed
        local char = string.char(evt[3])
        cout(char)
      end
    elseif evt[1] == 'scroll' then
      if evt[5] > 0 then -- scroll up
        scrollUp()
      elseif evt[5] < 0 then -- scroll down
        scrollDown()
      end
    end
    blinkcursor()
  end
end
-- autorun
if component.filesystem.exists('autorun.lua') then
  f.runfile('autorun.lua')
end
-- run shell
local res,err = xpcall(main,function(msg) return msg ..'\n'.. debug.traceback() end)
if not res and err then
  error(err)
end
computer.shutdown()