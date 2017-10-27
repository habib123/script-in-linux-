require 'lfs'


----------------------
--    constants     --
----------------------
local SERVER_URL = "meine-dev.sonnenbatterie.de"
local SERVER_EVENTLOG_URL = "https://meine.sonnenbatterie.de/eventlog/"
local BATTERY_SERVICEID = "urn:psi-storage-com:serviceId:Battery1"
local EXIT_CODE_PATTERN = "EXITCODE:"
local PATH_EVENT_TRANSMIT_FOLDER = "/tmp/prosol/events/transmit"
local PATH_EVENT_TMP_FOLDER = "/tmp/prosol/events/tmp"
local LOCK_FILE_NAME = "eventlock"
local MAX_NUMBER_OF_EVENTS = 500
local TIME_EVENT_PRIORITY_DELAY = 150  -- transfer count is multiplied with this value based on the formula: TIME_EVENT_PRIORITY_DELAY * (PriortyVal * PriorityVal + 5 * PriortiyVal)
local TIME_RESENT_LOCK_DELAY = 300 -- todo set back to 300

----------------------
-- helper functions --
----------------------

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


--- Reads the username of the smartfunction from "/etc/cmh/users.conf"
-- @return Returns the username
getUserName = function ()
  -- read username from /etc/cmh/users.conf
  handle = io.popen("cat /etc/cmh/users.conf | grep -E '^[a-z,A-Z]{3}[0-9]{2,}' | cut -d'=' -f 1")
  local psbnr = handle:read("*a")
  
  -- if users.conf doesnt contain a serialnumber we will take the serialnumber exported by the plc
  -- if this exportvalue is empty we take 1 as serialnumber
  if psbnr == "" or psbnr == nil  or string.len(psbnr) > 10 then
    local f = io.popen("curl http://localhost:7979/rest/devices/battery/S15", 'r')
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
	
	
	
--- Reads the serialnumber of the smartfunction
-- @return Returns the serialnumber
getSerialNumber = function()
  -- read serial nummer
  handle = io.popen("nvram get vera_serial")
  local sfid = handle:read("*a")
  handle:close()
  return sfid	
end



--- Checks if "serverString" is reachable
-- @param serverString Url of the server to check reachability
-- @return true is reachable else false 
isServerReachable = function (serverString)
  local retval = false
  
  handle = io.popen("ping -c1 -q -4 -W1 -w1 "..serverString.."  >/dev/null 2>&1 ; echo $?")
  local inetConnection = handle:read("*a")
  handle:close()
  
  if tonumber(inetConnection) == 0 then
    retval = true
    --luup.log(""..serverString.." is reachable", 02)
  else
    --luup.log(""..serverString.." is not reachable", 02)
  end
  
  return retval	
end





--- creates a json containing the first 500 elements from the eventDataArray
-- @param inputArray
-- @return Returns a json containing the first 500 elements
-- Author Dennis Thalmeier
eventBulkOFEventFilesFromEventDataArray = function(inputBulkArray)
    print("eventArraymakeBulkcalled:"..tablelength(inputBulkArray))
    
    local eventBulkData = {}
    local eventsPriorityDelayed = {}
    local eventsMaxPriority = {}
    local eventcount = 0
  
    for key,value in pairs(inputBulkArray) do 
      print("currentInputElementKey:"..key) 
      -- delete Eventfile
        removeFileFromPath(key, PATH_EVENT_TRANSMIT_FOLDER.."/") 
     if bool_checkEventPriorityDelay(value) then
        eventBulkData[key] = value
        -- increase prio + 1   
        value[7] = value[7] + 1
        eventcount = eventcount + 1
        -- delete Event in case of to high priority
        if value[7] > 10 then
          eventsMaxPriority[key] = value;
        end
      else
        eventsPriorityDelayed[key] = value
      end
      
      if eventcount >= MAX_NUMBER_OF_EVENTS then
        print("Max number of events reached")
        break
      end
    end  
  local eventBulk = JSON:encode(eventBulkData)
  
  return eventBulk, eventcount, eventBulkData, eventsPriorityDelayed, eventsMaxPriority
  
  end

