require ("RequestLogger")
require ("DebugLogger")
require ("LuupDataProvider")
require ("JsonDataProvider")

require ("Utils")

io.stdout:setvbuf('no')

print(os.time().."\tStart RestAPI")

DEBUG = 1

MAX_FILE_SIZE = 1024 * 512

dataProvider = LuupDataProvider.new(DEBUG)

--if dataProvider == nil then
--  os.exit()
--end
provider = JsonDataProvider.new() 


copas = require "copas"

socket = require( "socket" ) 

url = require "socket.url"

server = socket.bind( "*", 7979 ) 


function debug(msg, prio)
  
  if DEBUG >= prio then
    
    DebugLogger.LogMsg(msg)
    
  end
end



function echoHandler(skt)
  debug("Function echoHandler", 3)
  
  local srv, port = skt:getsockname ()
  local request = 
  {
          rawskt = skt,
          srv = srv,
          port = port,
          copasskt = copas.wrap (skt),
  }
  request.socket = request.copasskt

  while read_method (request) do
    
    response = {}
    
    read_headers (request, response)
    
    if not response.status then read_params (request, response) end
    
    if not response.status then parse_url(request, response) end
    
    if not response.status then log_request(request) end
    
    if not response.status then process_request(request, response) end
    
    send_response(request, response)
    
    
    if response.quit == true then
      os.exit()
    end
    
    --if not request.keepalive or response.status ~= "200 OK" then
    --  print("Close connection")
    --  break
    --end
    break
  end
end

function strsplit (str)
  debug("Function strsplit", 3)
  
  local words = {}

  for w in string.gmatch (str, "%S+") do
          table.insert (words, w)
  end

  return words
end

function strSplitBySeperator(inputstr, sep)
  debug("Function strSplitBySeperator", 3)
  
  if sep == nil then
          sep = "%s"
    end
    
    local t={} 
    local i=1
    
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end


function read_method (req)
  debug("Function read_method", 3)
  
  local err
  req.cmdline, err = req.socket:receive ()

  if not req.cmdline then
    debug("Nothing received from client. Error: "..err, 1)
    return nil 
  end
  
  req.cmd_mth, req.cmd_url, req.cmd_version = unpack (strsplit (req.cmdline))
  req.cmd_mth = string.upper (req.cmd_mth or 'GET')
  req.cmd_url = req.cmd_url or '/'

  debug("Method: "..req.cmd_mth, 2)
  
  return true
end

function read_headers (req, response)
  debug("Function read_headers", 3)
  
  local headers = {}
  local prevval, prevname

  while 1 do
    local l,err = req.socket:receive ()
    
    if (not l or l == "") then
      req.headers = headers
      
      if headers["connection"] == "Keep-Alive" or headers["connection"] == "keep-alive" then
        req.keepalive = true
      else
        req.keepalive = nil
      end
      
      
      for key,value in pairs(headers) do
        debug(key..": "..value, 2)
      end
      
      return
    end
    
    local _,_, name, value = string.find (l, "^([^: ]+)%s*:%s*(.+)")
    name = string.lower (name or '')
    
    if name then
      prevval = headers [name]
      if prevval then
        value = prevval .. "," .. value
      end
      headers [name] = value
      prevname = name
    elseif prevname then
      headers [prevname] = headers [prevname] .. l
    end
    
  end
end

function read_params (req, response)
  debug("Function read_params", 3)
  
  if req.cmd_mth == "POST" or req.cmd_mth == "PUT" then
    req.parameter = nil

    local contentLength = tonumber(req.headers["content-length"])
    local data, err = req.socket:receive ( contentLength )
    
    if not err then
      req.parameter = data
    end 
    
    if req.parameter == nil then
      debug("Cant receive parameters. Error: "..err,1)
      
      response.status = "400 Bad Request"
      response.content_type  = "text/plain"
    end
    
  end
end

