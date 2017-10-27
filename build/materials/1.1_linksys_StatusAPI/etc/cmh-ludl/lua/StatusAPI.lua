require ("RequestLogger")
require ("DebugLogger")
--require ("LuupDataProvider")
require ("Utils")
require ("JsonDataProvider")

io.stdout:setvbuf('no')

print(os.time().."\tStart StatusAPI")

DEBUG = 1

MAX_FILE_SIZE = 1024 * 512

--dataProvider = LuupDataProvider.new(DEBUG)

--if dataProvider == nil then
--  os.exit()
--end
local buildnumber = 1
local version = 1.0

copas = require "copas"

socket = require( "socket" ) 

url = require "socket.url"

server = socket.bind( "*", 3480 ) 
--portal 3480

--receiver = UdpReceiver_LS.new("*", 1202)
provider = JsonDataProvider.new() 
--local socketLS = receiver.connectToServer("*", 1202)
--local apiStatus = receiver.createClientLoop(socketLS, "*", 1202)

--receiver = UdpReceiver.new("*", sbIncomingPort, OnReceive, lul_device)
--luup.call_delay("StartReceiver",1,tostring(lul_device), 0) 



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
     string.match(relpath, '^/data_request') or
     string.match(relpath, '^/rest/debug') or
     string.match(relpath, '^/rest/alive') or
     string.match(relpath, '^/rest/delay') or
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
      data = dataProvider.GetVersionData()
      
      if data == nil then
        debug("Cant read Version Data.", 1)
        
        response.status = "500 Internal Server Error no data"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "application/json"
        response.content = data
      end
       
    elseif req.relpath == "/rest/devices/battery" then
      local data = nil
      data = dataProvider.GetBatteryData()
      
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
      data = dataProvider.GetDataByIdentifier(identifier)
      
      if data == nil then
        debug("Cant read resource by identifier.", 1)
        
        response.status = "500 Internal Server Error"
        response.content_type  = "text/plain"
      else
        response.status = "200 OK"
        response.content_type  = "text/plain"
        response.content = data
      end
      
      
    elseif req.relpath == "/data_request" then
      local data = nil
      --data = dataProvider.GetEventData()
--      print("req: ") 
--      print(req)
--      print("req.relpath") 
--      print(req.relpath)
--      print(req.cmd_mth)
--      print(req.path)
        print(req.cmd_url)