--- compares the actual event priority with the Delaytime (delaytime is a constant multiplied with the priority number) ot the priority and sends true, if the Event could be send
-- @param EventElement
-- @return bool
-- Author Dennis Thalmeier
bool_checkEventPriorityDelay = function(input)
  print("Priority: "..input[7])
  if (input[7] == 0) then
    return true
  end
  
  if (input[7] > 0) then
    -- check delay time with priority multipicator (prio 1: 900s; prio 2: 2100s prio 3: 3600...) formula: TIME_EVENT_PRIORITY_DELAY * (PriortyVal * PriorityVal + 5 * PriortiyVal)
    print("PriorityDelay:"..(TIME_EVENT_PRIORITY_DELAY * (math.pow(input[7],2) + input[7] * 5)).." < "..(os.time() - (input[1])))
    compareVal = (TIME_EVENT_PRIORITY_DELAY * (math.pow(input[7],2) + input[7] * 5))
    if (compareVal < (os.time() - input[1])) then
      print("true")
      return true
    end
  end
  print("false")
  return false
end

postEventData = function(data, url, psbSerial, sfSerial, count)
    
  local cmd = "curl -q -s -S -k -H 'Content-type: application/json' --connect-timeout 10 -m 30 -X POST -d '"..data.."' "..url..psbSerial.."/"..sfSerial.."?c="..count.." 2>&1 ; echo "..EXIT_CODE_PATTERN.."$?"
  print("Command: "..cmd)
  print("\n")
  

  local f = assert(io.popen(cmd, 'r'))
  local response = assert(f:read('*a'))
  f:close()
  
  return response
end



parseServerResponse = function(response)
  local startIndex = nil
  local endIndex = nil
  local responseBody = nil
  local exitCode = nil
  
  startIndex, endIndex = string.find(response, EXIT_CODE_PATTERN)
    
  print("Start at: "..startIndex)
  print("End at: "..endIndex)
  
  if startIndex ~= nil then
    responseBody = string.sub(response, 1, startIndex - 1)
    exitCode = tonumber(string.sub(response, endIndex + 1))
  end
  
  return exitCode, responseBody
end



decodeResponseBody = function(responseBody)
  local fileListToRemove = nil
  
  fileListToRemove = JSON:decode(responseBody)
  
  return fileListToRemove
end



removeFileFromPath = function(file, path)
    print("Delete: "..path..file)
    os.remove(path..file)
end

--- deletes files from the inputArray by the files saved in the files to remove array
-- @param filesToRemove String-Array; inputArray Array EventElement-Array
-- @return array
removeEventFilesFromArray = function(filesToRemove, inputArray)
  for i,file in pairs(filesToRemove) do 
    --table.remove(inputArray, file)
    print("Deleting by String KeyName: "..tostring(file))
    inputArray[tostring(file)] = nil
  end
  return inputArray
end
--- deletes files from the inputArray by the files saved in the files to remove array
-- @param filesToRemove EventElement-Array; inputArray Array EventElement-Array
-- @return array
removeKeyEventFilesFromArray = function(filesToRemove, inputArray)
  print("Delete_arraylength"..tablelength(filesToRemove))
  for key,value in pairs(filesToRemove) do 
    --table.remove(inputArray, file)
    print("Deleting by arrayElements: "..tostring(key))
    inputArray[tostring(key)] = nil
  end
  return inputArray
end

--- deletes files from the inputArray by the files saved in the files to remove array
-- @param filesToRemove EventElement-Array; inputArray Array EventElement-Array
-- @return array
safeEventFilesWithNewPriority = function(filesToRemoveFromArray, bulkarray)
  for key,value in pairs(filesToRemoveFromArray) do 
    print("Deleting from Bulk: "..value)
    bulkarray[tostring(value)] = nil
  end
  if (bulkarray ~= nil) then
        for key,file in pairs(bulkarray) do
          createNewEventFile(tostring(key), file[1], file[2], file[3], file[4], file[5], file[6], file[7]) 
          bulkarray[key] = nil
        end
  end
  
end
 --- creates new event file with given Data (to safe Event with inveased priority)