function parse_url (req, response)
  debug("Function parse_url", 3)
  
  local def_url = string.format ("http://%s%s", req.headers.host or "", req.cmd_url or "")

  req.parsed_url = url.parse (def_url or '')
  req.parsed_url.port = req.parsed_url.port or req.port
  req.built_url = url.build (req.parsed_url)

  req.relpath = url.unescape (req.parsed_url.path)
  
  if not validate_relpath(req.relpath) then
    debug("Resource in unknown format. URL: "..req.relpath,1)
    
    response.status = "400 Bad Request"
    response.content_type  = "text/plain"
  end
  
end

function validate_relpath (relpath)
  debug("Function validate_relpath", 3)
  
  retval = false;
  if string.match(relpath, '^/rest/version') or
     string.match(relpath, '^/rest/version/[A-Z][0-9][0-9]$') or
     string.match(relpath, '^/rest/devices/battery') or
     string.match(relpath, '^/rest/devices/battery/[A-Z][0-9][0-9]$') or
     string.match(relpath, '^/rest/events') or
     string.match(relpath, '^/rest/debug') or
     string.match(relpath, '^/rest/alive') or
     string.match(relpath, '^/rest/delay') or
     string.match(relpath, '^/rest/reboot') or
     string.match(relpath, '^/rest/quit') then
     retval = true
  end 
  return retval
end



function log_request (req)
  debug("Function log_request", 3)
  
  RequestLogger.LogRequest(os.time(), req.rawskt:getsockname(), req.cmd_mth, req.relpath, req.parameter)
end



function send_response (request, response)
  debug("Function send_response", 3)
  
  request.socket:send( "HTTP/1.1 "..response.status.."\r\n" )
  
  -- if request.keepalive then
  --  print ("Sending keepalive")
  --  request.socket:send( "connection: keep-alive\r\n" )
  -- end
  
  
  request.socket:send( "Content-Type: "..response.content_type.."\r\n\r\n" )
  
  if response.content then
    request.socket:send( response.content.."\r\n" )
  end
  
  request.socket:flush ()
  
end