--      print("test") 
--      print(provider.getStatusValueByKey("M30"))
--      print(provider.getStatusValueByKey("M06"))
      
      req.cmd_url = string.sub(req.cmd_url, 0, 26)
      print(req.cmd_url)
      
      local data
      
      
      if req.cmd_url == "/data_request?id=sdata"  or req.cmd_url == "/data_request?id=sdata&output_format=json" or req.cmd_url == "/data_request?id=sdata&loa" then
        print("sdata"..os.time()) 
        local data_sdata ='{"full": 1,"version": "*1.5.622*","model": "Sercomm NA900","zwave_heal": 1,"temperature": "C","serial_number": "30110285","fwd1": "fwd1.mios.com","fwd2": "fwd2.mios.com","sections": [{"name": "My Home","id": 1}],"rooms": [{"name": "Sonnenbatterie","id": 1,"section": 1}],"scenes": [],"devices": [{"name": "BHKW 1","altid": "CHP-1","id": 6,"category": 0,"subcategory": 0,"room": 1,"parent": 3,"watts": "0","chppeakpower": "0"},{"name": "Eigenverbrauchsrelais 1","altid": "OwnConsumptionRelay-1","id": 8,"category": 0,"subcategory": 0,"room": 1,"parent": 3,"automode": "0","duration": "30","threshold": "1000","status": "0"},{"name": "Gesamtverbauch 1","altid": "TotalConsumption-1","id": 7,"category": 0,"subcategory": 0,"room": 1,"parent": 3,"wattsl1": "0","wattsl2": "0","wattsl3": "0","maxwattsl1": "0","maxwattsl2": "0","maxwattsl3": "0","iscountercumulated": "0","watts": "0.0"},{"name": "Photovoltaik 1","altid": "Photovoltaics-1","id": 4,"category": 0,"subcategory": 0,"room": 1,"parent": 3,"watts": "0","maxfeedin": "100","pvpeakpower": "5.04"},{"name": "Sonnenbatterie #'.. provider.getStatusValueByKey("S15") .. '","altid": "","id": 3,"category": 0,"subcategory": -1,"room": 1,"parent": 0,"priority": "1","watts": "0","soc": "'.. provider.getStatusValueByKey("M05") .. '","temperature": "0.0","chargingcontactor": "-1","consumptioncontactor": "FALSE","nocharging": "FALSE","capacity": "0040","chargingbuffer": "50","switchingthresholdgrid": "-1","switchingthresholdbattery": "-1","serialnumber": "'.. provider.getStatusValueByKey("S15") .. '","versionplc": "'.. provider.getStatusValueByKey("S16") .. '","nominalvoltage": "51.2","lowerlimitsoc": "0","location": "'.. provider.getStatusValueByKey("S07") .. '","autosocket1": "0","autosocket2": "0","autosocket3": "0","wattsdischarge": "'.. provider.getStatusValueByKey("M34") .. '","operatingmode": "'.. provider.getStatusValueByKey("M06") .. '","operationmode": "'.. provider.getStatusValueByKey("M06") .. '","lastoperationmodechange": "1505291615","chargingpowermanual": "2300","wattscharge": "'.. provider.getStatusValueByKey("M35") .. '","lastvaliddata": "1505292171"},{"name": "Waermepumpe 1","altid": "Heatpump-1","id": 5,"category": 0,"subcategory": 0,"room": 1,"parent": 3,"isheatpumpgrid": "FALSE","isheatpumpbattery": "FALSE","isheatpumpinstalled": "FALSE"}],"categories": [],"ir": 0,"irtx": "","loadtime": 0,"dataversion": 0,"state": 1,"comment": "Linksys"}'    
        
        data = data_sdata
        
      elseif req.cmd_url == "/data_request?id=status" or req.cmd_url == "/data_request?id=status&ou" or req.cmd_url == "/data_request?id=status&Lo" then
        print("status"..os.time()) 
        local data_0 = '{"startup": {"tasks": []},"devices": [{"id": 1,"states": [],"Jobs": [],"tooltip": {"display": 0},"status": -1},{"id": 2,"states": [],"Jobs": [],"tooltip": {"display": 0},"status": -1},{"id": 3,"states": [{"id": 73,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "Priority","value": "1"},{"id": 74,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "Restart","value": "1"},{"id": 75,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "VersionSmartFunction","value": "LS_1.0"},{"id": 76,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S70","value": "'.."LS".. version.. '"},{"id": 77,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "BuildNumber","value": "'..buildnumber..'"},{"id": 78,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "Watts","value": "0"},{"id": 79,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "WattsDischarge","value": "'.. provider.getStatusValueByKey("M34") .. '"},{"id": 80,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "WattsCharge","value": "'.. provider.getStatusValueByKey("M35") .. '"},{"id": 81,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "SOC","value": "'.. provider.getStatusValueByKey("M05") .. '"},{"id": 82,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "OperationMode","value": "'.. provider.getStatusValueByKey("M06") .. '"},{"id": 83,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "Temperature","value": "0.0"},{"id": 84,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "ChargingContactor","value": "-1"},{"id": 85,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "ConsumptionContactor","value": "FALSE"},{"id": 86,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "NoCharging","value": "FALSE"},{"id": 87,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "Capacity","value": "0040"},{"id": 88,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "ChargingPowerManual","value": "2300"},{"id": 89,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "ChargingBuffer","value": "50"},{"id": 90,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "SwitchingThresholdGrid","value": "-1"},{"id": 91,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "SwitchingThresholdBattery","value": "-1"},{"id": 92,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "SerialNumber","value": "'.. provider.getStatusValueByKey("S15") .. '"},{"id": 93,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "VersionPLC","value": "'.. provider.getStatusValueByKey("S16") .. '"},{"id": 94,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "NominalVoltage","value": "51.2"},{"id": 95,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "LowerLimitSoc","value": "0"},{"id": 96,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "Location","value": "DE-87499"},{"id": 97,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "LastOperationModeChange","value": "1504185634"},{"id": 98,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "LastValidData","value": "'..os.time()..'"},{"id": 99,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "C07","value": "0"},{"id": 100,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "C08","value": "0"},{"id": 101,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "C09","value": "0"},{"id": 102,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "C10","value": "0"},{"id": 103,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "C11","value": "0"},{"id": 104,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "C12","value": "0"},{"id": 105,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "C23","value": "0"},{"id": 106,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "C24","value": "0"},{"id": 107,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "NumberOfPhotovoltaics","value": "1"},{"id": 108,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "NumberOfHeatpumps","value": "1"},{"id": 109,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "NumberOfCHPs","value": "1"},{"id": 110,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "NumberOfTotalConsumptions","value": "1"},{"id": 111,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "NumberOfOwnConsumptionRelais","value": "1"},{"id": 112,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S92","value": "'.. provider.getStatusValueByKey("S92") .. '"},{"id": 113,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S110","value": "'.. provider.getStatusValueByKey("S110") .. '"},{"id": 114,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S96","value": "'.. provider.getStatusValueByKey("S96") .. '"},{"id": 115,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S116","value": "'.. provider.getStatusValueByKey("S116") .. '"},{"id": 116,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S113","value": "'.. provider.getStatusValueByKey("S113") .. '"},{"id": 117,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S93","value": "'.. provider.getStatusValueByKey("S93") .. '"},{"id": 118,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S104","value": "'.. provider.getStatusValueByKey("S104") .. '"},{"id": 119,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S102","value": "'.. provider.getStatusValueByKey("S102") .. '"},{"id": 120,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S109","value": "'.. provider.getStatusValueByKey("S109") .. '"},{"id": 121,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S97","value": "'.. provider.getStatusValueByKey("S97") .. '"},{"id": 122,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S108","value": "'.. provider.getStatusValueByKey("S108") .. '"},{"id": 123,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S99","value": "'.. provider.getStatusValueByKey("S99") .. '"},{"id": 124,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S119","value": "'.. provider.getStatusValueByKey("S119") .. '"},{"id": 125,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S103","value": "'.. provider.getStatusValueByKey("S103") .. '"},{"id": 126,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S94","value": "'.. provider.getStatusValueByKey("S94") .. '"},{"id": 127,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S105","value": "'.. provider.getStatusValueByKey("S105") .. '"},{"id": 128,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S115","value": "'.. provider.getStatusValueByKey("S115") .. '"},{"id": 129,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S101","value": "'.. provider.getStatusValueByKey("S101") .. '"},{"id": 130,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S98","value": "'.. provider.getStatusValueByKey("S98") .. '"},{"id": 131,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S91","value": "'.. provider.getStatusValueByKey("S91") .. '"},{"id": 132,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S111","value": "'.. provider.getStatusValueByKey("S111") .. '"},{"id": 133,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S112","value": "'.. provider.getStatusValueByKey("S112") .. '"},{"id": 134,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S117","value": "'.. provider.getStatusValueByKey("S117") .. '"},{"id": 135,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S95","value": "'.. provider.getStatusValueByKey("S95") .. '"},{"id": 136,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S100","value": "'.. provider.getStatusValueByKey("S100") .. '"},{"id": 137,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S118","value": "'.. provider.getStatusValueByKey("S118") .. '"},{"id": 138,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S139","value": "'.. provider.getStatusValueByKey("S139") .. '"},{"id": 139,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S123","value": "'.. provider.getStatusValueByKey("S123") .. '"},{"id": 140,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S122","value": "'.. provider.getStatusValueByKey("S122") .. '"},{"id": 141,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S131","value": "'.. provider.getStatusValueByKey("S131") .. '"},{"id": 142,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S127","value": "'.. provider.getStatusValueByKey("S127") .. '"},{"id": 143,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S125","value": "'.. provider.getStatusValueByKey("S125") .. '"},{"id": 144,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S132","value": "'.. provider.getStatusValueByKey("S132") .. '"},{"id": 145,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S120","value": "'.. provider.getStatusValueByKey("S120") .. '"},{"id": 146,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S138","value": "'.. provider.getStatusValueByKey("S138") .. '"},{"id": 147,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S137","value": "'.. provider.getStatusValueByKey("S137") .. '"},{"id": 148,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S126","value": "'.. provider.getStatusValueByKey("S126") .. '"},{"id": 149,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S128","value": "'.. provider.getStatusValueByKey("S128") .. '"},{"id": 150,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S133","value": "'.. provider.getStatusValueByKey("S133") .. '"},{"id": 151,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S136","value": "'.. provider.getStatusValueByKey("S136") .. '"},{"id": 152,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S129","value": "'.. provider.getStatusValueByKey("S129") .. '"},{"id": 153,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S135","value": "'.. provider.getStatusValueByKey("S135") .. '"},{"id": 154,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S121","value": "'.. provider.getStatusValueByKey("S121") .. '"},{"id": 155,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S124","value": "'.. provider.getStatusValueByKey("S124") .. '"},{"id": 156,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S130","value": "'.. provider.getStatusValueByKey("S130") .. '"},{"id": 157,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S142","value": "'.. provider.getStatusValueByKey("S142") .. '"},{"id": 158,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S144","value": "'.. provider.getStatusValueByKey("S144") .. '"},{"id": 159,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S146","value": "'.. provider.getStatusValueByKey("S146") .. '"},{"id": 160,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S143","value": "'.. provider.getStatusValueByKey("S143") .. '"},{"id": 161,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S161","value": "'.. provider.getStatusValueByKey("S161") .. '"},{"id": 162,"service": "urn:psi-storage-com:serviceId:Battery1",'
        