-- @param eventfilename, timestamp, key, old, new, entity_id, note, priority
createNewEventFile = function(eventfilename, timestamp, key, old, new, entity_id, note, priority)
    
    if (priority == nil) then 
      priority = 0 
    end
    
    if (eventfilename == nil or timestamp == nil or key == nil or old == nil or new == nil or entity_id == nil or note == nil) then
      print("try to write nil value")
    
    else 
    -- open file in append mode
    local logfile = io.open(PATH_EVENT_TRANSMIT_FOLDER.."/"..eventfilename, "a+")
    
    -- write content to file
    logfile:write(tonumber(timestamp).."\t"..tonumber(key).."\t"..tostring(entity_id).."\t"..tostring(old).."\t"..tostring(new).."\t"..tostring(note).."\t"..tostring(priority))
    -- close file
    logfile:close()
    
    --local moveCmd = "mv "..EventNotifier.PATH_EVENT_TMP_FOLDER.."/"..id.." "..EventNotifier.PATH_EVENT_TRANSMIT_FOLDER.."/"..id
    --os.execute(moveCmd)
    end
  end
getLockForEventTransmit = function(path)
  local retval = false
  local filePath = path.."/"..LOCK_FILE_NAME 
  
  -- check if file exists
  local f=io.open(filePath,"r")
  if f~=nil then 
    -- file exists
    io.close(f) 
      
    local lastModification = lfs.attributes(filePath, "modification") 
    if os.time() - TIME_RESENT_LOCK_DELAY > lastModification then
      os.remove(filePath)
      os.execute("touch "..filePath)
      retval = true
    else
      retval = false
    end
    
    
  else 
    -- file does no exist
    os.execute("touch "..filePath)
    retval = true
  end
    
  return retval
end


-----------------------------
-- EventNotifier functions --
-----------------------------
transmitEvents = function(inputArray)

  local reachable = isServerReachable(SERVER_URL)
    if reachable then
      print ("IsServerReachable: true")
      print("\n")
    
      local sfSerial = getSerialNumber()
      sfSerial = (sfSerial:gsub("^%s*(.-)%s*$", "%1"))
      print("Serial: "..sfSerial)
      print("\n")
      
      local psbSerial = getUserName()
      psbSerial = (psbSerial:gsub("^%s*(.-)%s*$", "%1"))
      print ("Username: "..psbSerial)
      print("\n")
    
      --local bulk, count = eventBulkOfEventFilesFromPath(PATH_EVENT_TRANSMIT_FOLDER.."/") --deprecated
      local bulk, count, bulkarray, priorityDelayedEvents, eventsMaxPriority = eventBulkOFEventFilesFromEventDataArray(inputArray)
      print("JSON: "..bulk)
      print("\n")
      
      if bulk ~= "[]" then
        local serverResponse = postEventData(bulk, SERVER_EVENTLOG_URL, psbSerial, sfSerial, count)
        print("ServerResponse: "..serverResponse)
  
        local exitCode, responseBody
        exitCode, responseBody = parseServerResponse(serverResponse)
    
        if exitCode ~= nil and exitCode == 0 then
          print("ExitCode: "..exitCode)
          print("\n")
      
          local filesToRemove = decodeResponseBody(responseBody)
      
          if filesToRemove ~= nil then
            --removeFilesFromPath(filesToRemove, PATH_EVENT_TRANSMIT_FOLDER.."/")--deprecated
            -- set up inputArray
            inputArray = removeEventFilesFromArray(filesToRemove, inputArray)
            inputArray = removeKeyEventFilesFromArray(eventsMaxPriority, inputArray)
            inputArray = removeKeyEventFilesFromArray(priorityDelayedEvents, inputArray)
            
            -- set up bulkArray
            bulkarray = removeKeyEventFilesFromArray(eventsMaxPriority, bulkarray)
            
            -- save new Event files
            safeEventFilesWithNewPriority(filesToRemove, bulkarray)
            safeEventFilesWithNewPriority(filesToRemove, priorityDelayedEvents)
          end
        end
      else
      --delete all priority delayed files in case of empty bulk array and skip Server Request
      print("empty bulk")
      inputArray = removeKeyEventFilesFromArray(priorityDelayedEvents, inputArray)
      safeEventFilesWithNewPriority(inputArray, priorityDelayedEvents)
      end
    else
      print ("IsServerReachable: false")
      print("\n")
  end
  return inputArray
