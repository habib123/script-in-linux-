--- script sf_sps_heartbeat.lua 1.01
-- @author Dennis Thalmeier
-- @description Script that sends a heartbeat signals to a server, and checks validData timestamp. If the timestamp is older than 300 sec a ping will be send to the eaton panel. If the panel is offline event 600 url will be called, if the panel is online and the timestamp is older than 300 s event 601 will be called, if lastValidData is not valid (-1) and this contiction is true for more than 20 min event 602, if there are multiple plugin devics installed event 603 will be called; if theres a problem with the lua startup or engine the Event 604 will be called

--- ChangeLog
-- 01.07.2016   Fixed LuaStartup Failed Bug  
-- 05.09.2016   Added G150 support

--- Constants
  local let_ping_url = "meine.sonnenbatterie.de"
  local let_heartbeat_public_ip_URL = "https://meine.sonnenbatterie.de/heartbeat?origin=1&serial=" -- url of server batteryID, sfID will be added like the followoing example https://meine-dev.sonnenbatterie.de/heartbeat?origin=1&serial="BatterySerial"
  local let_heartbeat_vpn_URL = "https://meine.sonnenbatterie.de/heartbeat?origin=1&serial=" -- url of server
	local let_allhttp_devices_URL = "curl -q -s -S -k --connect-timeout 5  -m 7 'http://127.0.0.1/port_49451/data_request?id=lr_devices'" -- url of all devices registered sf
	local let_EatonPanel_IP = "192.168.81.2" -- IP to send Ping to the panel 
  local let_delay_file_path = "/tmp/heartbeat_rnd_delay"

--- Functions ---
--- Function that performs a terminal command and gives back the result as a string value
	-- @param string terminal command
	-- @return string return value 
	get_popen_value = function(inval)
		local file_retval =  io.popen(inval)
    local str_retval = file_retval:read("*a")
    file_retval:close()

		return str_retval
	end


--- Splits inputstr by sep
-- splits the assigned string (inputstr) by the assigned seperator (sep).
-- @param inputstr The string to split
-- @param sep The seperator to use
-- @return Returns a table with the split string
split = function(inputstr, sep)
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

--- safes array Data to specific directory
-- @param path where Data should be safed, inputArrayData
safeEventDataArray = function(filePath, inputArray)
  
  local newf=io.open(filePath,"w")
    newf:write(inputArray[1].."\t"..inputArray[2].."\t"..inputArray[3])
    io.close(newf) 
  
end

--- creates an array containing all data form given path
-- @param path where event files are located
-- @return Returns an array containing all data
getEventDataArray = function(path)
 
  local filePath = path 
  local content
  -- check if file exists
  local f = io.open(filePath,"r")
    if f ~= nil then 
      -- file exists; split data
      content = f:read("*all")
      f:close()
      
      -- convert content string into content array seperated by tab
      content = split(content, "\t")
      
      
      -- convert string data (timestamp, key)to number
      content[1] = tonumber(content[1])
      content[2] = tonumber(content[2])
      content[3] = tonumber(content[3])
      
      -- nil check
      
      if content[1] == nil or content[2] == nil or content[3] == nil then
        print("nil check called")
        math.randomseed(os.time())
        content[1] = math.random (290)
        content[2] = 0
        content[3] = 1
      end
      
      
      if content[1] > 0 and content[1] < 291 then
        print ("readed waiting time in seconds:" ..content[1])
      else
        math.randomseed(os.time())
        n = math.random (290)
        print ("readed waiting time not ok; generating new:" ..n)
        content[1] = n
      end
      
  else 
    -- file does no exist; create file and safe delay time
    os.execute("touch "..filePath)
    local newf=io.open(filePath,"w")
      math.randomseed(os.time())
      n = math.random (290)
    local default = {n, 0, 1}
    newf:write(default[1].."\t"..default[2].."\t"..default[3])
    io.close(newf) 
    print ("delay file created; waiting time:" ..n)
    
    local f = io.open(path, "r")
    content = f:read("*all")
    f:close()
    
    -- convert content string into content array seperated by tab
    content = split(content, "\t")
    
    -- convert string data (timestamp, key)to number
    content[1] = tonumber(content[1])
    content[2] = tonumber(content[2])
    content[3] = tonumber(content[3])
  
  end
  
  return content