local data_1 = '"variable": "S152","value": "'.. provider.getStatusValueByKey("S152") .. '"},{"id": 163,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S154","value": "'.. provider.getStatusValueByKey("S154") .. '"},{"id": 164,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S160","value": "'.. provider.getStatusValueByKey("S160") .. '"},{"id": 165,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S145","value": "'.. provider.getStatusValueByKey("S145") .. '"},{"id": 166,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M12","value": "'.. provider.getStatusValueByKey("M12") .. '"},{"id": 167,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M02","value": "'.. provider.getStatusValueByKey("M02") .. '"},{"id": 168,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M06","value": "'.. provider.getStatusValueByKey("M06") .. '"},{"id": 169,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M01","value": "'.. provider.getStatusValueByKey("M01") .. '"},{"id": 170,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M11","value": "'.. provider.getStatusValueByKey("M11") .. '"},{"id": 171,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M05","value": "'.. provider.getStatusValueByKey("M05") .. '"},{"id": 172,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M10","value": "'.. provider.getStatusValueByKey("M10") .. '"},{"id": 173,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M20","value": "'.. provider.getStatusValueByKey("M20") .. '"},{"id": 174,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M14","value": "'.. provider.getStatusValueByKey("M14") .. '"},{"id": 175,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M08","value": "'.. provider.getStatusValueByKey("M08") .. '"},{"id": 176,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M04","value": "'.. provider.getStatusValueByKey("M04") .. '"},{"id": 177,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M18","value": "'.. provider.getStatusValueByKey("M18") .. '"},{"id": 178,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M03","value": "'.. provider.getStatusValueByKey("M03") .. '"},{"id": 179,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M13","value": "'.. provider.getStatusValueByKey("M13") .. '"},{"id": 180,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M09","value": "'.. provider.getStatusValueByKey("M09") .. '"},{"id": 181,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M19","value": "'.. provider.getStatusValueByKey("M19") .. '"},{"id": 182,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M07","value": "'.. provider.getStatusValueByKey("M07") .. '"},{"id": 183,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M17","value": "'.. provider.getStatusValueByKey("M17") .. '"},{"id": 184,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M32","'.. provider.getStatusValueByKey("M32") .. '": "0"},{"id": 185,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M22","value": "'.. provider.getStatusValueByKey("M22") .. '"},{"id": 186,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M36","value": "'.. provider.getStatusValueByKey("M36") .. '"},{"id": 187,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M26","value": "'.. provider.getStatusValueByKey("M26") .. '"},{"id": 188,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M21","value": "'.. provider.getStatusValueByKey("M21") .. '"},{"id": 189,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M31","value": "'.. provider.getStatusValueByKey("M31") .. '"},{"id": 190,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M25","value": "'.. provider.getStatusValueByKey("M25") .. '"},{"id": 191,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M39","value": "'.. provider.getStatusValueByKey("M39") .. '"},{"id": 192,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M29","value": "'.. provider.getStatusValueByKey("M29") .. '"},{"id": 193,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M30","value": "'.. provider.getStatusValueByKey("M30") .. '"},{"id": 194,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M24","value": "'.. provider.getStatusValueByKey("M24") .. '"},{"id": 195,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M28","value": "'.. provider.getStatusValueByKey("M28") .. '"},{"id": 196,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M34","value": "'.. provider.getStatusValueByKey("M34") .. '"},{"id": 197,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M33","value": "'.. provider.getStatusValueByKey("M33") .. '"},{"id": 198,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M38","value": "'.. provider.getStatusValueByKey("M38") .. '"},{"id": 199,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M37","value": "'.. provider.getStatusValueByKey("M37") .. '"},{"id": 200,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M27","value": "'.. provider.getStatusValueByKey("M27") .. '"},{"id": 201,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M35","value": "'.. provider.getStatusValueByKey("M35") .. '"},{"id": 202,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M51","value": "2.7.0"},{"id": 203,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M54","value": "'.. provider.getStatusValueByKey("M54") .. '"},{"id": 204,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M53","value": "0.0.0"},{"id": 205,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M71","value": "'.. provider.getStatusValueByKey("M71") .. '"},{"id": 206,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M64","value": "'.. provider.getStatusValueByKey("M64") .. '"},{"id": 207,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M48","value": "2.3.0"},{"id": 208,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M50","value": "90.7.0"},{"id": 209,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M49","value": "2.6.0"},{"id": 210,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "M52","value": "2.7.0"},{"id": 211,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S03","value": "'.. provider.getStatusValueByKey("S03") .. '"},{"id": 212,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S13","value": "'.. provider.getStatusValueByKey("S13") .. '"},{"id": 213,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S07","value": "'.. provider.getStatusValueByKey("S07") .. '"},{"id": 214,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S08","value": "'.. provider.getStatusValueByKey("S08") .. '"},{"id": 215,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S20","value": "'.. provider.getStatusValueByKey("S20") .. '"},{"id": 216,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S15","value": "'.. provider.getStatusValueByKey("S15") .. '"},{"id": 217,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S18","value": "'.. provider.getStatusValueByKey("S18") .. '"},{"id": 218,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S17","value": "'.. provider.getStatusValueByKey("S17") .. '"},{"id": 219,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S16","value": "'.. provider.getStatusValueByKey("S16") .. '"},{"id": 220,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S02","value": "'.. provider.getStatusValueByKey("S02") .. '"},{"id": 221,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S09","value": "'.. provider.getStatusValueByKey("S09") .. '"},{"id": 222,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S19","value": "'.. provider.getStatusValueByKey("S19") .. '"},{"id": 223,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S14","value": "'.. provider.getStatusValueByKey("S14") .. '"},{"id": 224,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S04","value": "'.. provider.getStatusValueByKey("S04") .. '"},{"id": 225,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S01","value": "'.. provider.getStatusValueByKey("S01") .. '"},{"id": 226,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S10","value": "'.. provider.getStatusValueByKey("S10") .. '"},{"id": 227,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S27","value": "0.0"},{"id": 228,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S23","value": "'.. provider.getStatusValueByKey("S23") .. '"},{"id": 229,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S26","value": "'.. provider.getStatusValueByKey("S26") .. '"},{"id": 230,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S37","value": "'.. provider.getStatusValueByKey("S37") .. '"},'
    