function process_request(req, response)
  debug("Function process_request", 3)
  
  -- process GET
  if req.cmd_mth == "GET" then
    if req.relpath == "/rest/version" then
      local data = nil
      -- data = dataProvider.GetVersionData()
      data = '{"S01":'.. provider.getStatusValueByKey("S01") .. ',"S15":"'.. provider.getStatusValueByKey("S15") .. '","S16":"'.. provider.getStatusValueByKey("S16") .. '","S65":'.. provider.getStatusValueByKey("S65") .. ',"S66":"'.. provider.getStatusValueByKey("S66") .. '","S69":'.. provider.getStatusValueByKey("S69") .. ',"S70":"'.. provider.getStatusValueByKey("S70") .. '"}'
      
      
      if data == nil then
        debug("Cant read Version Data.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "application/json"
        response.content = data
      end
       
       
    elseif req.relpath == "/rest/devices/battery" then
      local data = nil
      --data = dataProvider.GetBatteryData()
      data = '{"C06":'.. provider.getStatusValueByKey("C06") .. ', "C07":'.. provider.getStatusValueByKey("C07") .. ',"C08":'.. provider.getStatusValueByKey("C08") .. ',"C09":'.. provider.getStatusValueByKey("C09") .. ',"C10":'.. provider.getStatusValueByKey("C10") .. ',"C11":'.. provider.getStatusValueByKey("C11") .. ',"C12":'.. provider.getStatusValueByKey("C12") .. ',"C23":'.. provider.getStatusValueByKey("C23") .. ', "C24":'.. provider.getStatusValueByKey("C24") .. ', "M03":'.. provider.getStatusValueByKey("M03") .. ',"M04":'.. provider.getStatusValueByKey("M04") .. ',"M05":'.. provider.getStatusValueByKey("M05") .. ',"M06":'.. provider.getStatusValueByKey("M06") .. ',"M07":'.. provider.getStatusValueByKey("M07") .. ',"M08":'.. provider.getStatusValueByKey("M08") .. ',"M09":'.. provider.getStatusValueByKey("M09") .. ', "M30":'.. provider.getStatusValueByKey("M30") .. ',"M31":'.. provider.getStatusValueByKey("M31") .. ',"M34":'.. provider.getStatusValueByKey("M34") .. ',"M35":'.. provider.getStatusValueByKey("M35") .. ',"M37":'.. provider.getStatusValueByKey("M37") .. ',"M38":'.. provider.getStatusValueByKey("M38") .. ',"M39":'.. provider.getStatusValueByKey("M39") .. ', "M40":'.. provider.getStatusValueByKey("M40") .. ',"M41":'.. provider.getStatusValueByKey("M41") .. ',"S01":'.. provider.getStatusValueByKey("S01") .. ',"S07":"'.. provider.getStatusValueByKey("S07") .. '","S08":'.. provider.getStatusValueByKey("S08") .. ',"S15":"'.. provider.getStatusValueByKey("S15") .. '","S16":"'.. provider.getStatusValueByKey("S16") .. '", "S45":"'.. provider.getStatusValueByKey("S45") .. '", "S160":'.. provider.getStatusValueByKey("S160") .. ',"S161":"'.. provider.getStatusValueByKey("S161") .. ',"S65":'.. provider.getStatusValueByKey("S65") .. ',"S66":'.. provider.getStatusValueByKey("S66") .. ',"S69":'.. provider.getStatusValueByKey("S69") .. ',"S70":"'.. provider.getStatusValueByKey("S70") .. '"}'
      
      if data == nil then
        debug("Cant read Battery Data.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "application/json"
        response.content = data
      end
      
      
    elseif string.match(req.relpath, '^/rest/version/[M,S,C,F]%d%d+$') or
           string.match(req.relpath, '^/rest/devices/battery/[M,S,C,F]%d%d+$') then
      --local identifier = string.sub(req.relpath, -3)
      
      
      local urlPathElements = Utils.Split(req.relpath, "/")
      local identifier = urlPathElements[table.getn(urlPathElements)]
      local data = nil
      --data = dataProvider.GetDataByIdentifier(identifier)
      data = provider.getStatusValueByKey(identifier)
      if data == nil then
        debug("Cant read resource by identifier.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
        response.content = data
      end
      
      
    elseif req.relpath == "/rest/events" then
      local data = nil
      data = dataProvider.GetEventData()
      
      if data == nil then
        debug("Cant read Event Data.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "application/json"
        response.content = data
      end
      
      
    elseif req.relpath == "/rest/quit" then 
      response.quit = true
      response.status = "200 OK"
      response.content_type  = "text/plain"
      response.content = "Quit Server"
    
    
    elseif req.relpath == "/rest/alive" then 
      response.status = "200 OK"
      response.content_type  = "text/plain"
      response.content = "Server alive"
      
      
    elseif req.relpath == "/rest/delay" then
      delay = 5
      os.execute("sleep "..delay)
      response.status = "200 OK"
      response.content_type  = "text/plain"
      response.content = "Delay with "..delay.." seconds."
      
    elseif req.relpath == "/rest/reboot" then
      os.execute("reboot")
      response.status = "200 OK"
      response.content_type  = "text/plain"
      response.content = "reboot executed"
      
      
    else
      debug("Resource not found: "..req.relpath, 1)
      
      response.status = "404 Not Found"
      response.content_type  = "text/plain"
    end
  end
   
  
  -- process PUT
  if req.cmd_mth == "PUT" then  
    if req.relpath == "/rest/devices/battery/C23" then
      local retval = false
      retval = dataProvider.SetSetpointForDischargingPower(req.parameter)
      
      if retval == false then
        debug("Cant set setpoint for discharging.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end
      
      
    elseif req.relpath == "/rest/devices/battery/C24" then
      local retval = false
      retval = dataProvider.SetSetpointForChargingPower(req.parameter)
      
      if retval == false then
        debug("Cant set setpoint for charging.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end
      
      
    elseif req.relpath == "/rest/devices/battery/C07" then
      local retval = false
      retval = dataProvider.SetLoadOnLine(req.parameter, 1)
      
      if retval == false then
        debug("Cant set measured load for L1.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end
    
    
    elseif req.relpath == "/rest/devices/battery/C08" then
      local retval = false
      retval = dataProvider.SetLoadOnLine(req.parameter, 2)
      
      if retval == false then
        debug("Cant set measured load for L2.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end
      
      
    elseif req.relpath == "/rest/devices/battery/C09" then
      local retval = false
      retval = dataProvider.SetLoadOnLine(req.parameter, 3)
      
      if retval == false then
        debug("Cant set measured load for L3.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end
      
      
    elseif req.relpath == "/rest/devices/battery/C10" then
      local retval = false
      retval = dataProvider.SetProductionOnLine(req.parameter, 1)
      
      if retval == false then
        debug("Cant set measured production for L1.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end
      
      
    elseif req.relpath == "/rest/devices/battery/C11" then
      local retval = false
      retval = dataProvider.SetProductionOnLine(req.parameter, 2)
      
      if retval == false then
        debug("Cant set measured production for L2.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end
      
      
    elseif req.relpath == "/rest/devices/battery/C12" then
      local retval = false
      retval = dataProvider.SetProductionOnLine(req.parameter, 3)
      
      if retval == false then
        debug("Cant set measured production for L3.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end
      
      
      
    elseif req.relpath == "/rest/devices/battery/C06" then
      local retval = false
      retval = dataProvider.SetOperationMode(req.parameter)
      
      if retval == false then
        debug("Cant set operationmode.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end
      
    -- setting PV reduction accepted parameters 0; 1; 2; 3;   
    elseif req.relpath == "/rest/devices/battery/C28" then
      local retval = false
      retval = dataProvider.SetPVreductionManually(req.parameter)
      
      if retval == false then
        debug("Cant set PV reduction manually.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end
     
    -- Delete SD Card now BOOL;    
    elseif req.relpath == "/rest/devices/battery/C30" then
      local retval = false
      retval = dataProvider.SetDeleteSDCardNow(req.parameter)
      
      if retval == false then
        debug("Can't set delete SD Card.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end   
      
    -- Delete SD Card monthly BOOL;    
    elseif req.relpath == "/rest/devices/battery/C31" then
      local retval = false
      retval = dataProvider.SetDeleteSDCardMonthly(req.parameter)
      
      if retval == false then
        debug("Can't set delete SD Card monthly.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end   
        
      
    -- setting US weather prognosis DATA accepted parameters STRING;    
    elseif req.relpath == "/rest/devices/battery/C35" then
      local retval = false
      retval = dataProvider.SetUSWeatherPrognosisDATA(req.parameter)
      
      if retval == false then
        debug("Cant set US weatherprognosis DATA.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end   
      
    -- activate critical update BOOL;    
    elseif req.relpath == "/rest/devices/battery/C40" then
      local retval = false
      retval = dataProvider.SetCriticalUpdate(req.parameter)
      
      if retval == false then
        debug("Can't set critical Update bool.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end    
      
      -- setting S161: Minimum days at which files will be deleted older than the setting. Standard value = 370 INT;      
    elseif req.relpath == "/rest/devices/battery/S161" then
      local retval = false
      retval = dataProvider.SetDeleteMinDaySetting(req.parameter)
      
      if retval == false then
        debug("Cant set delete files min day Setting.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end
      
      
    -- setting US weather prognosis Set active BOOL;      
    elseif req.relpath == "/rest/devices/battery/S162" then
      local retval = false
      retval = dataProvider.SetUSWeatherPrognosisSetting(req.parameter)
      
      if retval == false then
        debug("Cant set US weatherprognosis active.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end
      
      
    elseif req.relpath == "/rest/devices/battery/S104" then
      local retval = false
      retval = dataProvider.SetAutomaticCellCareStatus(req.parameter)
      
      if retval == false then
        debug("Cant set automatic cellcarestatus.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
      end
      
      
      
    elseif req.relpath == "/rest/debug" then
      DEBUG = tonumber(req.parameter)
      response.status = "200 OK"
      response.content_type  = "text/plain"
      
      
    else
      debug("Resource not found: "..req.relpath, 1)
      
      response.status = "404 Not Found"
      response.content_type  = "text/plain"
    end
  end

  
  return response
end


copas.addserver(server, echoHandler)
copas.loop()



