end
	-- static function isServerReachable
	--- Checks if "serverString" is reachable
	-- @param serverString Url of the server to check reachability
	-- @return true is reachable else false 
	isServerReachable = function (serverString)
		local retval = false
		
		--handle = io.popen("ping -c1 -q -4 -W1 -w1 "..serverString.."  >/dev/null 2>&1 ; echo $?")
		local inetConnection = get_popen_value("ping -c1 -q -4 -W1 -w1 "..serverString.."  >/dev/null 2>&1 ; echo $?") 
    --handle:read("*a")
		--handle:close()
		
		if tonumber(inetConnection) == 0 then
			retval = true
			print(""..serverString.." is reachable", 02)
		else
			print(""..serverString.." is not reachable", 02)
		end
		
		return retval	
	end
	
---function heartbeat that checks serverconnection and sends alive signal
  func_heartbeat = function(in_heartbeat_url, in_batteryID, in_sfID, in_sfStatus)
  local retval = false
    if isServerReachable(let_ping_url) then
      print("curl --silent -q -s -S -k --connect-timeout 5  -m 7 '"..in_heartbeat_url..""..in_batteryID.."&sf_serial="..in_sfID.."&sf_statusOK="..in_sfStatus.."'")
      local strRequestvalue = get_popen_value("curl --silent -q -s -S -k --connect-timeout 5  -m 7 '"..in_heartbeat_url..""..in_batteryID.."&sf_serial="..in_sfID.."&sf_statusOK="..in_sfStatus.."'")
      print(strRequestvalue)
      retval = true
    end
    return retval
  end
 
 
 
 ---function that provides a sleep time for n seconds; safes the sleep delay to temporary file
func_sleep = function(n)
  
  os.execute("sleep " .. tonumber(n))

end

---function get send/received data 
--func_get_traffic = function()

--  if get_popen_value("ifconfig | grep eth0.1") ~= "" then

--    local strRequestvalue = get_popen_value("ifconfig eth0.1 | grep \"RX bytes\" | sed \"s/^.*RX bytes:\([0-9]\+\).*TX bytes:\([0-9]\+\).*$/\1 \2/\"")
--        print(strRequestvalue)
--  else
--    local strRequestvalue2 = get_popen_value("ifconfig eth0.2 | grep \"RX bytes\" | sed \"s/^.*RX bytes:\([0-9]\+\).*TX bytes:\([0-9]\+\).*$/\1 \2/\"")
--        print(strRequestvalue2)
--  end
--end

--- Reads the username of the smartfunction from "/etc/cmh/users.conf"
-- @return Returns the username
getUserName = function ()
  -- read username from /etc/cmh/users.conf
  handle = io.popen("cat /etc/cmh/users.conf | grep -E '^[a-z,A-Z]{3}[0-9]{2,}' | cut -d'=' -f 1")
  local psbnr = handle:read("*a")
  
  -- if users.conf doesnt contain a serialnumber we will take the serialnumber exported by the plc
  -- if this exportvalue is empty we take 1 as serialnumber
  if psbnr == "" or psbnr == nil  or string.len(psbnr) > 10 then
    local f = io.popen("curl --silent http://127.0.0.1:7979/rest/devices/battery/S15", 'r')
    local updSerialNumber = f:read("*a")
    if updSerialNumber == "" or updSerialNumber == nil then
      psbnr = "1"
    else
      psbnr = updSerialNumber
    end
  else
    psbnr = string.sub(psbnr, 4)
  end
  
  handle:close()
		
	return psbnr
end
	


  ---- Main ----

main = function()
  
  
  ---- Setup ----
  
--func_get_traffic()

JSON = require ("JSON") -- one-time load of the routines
--print("banana")

-- check if file rnd_delay_heartbeat is avaliable; if not create new file with default values
-- wait random time between 0 and 290 seconds to make sure that the heartbeat signals will not send at the same time

local statusDataArray = {}
statusDataArray = getEventDataArray(let_delay_file_path)
func_sleep(statusDataArray[1])

-- Call localhost for Device information and write the information into string file
local str_httpAllDevices = get_popen_value(let_allhttp_devices_URL)

-- parse string file for device id 

local deviceList = JSON:decode(str_httpAllDevices) -- JSON:decode(str_httpAllDevices)
      