local data_2 = '{"id": 231,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S22","value": "1"},{"id": 232,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S43","value": "'.. provider.getStatusValueByKey("S43") .. '"},{"id": 233,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S21","value": "'.. provider.getStatusValueByKey("S21") .. '"},{"id": 234,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S29","value": "TRUE"},{"id": 235,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S25","value": "0.0"},{"id": 236,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S49","value": "'.. provider.getStatusValueByKey("S49") .. '"},{"id": 237,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S47","value": "'.. provider.getStatusValueByKey("S47") .. '"},{"id": 238,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S28","value": "0.0"},{"id": 239,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S38","value": "'.. provider.getStatusValueByKey("S38") .. '"},{"id": 240,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S48","value": "'.. provider.getStatusValueByKey("S48") .. '"},{"id": 241,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S46","value": "'.. provider.getStatusValueByKey("S46") .. '"},{"id": 242,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S30","value": "'.. provider.getStatusValueByKey("S30") .. '"},{"id": 243,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S39","value": "'.. provider.getStatusValueByKey("S39") .. '"},{"id": 244,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S32","value": "'.. provider.getStatusValueByKey("S32") .. '"},{"id": 245,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S41","value": "100"},{"id": 246,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S66","value": "'.. provider.getStatusValueByKey("S66") .. '"},{"id": 247,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S56","value": "'.. provider.getStatusValueByKey("S56") .. '"},{"id": 248,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S52","value": "'.. provider.getStatusValueByKey("S52") .. '"},{"id": 249,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S62","value": "'.. provider.getStatusValueByKey("S62") .. '"},{"id": 250,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S57","value": "'.. provider.getStatusValueByKey("S57") .. '"},{"id": 251,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S53","value": "'.. provider.getStatusValueByKey("S53") .. '"},{"id": 252,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S63","value": "'.. provider.getStatusValueByKey("S63") .. '"},{"id": 253,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S64","value": "'.. provider.getStatusValueByKey("S64") .. '"},{"id": 254,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S54","value": "'.. provider.getStatusValueByKey("S54") .. '"},{"id": 255,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S60","value": "'.. provider.getStatusValueByKey("S60") .. '"},{"id": 0,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S50","value": "'.. provider.getStatusValueByKey("S50") .. '"},{"id": 1,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S69","value": "'.. provider.getStatusValueByKey("S69") .. '"},{"id": 2,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S55","value": "'.. provider.getStatusValueByKey("S55") .. '"},{"id": 3,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S58","value": "'.. provider.getStatusValueByKey("S58") .. '"},{"id": 4,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S65","'.. provider.getStatusValueByKey("S65") .. '": "2500"},{"id": 5,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S61","value": "'.. provider.getStatusValueByKey("S61") .. '"},{"id": 6,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S51","value": "'.. provider.getStatusValueByKey("S51") .. '"},{"id": 7,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S59","value": "'.. provider.getStatusValueByKey("S59") .. '"},{"id": 8,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S82","value": "'.. provider.getStatusValueByKey("S82") .. '"},{"id": 9,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S76","value": "'.. provider.getStatusValueByKey("S76") .. '"},{"id": 10,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S86","value": "'.. provider.getStatusValueByKey("S86") .. '"},{"id": 11,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S72","value": "'.. provider.getStatusValueByKey("S72") .. '"},{"id": 12,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S83","value": "'.. provider.getStatusValueByKey("S83") .. '"},{"id": 13,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S87","value": "'.. provider.getStatusValueByKey("S87") .. '"},{"id": 14,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S77","value": "'.. provider.getStatusValueByKey("S77") .. '"},{"id": 15,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S73","value": "'.. provider.getStatusValueByKey("S73") .. '"},{"id": 16,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S90","value": "TRUE"},{"id": 17,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S80","value": "'.. provider.getStatusValueByKey("S80") .. '"},{"id": 18,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S79","value": "'.. provider.getStatusValueByKey("S79") .. '"},{"id": 19,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S74","value": "'.. provider.getStatusValueByKey("S74") .. '"},{"id": 20,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S84","value": "'.. provider.getStatusValueByKey("S84") .. '"},{"id": 21,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S81","value": "'.. provider.getStatusValueByKey("S81") .. '"},{"id": 22,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S88","value": "'.. provider.getStatusValueByKey("S88") .. '"},{"id": 23,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S78","value": "'.. provider.getStatusValueByKey("S78") .. '"},{"id": 24,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S71","value": "'.. provider.getStatusValueByKey("S71") .. '"},{"id": 25,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S85","value": "'.. provider.getStatusValueByKey("S85") .. '"},{"id": 26,"service": "urn:psi-storage-com:serviceId:Battery1","variable": "S75","value": "'.. provider.getStatusValueByKey("S75") .. '"},{"id": 27,"service": "urn:upnp-org:serviceId:PSBatterie1","variable": "UdpDebugIp","value": "192.168.2.100"},{"id": 28,"service": "urn:upnp-org:serviceId:PSBatterie1","variable": "UdpDebugPort","value": "15001"},{"id": 29,"service": "urn:upnp-org:serviceId:PSBatterie1","variable": "UdpSbIp","value": "192.168.81.2"},{"id": 30,"service": "urn:upnp-org:serviceId:PSBatterie1","variable": "UdpSbIncomingPort","value": "1202"},{"id": 31,"service": "urn:upnp-org:serviceId:PSBatterie1","variable": "UdpSbOutgoingPort","value": "1203"},{"id": 32,"service": "urn:upnp-org:serviceId:PSBatterie1","variable": "SmartHomeUnitIp","value": "192.168.25.99"},{"id": 33,"service": "urn:upnp-org:serviceId:PSBatterie1","variable": "SmartHomeUnitPort","value": "1202"},{"id": 34,"service": "urn:upnp-org:serviceId:PSBatterie1","variable": "AutoSocket1","value": "0"},{"id": 35,"service": "urn:upnp-org:serviceId:PSBatterie1","variable": "AutoSocket2","value": "0"},{"id": 36,"service": "urn:upnp-org:serviceId:PSBatterie1","variable": "AutoSocket3","value": "0"},{"id": 37,"service": "urn:upnp-org:serviceId:PSBatterie1","variable": "OperatingMode","value": "'.. provider.getStatusValueByKey("M06") .. '"},{"id": 38,"service": "urn:upnp-org:serviceId:PSBatterie1","variable": "BatteryCapacity","value": "0040"},{"id": 39,"service": "urn:upnp-org:serviceId:PSBatterie1","variable": "SOC","value": "'.. provider.getStatusValueByKey("M05") .. '"},{"id": 40,"service": "urn:upnp-org:serviceId:PSBatterie1","variable": "InstalledPvPower","value": "5.04"}],"Jobs": [],"tooltip": {"display": 0},"status": -1},{"id": 4,"states": [],"Jobs": [],"tooltip": {"display": 0},"status": -1},{"id": 5,"states": [],"Jobs": [],"tooltip": {"display": 0},"status": -1},{"id": 6,"states": [],"Jobs": [],"tooltip": {"display": 0},"status": -1},{"id": 7,"states": [],"Jobs": [],"tooltip": {"display": 0},"status": -1},{"id": 8,"states": [],"Jobs": [],"tooltip": {"display": 0},"status": -1}],"LoadTime": 0,"DataVersion": 0,"UserData_DataVersion": 134946413,"TimeStamp": 1504190274,"ZWaveStatus": 1,"LocalTime": "2017-09-12 14:37:54 D"}'

        data = data_0 .. data_1..data_2
        
        
      elseif req.cmd_url == "/data_request?id=alive" then
        print("alive")
        data = "OK"
        
      elseif req.cmd_url == "/data_request?id=lr_devices" or req.cmd_url == "/data_request?id=lr_devices&output_format=json" or req.cmd_url == "/data_request?id=lr_device" then
        print("devices")
        data = '{"devices":[{"id":1,"name":"ZWave","type":"urn:schemas-micasaverde-com:device:ZWaveNetwork:1"},{"id":2,"name":"_Scene Controller","type":"urn:schemas-micasaverde-com:device:SceneController:1"},{"id":3,"name":"Sonnenbatterie #26355","type":"urn:schemas-psi-storage-com:device:Battery:1"},{"id":4,"name":"Photovoltaik 1","type":"urn:schemas-psi-storage-com:device:Photovoltaics:1"},{"id":5,"name":"Waermepumpe 1","type":"urn:schemas-psi-storage-com:device:Heatpump:1"},{"id":6,"name":"BHKW 1","type":"urn:schemas-psi-storage-com:device:CHP:1"},{"id":7,"name":"Gesamtverbauch 1","type":"urn:schemas-psi-storage-com:device:TotalConsumption:1"},{"id":8,"name":"Eigenverbrauchsrelais 1","type":"urn:schemas-psi-storage-com:device:OwnConsumptionRelay:1"}]}'
        
      end




-- data 
-- local data = data_0
-- local data = data_26802
-- print(data) 

      if data == nil then
        debug("Cant read Event Data.", 1)
        print("Cnat read data")
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
      response.content = "Status Server alive"
      
      
    elseif req.relpath == "/rest/delay" then
      delay = 5
      os.execute("sleep "..delay)
      response.status = "200 OK"
      response.content_type  = "text/plain"
      response.content = "Delay with "..delay.." seconds."
      
      
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

-- zweiter Server und ggf. echo Handler
copas.addserver(server, echoHandler)
copas.loop()