end


--- creates an array containing all events form given path
-- @param path where event files are located
-- @return Returns an array containing all events
-- Author Dennis Thalmeier
getEventDataArray = function(path)

local array_retval = {}
for file in lfs.dir(path) do
    local filePath = path.."/"..file
        
    local attributes = lfs.attributes(filePath) 
    if attributes.mode == "file" then
      print("File: "..file)
      local f = io.open(filePath, "rb")
      local content = f:read("*all")
      f:close()
      
      -- convert content string into content array seperated by tab
      content = split(content, "\t")
      
      if content[7] == nil or content[7] == "" then 
        print("no file priority; setting prioritiy to 0") 
        content[7] = 0
      end

      -- convert string data (timestamp, key)to number
      content[1] = tonumber(content[1])
      content[2] = tonumber(content[2])
      content[7] = tonumber(content[7])
      array_retval[file] = content
      
    end
  end

return array_retval

end

tablelength = function(intable)
  local count = 0
  if (intable ~= nil) then
    for _ in pairs(intable) do count = count + 1 end
    return count
  else 
    return 0
  end
end

run = function()
  
  os.execute("touch "..PATH_EVENT_TMP_FOLDER.."/eventtransmit_started")
  
  if getLockForEventTransmit(PATH_EVENT_TMP_FOLDER) then
    print("get lock succesfully")
    
    --- function that gives you a table with all events in PATH_EVENT_TRANSMIT_FOLDER
    local eventDataArray = {}
    eventDataArray = getEventDataArray(PATH_EVENT_TRANSMIT_FOLDER)    
    print(tablelength(eventDataArray))
    
    
    --- new transmit function
    while tablelength(eventDataArray) > 0 do
       os.execute("touch "..PATH_EVENT_TMP_FOLDER.."/"..LOCK_FILE_NAME)
      print("EventArrayLength:"..tablelength(eventDataArray))
      eventDataArray = transmitEvents(eventDataArray)
      local socket = require("socket")
			socket.select(nil, nil, 5.0)
    end
    
    
    os.remove(PATH_EVENT_TMP_FOLDER.."/"..LOCK_FILE_NAME)
    
  else
    print("didn't get lock succesfully")
    return
  end
end

-- init JSON
JSON = require ("JSON")

run()


---- deprecated ----
--eventsStillLeft = function(path)
--  local retval = false
--  local number = 0
  
--  for file in lfs.dir(path) do
--    local attributes = lfs.attributes(path.."/"..file) 
--    if attributes.mode == "file" then
--      number = number + 1
--    end
--  end
  
--  return number
--end


---- deprecated ----
--eventBulkOfEventFilesFromPath = function(path) --deprecated

  
--  local eventBulkData = {}
--  local eventcount = 0
--  local eventIndex = 0
  
--  for file in lfs.dir(path) do
--    local filePath = path.."/"..file
        
--    local attributes = lfs.attributes(filePath) 
--    if attributes.mode == "file" then
--      print("File: "..file)
--      local f = io.open(filePath, "rb")
--      local content = f:read("*all")
  
--      f:close()
      
--      -- convert content string into content array seperated by tab
--      content = split(content, "\t")
      
--      -- convert string data (timestamp, key, priority)to number
--      content[1] = tonumber(content[1])
--      content[2] = tonumber(content[2])
--      content[7] = tonumber(content[7])
      
--      -- todo call priority_method and add event to bulk or skip event
--      if checkEventPriorityDelay(content) then
--        eventBulkData[file] = content
--        eventcount = eventcount + 1
--      end
      
--      eventIndex = eventIndex + 1
--      print(eventIndex)
--      if eventcount >= MAX_NUMBER_OF_EVENTS then
--        print("Max number of events reached")
--        break
--      end
--    end
--  end
  
--  local eventBulk = JSON:encode(eventBulkData)
  
--  return eventBulk, eventcount

--end