-- get list of devices from json
local devices = deviceList["devices"]
local count_sb_devices = 0     
local idhelper = nil
local namehelper = "1"
-- get id for battery device 
for i, device in pairs(devices) do
  
  if device["type"] == "urn:schemas-psi-storage-com:device:Battery:1" then
    
    str_batteryID = device["id"]
    count_sb_devices = count_sb_devices + 1
    local name = device["name"]
    --print("\n")
    name = string.gsub(name, " ", "")
    print(string.sub(name, 16))
    --check if correct device number avaliabel and take this device
    if tonumber(string.sub(name, 16)) + 1 > 1 then
      idhelper = device["id"]
      namehelper = string.sub(device["name"], 16)
      namehelper = string.gsub(namehelper, " ", "")
    end
    
    if idhelper ~= nil then
      str_batteryID = idhelper
    end
  end
end

print("SB-DeviceCount: "..count_sb_devices)

--print(batteryID)
local str_sfID = get_popen_value("nvram get vera_serial")
str_sfID = string.gsub(str_sfID, "\n", "")

local str_batteryName = getUserName()
str_batteryName = (str_batteryName:gsub("^%s*(.-)%s*$", "%1"))
if str_batteryName == "" then
  str_batteryName = namehelper
end
print("BatteryName: "..str_batteryName)

-- Call localhost for LastValidData and write the information into string file

local str_lastValidData = get_popen_value("curl --silent -q -s -S -k --connect-timeout 5  -m 7 'http://127.0.0.1:3480/data_request?id=variableget&DeviceNum="..str_batteryID.."&serviceId=urn:psi-storage-com:serviceId:Battery1&Variable=LastValidData'")

---- heartbeat ----

-- Call heartbeat function with public ip to send alive signal to server
if func_heartbeat(let_heartbeat_public_ip_URL, str_batteryName, str_sfID, statusDataArray[3])== false then
    print ("heartbeat public failed")
    else print("heartbeat public success")
end

-- Call heartbeat function with public ip to send alive signal to server
-- if func_heartbeat(let_heartbeat_vpn_URL, str_batteryName, str_sfID)== false then
--    print ("heartbeat vpn failed")
--    else print("heartbeat vpn success")
--end

-- check device number; send event if device count is incorrect

