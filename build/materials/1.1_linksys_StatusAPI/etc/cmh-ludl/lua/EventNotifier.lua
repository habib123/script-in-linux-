--- Static Class EventNotifier
-- @author Christian Rothaermel
-- @class EventNotifier
-- @description EventNotifier send events to the server and to the smarthomeunit. If sending fails events are logged to "/tmp/prosol/events/sh" and "/tmp/prosol/events/srv" and will be resend.

EventNotifier=
{
	SONNENBATTERIE_URL="https://meine.sonnenbatterie.de/eventlog/", -- url of server
	PATH_EVENT_FOLDER = "/tmp/prosol/events", -- folder of events
	PATH_EVENT_SRV_FOLDER = "/tmp/prosol/events/srv", -- folder of events for srv
	PATH_EVENT_SH_FOLDER = "/tmp/prosol/events/sh", -- folder of events for sh
  PATH_EVENT_TMP_FOLDER = "/tmp/prosol/events/tmp",
  PATH_EVENT_TRANSMIT_FOLDER = "/tmp/prosol/events/transmit",
  
  STATIC_HASH = {},
	CURRENT_DAY = os.date("%d"), -- Date of current day
	COUNTER_OP_MODE_CHANGES = 0 , -- counter for operation mode changes of battery system
	TIMESTAMP_OP_MODE_CHANGED = os.time(), -- timestamp of last operation mode change
	SECONDS_OF_36_HOURS = (60*60*36), -- 36 hours in seconds
	TO_MANY_OP_MODE_CHANGES = 10 + 1, -- if number of operation mode changes reaches TO_MANY_OP_MODE_CHANGES an event is sent once
  USERNAME = nil,
  SERIAL_NUMBER = nil,
	
	
	DELETE_FILES_BEFORE = (60 * 60 * 24 * 7), -- files that are older than 7 days will be deleted
	
	MAX_FILE_SIZE = 1024 * 512, -- 512 kb
	

	-- AUX_FUNCTIONS
  InitStaticHash = function(lul_device)
    luup.log("EventNotifier ID:"..lul_device)
    local id = lul_device
    local url = "http://127.0.0.1/port_3480/data_request?id=lu_status&DeviceNum="..id
    local http=require'socket.http'
    local test = http.request(url)


    j= require ("lua.JSON")

    local deviceList = j:decode(test)
    local device = deviceList["Device_Num_"..id]
    local states = device["states"]
    
    for i, state in pairs(states) do
      if string.match(state["variable"], '^[A-Z][0-9][0-9]') then
        EventNotifier.STATIC_HASH[state["variable"]] = state["value"]
      end
    end
    
    for i, v in pairs(EventNotifier.STATIC_HASH) do
      luup.log("EventNotifier StaticHash: "..i..":"..v)
    end
    
  end,
  

	-- static function urlencode
	--- Encode the assigned url
	-- @param str String that contains the url to encode
	-- @return Returns the encoded url as string
	UrlEncode = function (str)
	  if (str) then
	    str = string.gsub (str, "\n", "\r\n")
	    str = string.gsub (str, "([^%w ])",
	    function (c) return string.format ("%%%02X", string.byte(c)) end)
	    str = string.gsub (str, " ", "+")
	  end
    return str    
	end,
	
		

	-- static function GetUserName
	--- Reads the username of the smartfunction from "/etc/cmh/users.conf"
	-- @return Returns the username
	GetUserName = function ()
		-- read username from /etc/cmh/users.conf
		handle = io.popen("cat /etc/cmh/users.conf | grep -E '^[a-z,A-Z]{3}[0-9]{2,}' | cut -d'=' -f 1")
		local psbnr = handle:read("*a")
		
    -- if users.conf doesnt contain a serialnumber we will take the serialnumber exported by the plc
    -- if this exportvalue is empty we take 1 as serialnumber
		if psbnr == "" or psbnr == nil or string.len(psbnr) > 10 then
      local updSerialNumber = EventNotifier.STATIC_HASH["S15"]
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
	end,
	
	
	
	-- static function GetSerialNumber
	--- Reads the serialnumber of the smartfunction
	-- @return Returns the serialnumber
	GetSerialNumber = function()
		-- read serial nummer
		handle = io.popen("hostname | grep -o -E '[0-9]+'")
		local sfid = handle:read("*a")
		handle:close()
		return sfid	
	end,
	
	
	
	-- static function IsServerReachable
	--- Checks if "serverString" is reachable
	-- @param serverString Url of the server to check reachability
	-- @return true is reachable else false 
	IsServerReachable = function (serverString)
		local retval = false
		
		handle = io.popen("ping -c1 -q -4 -W1 -w1 "..serverString.."  >/dev/null 2>&1 ; echo $?")
		local inetConnection = handle:read("*a")
		handle:close()
		
		if tonumber(inetConnection) == 0 then
			retval = true
			luup.log(""..serverString.." is reachable", 02)
		else
			luup.log(""..serverString.." is not reachable", 02)
		end
		
		return retval	
	end,
	
	
	
	
	-- static function CreateSmartHomeUrl
	--- Creates an url with the assigned parameters
	-- @param serverName url of the server
	-- @param eventCode Code of the event to send
	-- @param oldValue The old value
	-- @param newValue The new value
	-- @param entityId Id of the entity
	-- @param note The note
	-- @param timeStamp Timestamp when the event was risen
	-- @param lul_device Id of the battery device
	CreateUrl = function(serverName, eventCode, oldValue, newValue, entityId, note, timeStamp, lul_device)
		
		-- WINDOWS DEBUG
		-- local username = "3248"
		-- local serialnumber = "30101322"
		-- /WINDOWS DEBUG

    if EventNotifier.USERNAME == nil then
      EventNotifier.USERNAME = EventNotifier.GetUserName()
    end
  
		if EventNotifier.SERIAL_NUMBER == nil then
      EventNotifier.SERIAL_NUMBER = EventNotifier.GetSerialNumber()
    end		
    
		local baseurl = serverName..tonumber(EventNotifier.USERNAME).."/"..tonumber(EventNotifier.SERIAL_NUMBER).."/"
		
		if eventCode ~= nil and eventCode ~= "" then
			baseurl = baseurl..tonumber(eventCode)
		else
			return nil
		end
		
		if oldValue == nil then
			oldValue = ""
		end
		
		if newValue == nil then
			newValue = ""
		end
		
		if entityId == nil then
			entityId = ""
		end
		
		if note == nil then
			note = ""
		end
		
		if timeStamp == nil then
			timeStamp = ""
		end
		
		baseurl = baseurl.."?old="..EventNotifier.UrlEncode(oldValue).."&new="..EventNotifier.UrlEncode(newValue).."&entity_id="..EventNotifier.UrlEncode(entityId).."&note="..EventNotifier.UrlEncode(note).."&timestamp="..timeStamp
		
		return baseurl
	end,
	-- END AUX_FUNCTIONS
	
	
	
	-- static function TransmitFailesEvents
	--- Transmits failes events to the server 
	-- @param path Path to the logfile of events transmit failed
	TransmitFailedEvents = function(path)			
		
		local oldPath = path.."/TransmitFailed.log"
		local newPath = path.."/_TransmitFailed.log"
		
		if Utils.FileExists(oldPath) then
			os.rename(oldPath, newPath)
	
			for line in io.lines(newPath) do
        local tmp = Utils.Split(line, "\t")
        local timeStamp = tmp[1]
        local url = tmp[2]
        
        -- try to transmit 
        local transmitSucceded = EventNotifier.SendHttpsRequest(url)
        
		    if transmitSucceded then
					EventNotifier.WriteToLog(timeStamp, url, path.."/"..os.date("%Y-%m-%d", tonumber(timeStamp))..".log" )
					luup.log("Retransmit successful", 02)				
				else
					EventNotifier.WriteToLog(timeStamp, url, oldPath)
					luup.log("Retransmit failed", 02)
				end
		    	
			end
			
			os.remove(newPath)
		end
	end,
	
	
	
	-- static function SendHttpsRequest
	--- Calls the assinged url
	-- @param baseurl The url to call
	-- @return True if http get successful else false
	SendHttpsRequest = function(baseurl)
    
    
    local retval = true
    
    luup.log("Send request...", 02)
    luup.log("URL: "..baseurl, 02)
    
    local returnCode = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..baseurl.."'")
    
    luup.log("Request sent.", 02)
    
		-- if returnCode == 200 call done successfully
		if returnCode == nil or tonumber(returnCode) ~= 0 then
      if returnCode == nil then returnCode = "NIL" end
      luup.log("Request failed: "..returnCode, 02)
			retval = false
		end
		
		return retval	
    
	end,
	
	
	
	
	-- static function WriteToLog
	--- Writes the "timeStamp" and the "baseUrl" to "filePathName"
	-- @param timeStamp Timestamp to log
	-- @param baseUrl Url to log
	-- @param filePathName Where to log 
	WriteToLog = function(timeStamp, baseUrl, filePathName)
		
		-- open file in append mode filename like: 2013-07-15.csv
		local file = io.open(filePathName, "a+")
		
		if string.find(filePathName, "TransmitFailed") ~= nil then
			local size = file:seek("end")
			if size > EventNotifier.MAX_FILE_SIZE then
				-- close file
				file:close()
				
				-- do backup
				os.execute("mv "..filePathName.." "..string.gsub(filePathName, ".log", ".bak"))
				
				-- reopen file
				file = io.open(filePathName, "a+")
			end
		end
		
		-- write content to file
		file:write(timeStamp)
		file:write("\t")
		file:write(baseUrl)	
		file:write("\n")	
		
		-- close file
		file:close()
		
	end,
	
	
	
	
	-- static function NotifyEvent
	--- Checks is the server is reachable and send the events. If server is not reachable the events are logged
	-- @param eventList Table of events to send
	NotifyEvent = function (eventList)	
		
		os.execute("mkdir -p "..EventNotifier.PATH_EVENT_SH_FOLDER)
		os.execute("mkdir -p "..EventNotifier.PATH_EVENT_SRV_FOLDER)
		
		
		-- delete old files
		Utils.DeleteFilesBefore(EventNotifier.PATH_EVENT_SRV_FOLDER.."/", "%d%d%d%d%-%d%d%-%d%d%.log", (os.time() - (EventNotifier.DELETE_FILES_BEFORE) ))
		Utils.DeleteFilesBefore(EventNotifier.PATH_EVENT_SH_FOLDER.."/", "%d%d%d%d%-%d%d%-%d%d%.log", (os.time() - (EventNotifier.DELETE_FILES_BEFORE) ))
		
		-- get current time
		local timestamp = os.time()
		
		-- check if server is reachable
		local serverIsReachable = EventNotifier.IsServerReachable("meine.sonnenbatterie.de")
		
		if serverIsReachable then
			
			-- transmit failed events
			EventNotifier.TransmitFailedEvents(EventNotifier.PATH_EVENT_SRV_FOLDER)
      
			
			for key,event in pairs(eventList) do 
				-- create url for sonnenbatterie server
        
				local sonnenbatterieUrl = EventNotifier.CreateUrl(EventNotifier.SONNENBATTERIE_URL, event.code, event.oldValue, event.newValue, event.entityId, event.note, timestamp)
        
				local transmitToSonnenbatterieSucceded = EventNotifier.SendHttpsRequest(sonnenbatterieUrl)
			
				-- if transmition to sonnenbatterie server succeded write url to log, else write to sendtoserverlog
				if transmitToSonnenbatterieSucceded then
					luup.log("Transmit to Server successful.", 02)					
					EventNotifier.WriteToLog(timestamp, sonnenbatterieUrl, EventNotifier.PATH_EVENT_SRV_FOLDER.."/"..os.date("%Y-%m-%d", tonumber(timestamp))..".log")
				else
					luup.log("Transmit to Server failed.", 02)
					EventNotifier.WriteToLog(timestamp, sonnenbatterieUrl, EventNotifier.PATH_EVENT_SRV_FOLDER.."/".."TransmitFailed.log")
				end
				
			end

		else
			for key,event in pairs(eventList) do			
				-- create url for sonnenbatterie server
				local sonnenbatterieUrl = EventNotifier.CreateUrl(EventNotifier.SONNENBATTERIE_URL, event.code, event.oldValue, event.newValue, event.entityId, event.note, timestamp)
				
				EventNotifier.WriteToLog(timestamp, sonnenbatterieUrl, EventNotifier.PATH_EVENT_SRV_FOLDER.."/".."TransmitFailed.log")				
			end			
		end
		
		
		-- events to smarthome
		-- local smartHomeUnitIp = luup.variable_get("urn:upnp-org:serviceId:PSBatterie1","SmartHomeUnitIp", lul_device)
    luup.log("Send to SmartHome.", 02)
		local smartHomeUnitIp = "192.168.174.3"
		
		if smartHomeUnitIp ~= nil then
			local smartHomeIsReachable = EventNotifier.IsServerReachable(smartHomeUnitIp)
			
			if smartHomeIsReachable then
				-- transmit failed events
				EventNotifier.TransmitFailedEvents(EventNotifier.PATH_EVENT_SH_FOLDER)
				
				for key,event in pairs(eventList) do
					-- create url for smarthomeunit
					local smartHomeUnitUrl = EventNotifier.CreateUrl(smartHomeUnitIp.."/eventlog/", event.code, event.oldValue, event.newValue, event.entityId, event.note, timestamp)
					
					local transmitToSmartHomeSucceded = EventNotifier.SendHttpsRequest(smartHomeUnitUrl)
					
					-- if transmition to smarthomeunit succeded write url to log, else write to TransmitFailes_sh.log
					if transmitToSmartHomeSucceded then
						luup.log("Transmit to SmartHomeUnit successful.", 02)
						EventNotifier.WriteToLog(timestamp, smartHomeUnitUrl, EventNotifier.PATH_EVENT_SH_FOLDER.."/"..os.date("%Y-%m-%d", tonumber(timestamp))..".log")
					else
						luup.log("Transmit to SmartHomeUnit failed.", 02)
						EventNotifier.WriteToLog(timestamp, smartHomeUnitUrl, EventNotifier.PATH_EVENT_SH_FOLDER.."/".."TransmitFailed.log")
					end
				end 
				
			else
				for key,event in pairs(eventList) do
					-- create url for smarthomeunit
					local smartHomeUnitUrl = EventNotifier.CreateUrl(smartHomeUnitIp.."/eventlog/", event.code, event.oldValue, event.newValue, event.entityId, event.note, timestamp)
									
					EventNotifier.WriteToLog(timestamp, smartHomeUnitUrl, EventNotifier.PATH_EVENT_SH_FOLDER.."/".."TransmitFailed.log")
				end
			end
			
		end
			
	end,
	
	
	
	-- static function CheckForSettingChanges
	--- Checks if settings has changed and creates an event 
	-- @param hash Hash of current settings
	-- @return Table of events
	CheckForSettingsChanges = function (hash)
	
		local retval = {}
		
		for variable, value in pairs(hash) do 	
			if string.sub(variable, 1, 1) == "S" then
				if hash[variable] ~= EventNotifier.STATIC_HASH[variable] then
					local event = {}
					event.old = EventNotifier.STATIC_HASH[variable]
					event.new = hash[variable]
					event.variable = variable
					table.insert(retval, event)
				end
			end
			
    end
    return retval
	end,
	
	
	
	-- static function CopyData
	--- Copies the current settings to "STATIC_HASH"
	-- @param hash Hash of current settings
	CopyData = function (hash)
		for variable, value in pairs(hash) do 
      EventNotifier.STATIC_HASH[variable] = value
    end
	end,
	
	
	
	-- static function CreateEvent(eventCode, oldValue, newValue, entitiyId, note, lulDevice)
	--- Creates an event with assigned parameters
	-- @param eventCode Code of the event to send
	-- @param oldValue The old value
	-- @param newValue The new value
	-- @param entityId Id of the entity
	-- @param note The note
	-- @param lulDevice Id of the battery device
	-- @return The created event
	CreateEvent = function (eventCode, oldValue, newValue, entityId, note, lulDevice)
		local event ={}
		event.code = eventCode
		event.oldValue = oldValue
		event.newValue = newValue
		event.entityId = entityId
		event.note = note
		event.lulDevice = lulDevice
		return event		
	end,
	
	CheckAndSendNotificationOld = function(message, lul_device)
    
    luup.log("Process EventData (old)", 02)
          
		local eventList = {}
		local hash = DataParser.GetHash(message)
    
    -- get data from luup if length of EventNotifier.STATIC_HASH == 0
    local length = 0
    for i, v in pairs(EventNotifier.STATIC_HASH) do length = length + 1 end
    if length == 0 then
      EventNotifier.InitStaticHash(lul_device)
    end
		
		-- reset CHANGE_OP_MODE_COUNTER if day of week changes
		if EventNotifier.CURRENT_DAY ~= os.date("%d") then
			EventNotifier.CURRENT_DAY = os.date("%d")
			EventNotifier.COUNTER_OP_MODE_CHANGES = 0
		end
		
		
		-- EventCode 100
		-- check if operation mode changed (M06)
		if hash["M06"] ~= nil then
			if hash["M06"] ~= EventNotifier.STATIC_HASH["M06"] then
				
				-- send notification for operationmode changed
				table.insert(eventList, EventNotifier.CreateEvent("100", EventNotifier.STATIC_HASH["M06"], hash["M06"], "", "", lul_device))			
				
				-- increment operationmode counter
				EventNotifier.COUNTER_OP_MODE_CHANGES = EventNotifier.COUNTER_OP_MODE_CHANGES + 1
				
				-- update TIMESTAMP_OP_MODE_CHANGED
				EventNotifier.TIMESTAMP_OP_MODE_CHANGED = os.time()
				
				-- EventCode 101
				-- check if change of operation mode exceeds more than ten times in the last 24 hours
				if EventNotifier.COUNTER_OP_MODE_CHANGES == EventNotifier.TO_MANY_OP_MODE_CHANGES then
					table.insert(eventList, EventNotifier.CreateEvent("101", nil, nil, nil, nil, lul_device))
				end 
			end
		end		
		
		
		
		-- EventCode 102
		-- check if operation mode changed during the last 36 hours
		if EventNotifier.COUNTER_OP_MODE_CHANGES == 0 and (os.time() - EventNotifier.TIMESTAMP_OP_MODE_CHANGED) > EventNotifier.SECONDS_OF_36_HOURS then	
			
			table.insert(eventList, EventNotifier.CreateEvent("102", nil, nil, nil, nil, lul_device))
			
			-- reset TIMESTAMP_OP_MODE_CHANGED, only one notification for EventCode 102
			EventNotifier.TIMESTAMP_OP_MODE_CHANGED = os.time()
		end
		
		
		
		-- EventCode 110
		-- TODO: not sent from plc yet
		
		
		-- EventCode 111, 112, 113
		-- TODO: no differentiation sent from plc yet
		-- check if settings changed
		local settingChanges = EventNotifier.CheckForSettingsChanges(hash)
		if table.getn(settingChanges) > 0 then
			
			for variable, value in pairs(settingChanges) do 
        table.insert(eventList, EventNotifier.CreateEvent("111", value.old, value.new, value.variable, nil, lul_device))
      end
	        
		end
    
    
    -- EventCode 114
    -- check if M20 (Nichtlademerker) changed
    if hash["M20"] ~= nil then
      if hash["M20"] ~= EventNotifier.STATIC_HASH["M20"] then
        table.insert(eventList, EventNotifier.CreateEvent("114", EventNotifier.STATIC_HASH["M20"], hash["M20"], nil, nil, lul_device))
      end
    end
    
         
        
    -- EventCode 120
    -- TODO: not sent from plc yet
    
    
    -- EventCode 130
    -- TODO: not sent from plc yet
    
    
    -- EventCode 150,151,152
    -- TODO: implementation in hardwaresocketcontroller class
    
    -- EventCode 153
    if hash["M17"] ~= nil then
      if hash["M17"] ~= EventNotifier.STATIC_HASH["M17"] then
        table.insert(eventList, EventNotifier.CreateEvent("153", EventNotifier.STATIC_HASH["M17"], hash["M17"], nil, EventNotifier.STATIC_HASH["M04"], lul_device))
      end
    end
    
    -- EventCode 154
    if hash["M32"] ~= nil then
      if hash["M32"] ~= EventNotifier.STATIC_HASH["M32"] then
        table.insert(eventList, EventNotifier.CreateEvent("154", EventNotifier.STATIC_HASH["M32"], hash["M32"], nil, EventNotifier.STATIC_HASH["M03"], lul_device))
      end
    end
    
    -- EventCode 155
    if hash["M33"] ~= nil then
      if hash["M33"] ~= EventNotifier.STATIC_HASH["M33"] then
        table.insert(eventList, EventNotifier.CreateEvent("155", EventNotifier.STATIC_HASH["M33"], hash["M33"], nil, EventNotifier.STATIC_HASH["M03"], lul_device))
      end
    end
    
    
    -- EventCode 200, 201
    -- TODO: no differentiation sent from plc yet
		if hash["F06"] ~= nil then
			if hash["F06"] == "TRUE" and hash["F06"] ~= EventNotifier.STATIC_HASH["F06"] then
				table.insert(eventList, EventNotifier.CreateEvent("200", EventNotifier.STATIC_HASH["F06"], hash["F06"], nil, nil, lul_device))
			end 
		end
		
		
		-- EventCode 230, 231
		-- TODO: definition micheal geiger
		
		
		-- EventCode 250, 251
		-- TODO: not sent from plc yet
		
		
		-- EventCode 252
		-- check if totalvoltage is underrun
		if hash["F03"] ~= nil then
			if hash["F03"] ~= "0" and  hash["F03"] ~= EventNotifier.STATIC_HASH["F03"] then
				
				table.insert(eventList, EventNotifier.CreateEvent("252", EventNotifier.STATIC_HASH["F03"], hash["F03"], nil, nil, lul_device))
			end
		end 
		
		
		-- EventCode 253
		-- TODO: not sent from plc yet
		
		
		-- EventCode 254
		-- check if an overload occurs
		if hash["F01"] ~= nil then
			if hash["F01"] ~= "0" and hash["F01"] ~= EventNotifier.STATIC_HASH["F01"] then
		
				table.insert(eventList, EventNotifier.CreateEvent("254", EventNotifier.STATIC_HASH["F01"], hash["F01"], nil, nil, lul_device))
			end
		end 
    
    
    -- EventCode 258
    if hash["F07"] ~= nil then
			if hash["F07"] == "TRUE" and hash["F07"] ~= EventNotifier.STATIC_HASH["F07"] then
				table.insert(eventList, EventNotifier.CreateEvent("258", EventNotifier.STATIC_HASH["F07"], hash["F07"], nil, nil, lul_device))
			end 
		end
		
		
		-- EventCode 255, 256, 257
		-- TODO: need extra time
		
		
		-- EventCode 300
		-- check if bms error occurs
		if hash["F02"] ~= nil then
			if hash["F02"] ~= "0" and  hash["F02"] ~= EventNotifier.STATIC_HASH["F02"] then
		
				table.insert(eventList, EventNotifier.CreateEvent("300", EventNotifier.STATIC_HASH["F02"], hash["F02"], nil, nil, lul_device))
			end
		end
		
		
		-- EventCode 301
		-- TODO: need extra time
		
		
		-- EventCode 302
		-- Server handles this event
		
		
		-- EventCode 400
		-- TODO: not sent from plc yet
		
		
		-- EventCode Feuernotaus
		-- TODO: need to be spcified
		
		
		--if #eventList > 0 then
		--	EventNotifier.NotifyEvent(eventList)
		--end
    
    
    
    
    
    -- create event folders
    os.execute("mkdir -p "..EventNotifier.PATH_EVENT_SH_FOLDER)
    os.execute("mkdir -p "..EventNotifier.PATH_EVENT_SRV_FOLDER)
    os.execute("mkdir -p "..EventNotifier.PATH_EVENT_TMP_FOLDER)
    os.execute("mkdir -p "..EventNotifier.PATH_EVENT_TRANSMIT_FOLDER)
		
		
		-- delete old files
		Utils.DeleteFilesBefore(EventNotifier.PATH_EVENT_SRV_FOLDER.."/", "%d%d%d%d%-%d%d%-%d%d%.log", (os.time() - (EventNotifier.DELETE_FILES_BEFORE) ))
		Utils.DeleteFilesBefore(EventNotifier.PATH_EVENT_SH_FOLDER.."/", "%d%d%d%d%-%d%d%-%d%d%.log", (os.time() - (EventNotifier.DELETE_FILES_BEFORE) ))
    
    
    for key,event in pairs(eventList) do
      -- get current time
      local timestamp = os.time()
      
      --create new event file
      EventNotifier.CreateNewEventFile(timestamp, event.code, event.oldValue, event.newValue, event.entityId, event.note)
      
      --create/write event to log //LEGACY
      local sonnenbatterieUrl = EventNotifier.CreateUrl(EventNotifier.SONNENBATTERIE_URL, event.code, event.oldValue, event.newValue, event.entityId, event.note, timestamp)
      EventNotifier.WriteToLog(timestamp, sonnenbatterieUrl, EventNotifier.PATH_EVENT_SRV_FOLDER.."/"..os.date("%Y-%m-%d", tonumber(timestamp))..".log")
    end
		
		
		EventNotifier.CopyData(hash)
  end,
  
	
	
	-- static function CheckAndSendNotification(data)
	--- Checks if a event has been risen and sends it
	-- @param message The udp message to check for events
	-- @param lul_device Id of battery device
	CheckAndSendNotification = function (message, lul_device)
    luup.log("Process EventData", 02)
        
    local eventList = {}
    
    -- split by pipe to get each event 
    local rawEventList = Utils.Split(message, "|")
    
    for index, value in pairs(rawEventList) do
      
      local indexOfColon = string.find(value, ":")
      
      -- split by colon to seperate eventcode and eventparameters      
      if indexOfColon ~= nil then
        local key = string.sub(value, 1, indexOfColon - 1)
        
        -- split eventparameters by semicolon to get each parameter
        local eventParameters = Utils.Split(string.sub(value, indexOfColon + 1 ), ";")
        local eventHash = {}
        
        for x, eventParameter in ipairs(eventParameters) do
          -- split by equal sign the get each parameterkey and parametervalue 
          local eventParameterKeyValue = Utils.Split(eventParameter, "=")
        
          if table.getn(eventParameterKeyValue) == 2 then
            eventHash[eventParameterKeyValue[1]] = eventParameterKeyValue[2]
          end
        end        
        
        table.insert(eventList, EventNotifier.CreateEvent(key, eventHash["ov"], eventHash["nv"], eventHash["entity_id"], eventHash["note"], 1))
      end
    end      
    
    -- if #eventList > 0 then
		--	EventNotifier.NotifyEvent(eventList)
		--end
    
    
    
    
    
    
    -- create event folders
    os.execute("mkdir -p "..EventNotifier.PATH_EVENT_SH_FOLDER)
    os.execute("mkdir -p "..EventNotifier.PATH_EVENT_SRV_FOLDER)
    os.execute("mkdir -p "..EventNotifier.PATH_EVENT_TMP_FOLDER)
    os.execute("mkdir -p "..EventNotifier.PATH_EVENT_TRANSMIT_FOLDER)
		
		
		-- delete old files
		Utils.DeleteFilesBefore(EventNotifier.PATH_EVENT_SRV_FOLDER.."/", "%d%d%d%d%-%d%d%-%d%d%.log", (os.time() - (EventNotifier.DELETE_FILES_BEFORE) ))
		Utils.DeleteFilesBefore(EventNotifier.PATH_EVENT_SH_FOLDER.."/", "%d%d%d%d%-%d%d%-%d%d%.log", (os.time() - (EventNotifier.DELETE_FILES_BEFORE) ))
    
    
    for key,event in pairs(eventList) do
      -- get current time
      local timestamp = os.time()
      
      --create new event file
      EventNotifier.CreateNewEventFile(timestamp, event.code, event.oldValue, event.newValue, event.entityId, event.note)
      
      --create/write event to log //LEGACY
      local sonnenbatterieUrl = EventNotifier.CreateUrl(EventNotifier.SONNENBATTERIE_URL, event.code, event.oldValue, event.newValue, event.entityId, event.note, timestamp)
      EventNotifier.WriteToLog(timestamp, sonnenbatterieUrl, EventNotifier.PATH_EVENT_SRV_FOLDER.."/"..os.date("%Y-%m-%d", tonumber(timestamp))..".log")
    end
	end,
  
  
  CreateNewEventFile = function(timestamp, key, old, new, entity_id, note)
    
    -- create id
    local id = socket.gettime() * 10000
    id = tostring(id)
    id = string.sub(id,3)
    
    -- open file in append mode
    local logfile = io.open(EventNotifier.PATH_EVENT_TMP_FOLDER.."/"..id, "a+")
    
    -- write content to file
    logfile:write(tonumber(timestamp).."\t"..tonumber(key).."\t"..tostring(entity_id).."\t"..tostring(old).."\t"..tostring(new).."\t"..tostring(note).."\t0")
    -- luup.log(tonumber(timestamp).."\t"..tonumber(key).."\t"..tostring(entity_id).."\t"..tostring(old).."\t"..tostring(new).."\t"..tostring(note).."\t0")  
    -- close file
    logfile:close()
    
    local moveCmd = "mv "..EventNotifier.PATH_EVENT_TMP_FOLDER.."/"..id.." "..EventNotifier.PATH_EVENT_TRANSMIT_FOLDER.."/"..id
    os.execute(moveCmd)
    
  end,
  
  
}
