-- class sf_settings_provider.lua 1.0
-- @author Dennis Thalmeier
-- @description: class that checks if there was a charge possible over the last 8 hour. If a charge was possible and no charge of the system was initiated, the sf will send and event to the server

-- changes 0.2
-- added monthly sf_hardware export
-- changes 1.0
-- fixed some nil bugs
-- updated monitoring time to 8h (ref us test)

-- settingsProvider will be initialized with serial, functionmode, RSOC, pv-generation, consumption, charge_power, invertertype
  SF_settings_provider =
  {
  new = function(serial, functionmode, rsoc, pv, consumption, charge, inverter, lastValidData)
    ---- Constructor ----
    local self = {}
    -- getCurrent SOC; getCurrentExcess; getCurrent timestamp -> Safe values if excess is true
    -- if safedSOC > currentSOC and excess == true and elapsed time > 28800 (8 Hours) -> send Event
    
    ---Constants---
    let_delay_file_path = "/tmp/charge_check"
    let_threshold_us = 250
    let_threshold_eu = 50
    
    ---Variables---
    self.currentTime = os.time()
    self.serial = serial
    self.functionmode = functionmode
    self.input_rsoc = rsoc
    self.input_pv = pv
    self.input_consumption = consumption
    self.input_charge = charge
    self.input_inverter = inverter
    self.input_lastValidData = lastValidData
    
    --- Functions ---
   
   --- Function that performs a terminal command and gives back the result as a string value
    -- @param string terminal command
    -- @return string return value 
    self.get_popen_value = function(inval)
      local file_retval =  io.popen(inval)
      local str_retval = file_retval:read("*a")
      file_retval:close()
      
      return str_retval
    end


   
    -- compares production and consumtion and checks the difference
    -- @return returns an boolean thats true if theres excess and false if not
    self.getCurrentCharge = function()
      --- todo check eu and us systems threshold
      -- luup.log("pv: "..self.input_pv.."cons: "..self.input_consumption.."charge "..self.input_charge.."")
      local threshold = tonumber(let_threshold_us)
      if (self.input_inverter == nil) then return 0 end
      if (self.input_inverter == 2) then
        threshold = tonumber(let_threshold_us)
      else
        threshold = tonumber(let_threshold_eu)
      end
      
      --if (tonumber(self.input_pv) - threshold) > tonumber(self.input_consumption) and tonumber(self.input_charge) ~= 0.0 then
      if (self.input_pv == nil or self.input_consumption == nil) then
        return 0
      end  
      if (tonumber(self.input_pv) - threshold) > tonumber(self.input_consumption) then 
        return 1
      else 
        return 0
      end
    end
    
  --- Splits inputstr by sep
  -- splits the assigned string (inputstr) by the assigned seperator (sep). 
  -- @param inputstr The string to split
  -- @param sep The seperator to use
  -- @return Returns a table with the split string
  self.split = function(inputstr, sep)
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
    
    self.loadData = function(path)
      
      local filePath = path 
      local content
      -- check if file exists
      local f = io.open(filePath,"r")
      if f ~= nil then 
        -- file exists; split data
        content = f:read("*all")
        f:close()
        luup.log("content: "..content)
        -- convert content string into content array seperated by tab
        content = self.split(content, ";")
        
        
         -- nil check
      
      if content[1] == nil or content[2] == nil or content[3] == nil then
        luup.log("nil check load method")
        return nil
      end
        
        -- convert string data (bool safed as 0 or 1, SOC, timestamp)to number
        content[1] = tonumber(content[1])
        content[2] = tonumber(content[2])
        content[3] = tonumber(content[3])
        luup.log("content3: "..content[3])
        
        -- nil check
      
      if content[1] == nil or content[2] == nil or content[3] == nil then
        luup.log("nil check load method")
        return nil
      end
      
      else 
        -- file does no exist; return nil and exit
        return nil
      
      end
      
      return content
    end
    
    self.safeData = function(filePath, inputArray)
      
      local newf=io.open(filePath,"w")
      newf:write(inputArray[1]..";"..inputArray[2]..";"..inputArray[3])
      io.close(newf) 
      
    end
    
    self.checkChargeBehavior = function()
      
      local current_data_array = {}
      
      current_data_array[1] = tonumber(self.getCurrentCharge())
      current_data_array[2] = tonumber(self.input_rsoc)
      current_data_array[3] = tonumber(os.time())
      
       if current_data_array[1] == nil or current_data_array[2] == nil or current_data_array[3] == nil then
        luup.log("nil check chargeBehavior method")
        return nil
      end
      
      -- luup.log("safed Number: "..current_data_array[3])
      local saved_data_array = {} 
      saved_data_array = self.loadData(let_delay_file_path)
      
      --- check if there's old Data if not check the new data and end
      if saved_data_array  == nil then
        -- luup.log("safed Array is nil")
        self.safeData(let_delay_file_path, current_data_array)
        return
      end
      
      -- if savedSOC > currentSOC and excess == true and elapsed time > 28800 (8 hour) -> send Event
      --luup.log("currentChargePossible = "..current_data_array[1].."oldChargePossible = "..saved_data_array[1])
      --luup.log("currentSOC = "..current_data_array[2].."oldSOC = "..saved_data_array[2])
      --luup.log("Timestamp = "..current_data_array[3].."elapsed time = "..(os.time()-saved_data_array[3]))
      --luup.log("lastValidData = ".. self.input_lastValidData)
      if saved_data_array[1] == 1 and current_data_array[1] == 1 then
        if current_data_array[2] < saved_data_array[2] then
          if (os.time()-saved_data_array[3]) > 28800 then
              -- SlaveMode check; SOC check over 60%
            if self.functionmode ~= 20 and current_data_array[2] < 30 then
              -- alarm 128
              -- luup.log("Send Alarm 128")
              if (self.input_lastValidData == nil) then self.input_lastValidData = 0 end
              if ((os.time() - self.input_lastValidData) < 420 ) then
              self.sendEvent()
              end
              -- after sending the event ones reset the saved data to start a new test
              self.safeData(let_delay_file_path, current_data_array)
            end
          end
        end
      end
      
      --- reset timestamp if charge behavior has changed to 0; 
      if current_data_array[1] == 1 and saved_data_array[1] == 0 then
        self.safeData(let_delay_file_path, current_data_array)
      end
      --- reset data if no error is there
      if current_data_array[1] == 0 and saved_data_array[1] == 0 then
        self.safeData(let_delay_file_path, current_data_array)
      end
      
      --- reset data if soc increased
      if current_data_array[2] > saved_data_array[2] then
        self.safeData(let_delay_file_path, current_data_array)
      end
      
      --- send event to identify the sf hardware on the serverside once in a month
      self.sendEventSFVersion()
      
      --- do nothing in case of an error; time won't be resetted and an event will be called if the SOC is getting lower
      
    end
    
    
     self.sendEventSFVersion = function()
      --fire the Event only once an month on day 25 at 11:11
      local let_firedate = "251110"
      local var_date = os.date("%d%H%M")

     if var_date == let_firedate then
      -- todo timer 35 sec
      
         os.execute("sleep " .. 35)
      
        local str_sfID = self.get_popen_value("hostname | grep -o -E '[0-9]+'")
        str_sfID = string.gsub(str_sfID, "\n", "")
      
        -- get SF Hardware Version
        -- local str_sfhardware = self.get_popen_value("grep \"^system type\" /proc/cpuinfo | cut -d: -f2-")
        local str_sfhardware = self.get_popen_value("grep \"^system type\" /proc/cpuinfo | cut -d: -f2-")
   
        -- nil check
        if str_sfhardware == nil or str_sfID == nil then
          return
        end
             
        local sep = " "
        local t={} ; local i=1
          for str in string.gmatch(str_sfhardware, "([^"..sep.."]+)") do
            t[i] = str
            --  print(t[i])
            i = i + 1
          end
        
        str_sfhardware = t[2]

        if str_sfhardware == "RT3883" then 
          --str_sfhardware = split(str_sfhardware, " ")
          print("G300")
          str_sfhardware = "G300"
        elseif str_sfhardware == "MT7620A" then
          str_sfhardware = "G150"
        else
          str_sfhardware = "noData"
        end
        
        ---https://meine.sonnenbatterie.de/eventlog/xyz/111111/128
        --local str_callEventUrl = "https://meine.sonnenbatterie.de/eventlog/"..self.serial.."/"..str_sfID.."/130"
        local str_callEventUrl = "https://meine.sonnenbatterie.de/eventlog/"..self.serial.."/"..str_sfID.."/130?note="..str_sfhardware..""
      
        local http_SF_timeout_Result = self.get_popen_value("curl --silent -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
        luup.log("EventResult "..http_SF_timeout_Result)        
        var_eventSendOK = true
        
        --end
      end
    end
    
    self.sendEvent = function()
      local str_sfID = self.get_popen_value("hostname | grep -o -E '[0-9]+'")
      str_sfID = string.gsub(str_sfID, "\n", "")
      ---https://meine.sonnenbatterie.de/eventlog/xyz/111111/128
      --local str_callEventUrl = "https://meine.sonnenbatterie.de/eventlog/"..self.serial.."/"..str_sfID.."/128"
      local str_callEventUrl = "https://meine.sonnenbatterie.de/eventlog/"..self.serial.."/"..str_sfID.."/128"
      --luup.log("EventURL "..str_callEventUrl)
      local http_SF_timeout_Result = self.get_popen_value("curl --silent -q -s -S -k --connect-timeout 5  -m 7 '"..str_callEventUrl.."'")
      luup.log("EventResult "..http_SF_timeout_Result)
    end
    
    self.getSettings = function()
      
      local str_sfID = self.get_popen_value("hostname | grep -o -E '[0-9]+'")
      --str_sfID = string.gsub(str_sfID, "\n", "")
      str_sfID = string.gsub(str_sfID, "\n", "")
      luup.log("SFID "..str_sfID)
      
      local retval = self.serial
      luup.log("Serial: "..retval)
      luup.log("Functionmode: "..self.functionmode) 
      luup.log("rsoc: "..self.input_rsoc) 
      luup.log("pv: "..self.input_pv) 
      luup.log("consumption: "..self.input_consumption) 
      luup.log("charge: "..self.input_charge) 
      --luup.log("sf_ID: "..self.str_sfID)
      return retval
    end
    
    return self
  end,

}