if (count_sb_devices == 0 or count_sb_devices > 1) then
        print("more than 1 device")
        -- send plugin error event

        local str_callEventUrl = "https://meine.sonnenbatterie.de/eventlog/"..str_batteryName.."/"..str_sfID.."/603?note=multipleSB_Devices&entity_id="..str_batteryID.."&timestamp="..os.time()..""
        print("curl --silent -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
        local http_SF_timeout_Result = get_popen_value("curl --silent -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
        print(http_SF_timeout_Result)
        statusDataArray[3] = 0
        safeEventDataArray(let_delay_file_path, statusDataArray)
        return
      end
      
      
-- If SPS is not reachable for more then 5 minutes 
  if os.time() - str_lastValidData > 300 then
      
      -- delay time
      local int_lost_time = os.time() - str_lastValidData
      
      print ("callSPSLostEvent_validData_timeout: "..int_lost_time)
      
      -- g150 support for firewall.restart
      
      get_popen_value("/etc/init.d/firewall restart")
      
      -- if (lastValidData == -1 AND time lastValidData -1 > 15 MIN) OR DeviceNumber > 1 OR DeviceNumber 0 --> luaStartupFailed fo m --> send Event "PlugInProblem possible"
      
    if (str_lastValidData + 1 == 0) then
        statusDataArray[2] = statusDataArray[2] + 1
        print ("lastValidData -1 error count: "..statusDataArray[2])
        print("safe")
        safeEventDataArray(let_delay_file_path, statusDataArray)
        
        -- check time lastValidData == -1 if time > 20 Min
      if (statusDataArray[2] > 3 and isServerReachable(let_EatonPanel_IP)) then
        
        
        ---- SF Error handling ----
        
        -- print(get_popen_value("curl --silent http://localhost:3480/data_request?id=status  | grep -o  'Startup Lua Failed'"))
        
        if (get_popen_value("curl --silent http://localhost:3480/data_request?id=status  | grep -o  'Startup Lua Failed'")) ~= "" then
          print("error Startup lua failed")
          -- send Lua Engine failed to load error event
          local str_callEventUrl = "https://meine.sonnenbatterie.de/eventlog/"..str_batteryName.."/"..str_sfID.."/604?note=StartupLuaFailed&entity_id="..str_batteryID.."&timestamp="..os.time()..""
          print("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
          local http_SF_timeout_Result = get_popen_value("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
          print(http_SF_timeout_Result)
          
          
          -- print(get_popen_value("curl --silent http://localhost:3480/data_request?id=status  | grep -o  'Lua Engine failed to load'"))
          
        elseif (get_popen_value("curl --silent http://localhost:3480/data_request?id=status  | grep -o  'Lua Engine failed to load'")) ~= "" then
          print("error Lua Engine failed to load")
          -- send Lua Engine failed to load error event
          local str_callEventUrl = "https://meine.sonnenbatterie.de/eventlog/"..str_batteryName.."/"..str_sfID.."/604?note=LuaEngineFailedToLoad&entity_id="..str_batteryID.."&timestamp="..os.time()..""
          print("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
          local http_SF_timeout_Result = get_popen_value("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
          print(http_SF_timeout_Result)
          
        else
          
          --  send Event lua Startup Failed -> PluginProblem 
          local str_callEventUrl = "https://meine.sonnenbatterie.de/eventlog/"..str_batteryName.."/"..str_sfID.."/602?note=UnknownPluginProblem&entity_id="..str_batteryID.."&timestamp="..os.time()..""
          print("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
          local http_SF_timeout_Result = get_popen_value("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
          print(http_SF_timeout_Result)
          
        end
        
        --- if lastValid Data == -1 && SPS PING == false --- 
        
      elseif (statusDataArray[2] > 3 and isServerReachable(let_EatonPanel_IP) == false) then
        print ("callSPSLostEvent_Ping_timeout") 
          
        local str_callEventUrl = "https://meine.sonnenbatterie.de/eventlog/"..str_batteryName.."/"..str_sfID.."/600?note="..str_lastValidData.."&entity_id="..str_batteryID.."&timestamp="..os.time()..""
        print("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
        local http_SPSLost_Result = get_popen_value("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
        print(http_SPSLost_Result)
      end
      return
    end
      
      --Ping sps before sending event
      
    if isServerReachable(let_EatonPanel_IP) == false then
        print ("callSPSLostEvent_Ping_timeout") 
          
        local str_callEventUrl = "https://meine.sonnenbatterie.de/eventlog/"..str_batteryName.."/"..str_sfID.."/600?note="..int_lost_time.."&entity_id="..str_batteryID.."&timestamp="..os.time()..""
        print("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
        local http_SPSLost_Result = get_popen_value("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
        print(http_SPSLost_Result)
        
      else 
        print("SPS ping ok")
          
        if (get_popen_value("curl --silent http://localhost:3480/data_request?id=status  | grep -o  'Startup Lua Failed'")) ~= "" then
          print("error Startup lua failed")
          -- send Lua Engine failed to load error event
          local str_callEventUrl = "https://meine.sonnenbatterie.de/eventlog/"..str_batteryName.."/"..str_sfID.."/604?note=StartupLuaFailed&entity_id="..str_batteryID.."&timestamp="..os.time()..""
          print("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
          local http_SF_timeout_Result = get_popen_value("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
          print(http_SF_timeout_Result)
          
          
          -- print(get_popen_value("curl --silent http://localhost:3480/data_request?id=status  | grep -o  'Lua Engine failed to load'"))
          
        elseif (get_popen_value("curl --silent http://localhost:3480/data_request?id=status  | grep -o  'Lua Engine failed to load'")) ~= "" then
          print("error Lua Engine failed to load")
          -- send Lua Engine failed to load error event
          local str_callEventUrl = "https://meine.sonnenbatterie.de/eventlog/"..str_batteryName.."/"..str_sfID.."/604?note=LuaEngineFailedToLoad&entity_id="..str_batteryID.."&timestamp="..os.time()..""
          print("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
          local http_SF_timeout_Result = get_popen_value("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
          print(http_SF_timeout_Result)
          
        else
          
          -- call ping OK validData timeout Event
          local str_callEventUrl = "https://meine.sonnenbatterie.de/eventlog/"..str_batteryName.."/"..str_sfID.."/601?note="..int_lost_time.."&entity_id="..str_batteryID.."&timestamp="..os.time()..""
          print("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
          local http_SPSLost_Result = get_popen_value("curl -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
          print(http_SPSLost_Result)
          
        end
      end 
      statusDataArray[3] = 0
      safeEventDataArray(let_delay_file_path, statusDataArray)
  else
    print("everything is fine")
    -- reset lastValidDataErrorCount and set sps-Status ok  
    statusDataArray[2] = 0
    statusDataArray[3] = 1
    safeEventDataArray(let_delay_file_path, statusDataArray)
  end

end

main()