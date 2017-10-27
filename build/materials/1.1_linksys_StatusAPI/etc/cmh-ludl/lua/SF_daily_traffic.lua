--- script SF_daily_traffic.lua 1.0
-- @author Dennis Thalmeier
-- @description: Script that sends the daily SF traffic to sb-server to record the battery traffic

--- Constants
  local let_ping_url = "meine.sonnenbatterie.de"
  local let_heartbeat_public_ip_URL = "https://meine.sonnenbatterie.de/heartbeat?origin=1&serial=" -- url of server batteryID, sfID will be added like the followoing example https://meine-dev.sonnenbatterie.de/heartbeat?origin=1&serial="BatterySerial"
  local let_heartbeat_vpn_URL = "https://meine.sonnenbatterie.de/heartbeat?origin=1&serial=" -- url of server
	local let_allhttp_devices_URL = "curl -q -s -S -k --connect-timeout 5  -m 7 'http://127.0.0.1:49451/data_request?id=lr_devices'" -- url of all devices registered sf
	local let_EatonPanel_IP = "192.168.81.2" -- IP to send Ping to the panel 
  --local let_delay_file_path = "/tmp/heartbeat_rnd_delay"

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
	 
 ---function that provides a sleep time for n seconds; safes the sleep delay to temporary file
func_sleep = function(n)
  
  os.execute("sleep " .. tonumber(n))

end

---function get send/received data 
get_traffic = function()
local reval = ""
  if get_popen_value("ifconfig | grep eth0.1") ~= "" then
    local strRequestvalue0 = get_popen_value("ifconfig eth0.1 | grep \"RX bytes\" | sed \"s/^.*RX bytes:\([0-9]\+\).*TX bytes:\([0-9]\+\).*$/\1 \2/\"")
        print(strRequestvalue0)
        retval = strRequestvalue0
  else
    local strRequestvalue1 = get_popen_value("ifconfig eth0.2 | grep \"RX bytes\" | sed \"s/^.*RX bytes:\([0-9]\+\).*TX bytes:\([0-9]\+\).*$/\1 \2/\"")
        print(strRequestvalue1)
        retval = strRequestvalue1
  end
  retval = (retval:gsub(" ", ""))
  return retval
end
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
	
getBatteryID = function ()
    
-- Call localhost for Device information and write the information into string file
local str_httpAllDevices = get_popen_value(let_allhttp_devices_URL)

-- parse string file for device id 

local deviceList = JSON:decode(str_httpAllDevices) -- JSON:decode(str_httpAllDevices)
      
-- get list of devices from json
local devices = deviceList["devices"]
local count_sb_devices = 0     
local idhelper = nil
local namehelper = "1"

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

local str_batteryName = getUserName()
str_batteryName = (str_batteryName:gsub("^%s*(.-)%s*$", "%1"))
  if str_batteryName == "" then
    str_batteryName = namehelper
  end
  return str_batteryName
end

 sendEvent = function()
      local str_sfID = get_popen_value("hostname | grep -o -E '[0-9]+'")
      str_sfID = string.gsub(str_sfID, "\n", "")
      ---https://meine.sonnenbatterie.de/eventlog/xyz/111111/128
      --local str_callEventUrl = "https://meine.sonnenbatterie.de/eventlog/"..self.serial.."/"..str_sfID.."/129"
      local str_callEventUrl = "https://meine-dev2.sonnenbatterie.de/eventlog/"..getBatteryID().."/"..str_sfID.."/129?note="..get_traffic().." "
      local http_SF_timeout_Result = get_popen_value("curl --silent -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
      print(str_callEventUrl)
      print("EventResult "..http_SF_timeout_Result)
  end
  ---- Main ----

main = function()
  
---- Setup ----
JSON = require ("JSON") -- one-time load of the routines
get_traffic()

local str_sfID = get_popen_value("hostname | grep -o -E '[0-9]+'")
str_sfID = string.gsub(str_sfID, "\n", "")
print(str_sfID)

local str_batteryID = getBatteryID()
print("BatteryName: "..str_batteryID)

-- luup.log("Send Alarm 129")
sendEvent()


end

main()