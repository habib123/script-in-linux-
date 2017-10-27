require ("DataProvider")
require ("UdpSender")
require 'lfs'
JSON = require ("JSON") -- one-time load of the routines

LuupDataProvider=
{
  -- url
  BASE_URL = "http://127.0.0.1/",   
  
  
  -- services
  SERVICE_BATTERY = "urn:psi-storage-com:serviceId:Battery1",
  SERVICE_PHOTOVOLTAICS = "urn:psi-storage-com:serviceId:Photovoltaics1",
  SERVICE_TOTALCONSUMPTION = "urn:psi-storage-com:serviceId:TotalConsumption1",
  SERVICE_CHP = "urn:psi-storage-com:serviceId:CHP1",
  SERVICE_HEATPUMP = "urn:psi-storage-com:serviceId:Heatpump1",
  SERVICE_OWNCONSUMPTIONRELAY = "urn:psi-storage-com:serviceId:OwnConsumptionRelay1",
  
  -- types
  TYPE_BATTERY = "urn:schemas-psi-storage-com:device:Battery:1",
  TYPE_PHOTOVOLTAICS = "urn:schemas-psi-storage-com:device:Photovoltaics:1",
  TYPE_CHP = "urn:schemas-psi-storage-com:device:CHP:1",
  TYPE_TOTALCONSUMPTION = "urn:schemas-psi-storage-com:device:TotalConsumption:1",
  TYPE_OWNCONSUMPTIONRELAY = "urn:schemas-psi-storage-com:device:OwnConsumptionRelay:1",
  TYPE_HEATPUMP = "urn:schemas-psi-storage-com:device:Heatpump:1",
  
  -- paths
  PATH_EVENT_SRV_FOLDER = "/tmp/prosol/events/srv", -- folder of events for srv
  
  -- network
  SB_IP = "192.168.81.2",
  SB_PORT = "1203",
  
  
  inherit = function(self, debugLevel)
    local batteryID = nil
    local photovoltaicsID = nil
    local totalConsumptionID = nil
    local chpID = nil
    local heatpumpID = nil
    local ownConsumptionRelayID = nil
    
    self.devicesFound = false
    
    self.debugLevel = debugLevel
    
    self.sbUdpSender = UdpSender.new(LuupDataProvider.SB_IP, LuupDataProvider.SB_PORT, 0)
    
    --- Initializes the created object
    local super_init = self.Init
    self.Init = function()
      self.InitDeviceIDs()
    end
    
    
    
    --- Sets the setpoint for charging power
		-- @param setPoint The setpoint to set for batteries charging power
    local super_SetSetpointForChargingPower = self.SetSetpointForChargingPower
    self.SetSetpointForChargingPower = function(setPoint)      
      self.Debug("SetSetpointForChargingPower", 1)
      
--      if self.DevicesFound() == false then
--        return false
--      end
      
      
      local retval = true
      
      self.sbUdpSender.SendMessage("C24:"..setPoint)
      
      --local url_C23 = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable=C23&Value="..0
      --local url_C24 = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable=C24&Value="..setPoint
      
      --local returnCode_C23 = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_C23.."'")
      --local returnCode_C24 = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_C24.."'")
      
      --if (returnCode_C23 == nil or tonumber(returnCode_C23) ~= 0) or (returnCode_C24 == nil or tonumber(returnCode_C24) ~= 0) then
      --  retval = false
      --  self.Debug("Sent SetPoint to PLC failed: "..setPoint, 0)
      --end
      
      return retval	
    end
    
    
    
    --- Sets the setpoint for discharging power
		-- @param setPoint The setpoint to set for batteries discharging power
    local super_SetSetpointForDischargingPower = self.SetSetpointForDischargingPower
    self.SetSetpointForDischargingPower = function(setPoint)      
      self.Debug("SetSetpointForDischargingPower", 1)
      
--      if self.DevicesFound() == false then
--        return false
--      end
      
      local retval = true
      
      self.sbUdpSender.SendMessage("C23:"..setPoint)
      
--      local url_C23 = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable=C23&Value="..setPoint
--      local url_C24 = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable=C24&Value="..0
      
--      local returnCode_C23 = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_C23.."'")
--      local returnCode_C24 = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_C24.."'")
      
--      if (returnCode_C23 == nil or tonumber(returnCode_C23) ~= 0) or (returnCode_C24 == nil or tonumber(returnCode_C24) ~= 0) then
--        retval = false
--        self.Debug("Sent SetPoint to PLC failed: "..setPoint, 0)
--      end
      
      return retval	
    end
    
    --SetPVreductionManually
    --- Sets the step for PV reduction
		-- @param stepID The ID to set set the reduction step
    local super_SetPVreductionManually = self.SetPVreductionManually
    self.SetPVreductionManually = function(reductionStep)      
      self.Debug("SetPVreductionManually", 1)
      
--       if self.DevicesFound() == false then
--        return false
--      end
      
      local retval = true
      
      self.sbUdpSender.SendMessage("C28:"..reductionStep)
      
--      local url_C28 = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable=C28&Value="..reductionStep
      
--      local returnCode_C28 = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_C28.."'")
      
--      if returnCode_C28 == nil or tonumber(returnCode_C28) ~= 0 then
--        retval = false
--        self.Debug("Sent C28 to PLC failed: "..returnCode_C28, 0)
--      end
      
      return retval
    end
    
    
    --SetDeleteSDCardNow 
    --- sets the bool to delete the old files of the SD Card  
		-- @param bool delete true or false 
    local super_SetDeleteSDCardNow = self.SetDeleteSDCardNow
    self.SetDeleteSDCardNow = function(delete_bool)      
      self.Debug("SetDeleteSDCardNow", 1)
      
--       if self.DevicesFound() == false then
--        return false
--      end
      
      local retval = true
      
      self.sbUdpSender.SendMessage("C30:"..delete_bool)
      
--      local url_C30 = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable=C30&Value="..delete_bool
      
--      local returnCode_C30 = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_C30.."'")
      
--      if returnCode_C30 == nil or tonumber(returnCode_C30) ~= 0 then
--        retval = false
--        self.Debug("Sent C30 to PLC failed: "..returnCode_C30, 0)
--      end
      
      return retval
    end
    
    
    --SetDeleteSDCardMonthly 
    --- sets the bool to delete the old files of the SD Card monthly 
		-- @param bool delete monthly true or false  
    local super_SetDeleteSDCardMonthly = self.SetDeleteSDCardMonthly
    self.SetDeleteSDCardMonthly = function(delete_bool_monthly)      
      self.Debug("SetDeleteSDCardMonthly", 1)
      
--       if self.DevicesFound() == false then
--        return false
--      end
      
      local retval = true
      
      self.sbUdpSender.SendMessage("C31:"..delete_bool_monthly)
      
--      local url_C31 = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable=C31&Value="..delete_bool_monthly
      
--      local returnCode_C31 = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_C31.."'")
      
--      if returnCode_C31 == nil or tonumber(returnCode_C31) ~= 0 then
--        retval = false
--        self.Debug("Sent C31 to PLC failed: "..returnCode_C31, 0)
--      end
      
      return retval
    end
    
    
    --SetUSWeatherPrognosisData 
    --- Sets the weather forecast Data
		-- @param data The forecast Data from the Portal 
    local super_SetUSWeatherPrognosisDATA = self.SetUSWeatherPrognosisDATA
    self.SetUSWeatherPrognosisDATA = function(forecastData)      
      self.Debug("SetUSWeatherPrognosisDATA", 1)
      
--       if self.DevicesFound() == false then
--        return false
--      end
      
      local retval = true
      
      self.sbUdpSender.SendMessage("C35:"..forecastData)
      
--      local url_C35 = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable=C35&Value="..forecastData
      
--      local returnCode_C35 = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_C35.."'")
      
--      if returnCode_C35 == nil or tonumber(returnCode_C35) ~= 0 then
--        retval = false
--        self.Debug("Sent C35 to PLC failed: "..returnCode_C35, 0)
--      end
      
      return retval
    end
    
    
    --SetCriticalUpdate PLC 
    --- sets the bool to update the plc if the SD card version is newer than the installed one 
		-- @param bool critical_update_bool true or false  
    local super_SetCriticalUpdate = self.SetCriticalUpdate
    self.SetCriticalUpdate = function(critical_update_bool)      
      self.Debug("SetCriticalUpdate", 1)
      
--       if self.DevicesFound() == false then
--        return false
--      end
      
      local retval = true
      
      self.sbUdpSender.SendMessage("C40:"..critical_update_bool)
      
--      local url_C40 = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable=C40&Value="..critical_update_bool
      
--      local returnCode_C40 = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_C40.."'")
      
--      if returnCode_C40 == nil or tonumber(returnCode_C40) ~= 0 then
--        retval = false
--        self.Debug("Sent C40 to PLC failed: "..returnCode_C40, 0)
--      end
      
      return retval
    end
    
    
     --SetDeleteMinDaySetting 
    --- Sets days to delete files on the plc SD Card
		-- @param int days  
    local super_SetDeleteMinDaySetting = self.SetDeleteMinDaySetting
    self.SetDeleteMinDaySetting = function(delete_day_setting)      
      self.Debug("SetUSWeatherPrognosisSetting", 1)
      
--       if self.DevicesFound() == false then
--        return false
--      end
      
      local retval = true
      
      self.sbUdpSender.SendMessage("S161:"..delete_day_setting)
      
--      local url_S161 = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable=S161&Value="..delete_day_setting
      
--      local returnCode_S161 = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_S161.."'")
      
--      if returnCode_S161 == nil or tonumber(returnCode_S161) ~= 0 then
--        retval = false
--        self.Debug("Sent S161 to PLC failed: "..returnCode_S161, 0)
--      end
      
      return retval
    end
    
    
     --SetUSWeatherPrognosisData 
    --- Sets the weather forecast Data
		-- @param data The forecast Data from the Portal 
    local super_SetUSWeatherPrognosisSetting = self.SetUSWeatherPrognosisSetting
    self.SetUSWeatherPrognosisSetting = function(forecast_setting)      
      self.Debug("SetUSWeatherPrognosisSetting", 1)
      
--       if self.DevicesFound() == false then
--        return false
--      end
      
      local retval = true
      
      self.sbUdpSender.SendMessage("S162:"..forecast_setting)
      
--      local url_S162 = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable=S162&Value="..forecast_setting
      
--      local returnCode_S162 = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_S162.."'")
      
--      if returnCode_S162 == nil or tonumber(returnCode_S162) ~= 0 then
--        retval = false
--        self.Debug("Sent S162 to PLC failed: "..returnCode_S162, 0)
--      end
      
      return retval
    end
    
    
    
    
    --- Sets the measured load for a specific line
    -- @param load The measured load
    -- @param line The corresponding line
    self.SetLoadOnLine = function(measuredLoad, line)
      self.Debug("SetLoadOnLine", 1)
      
--      if self.DevicesFound() == false then
--        return false
--      end
      
      
      -- determine identifier for plc import based on line
      local identifierString = ""
      
      if line == 1 then
        identifierString = "C07"
      elseif line == 2 then
        identifierString = "C08"
      elseif line == 3 then
        identifierString = "C09"
      else 
        return false
      end
    
      
      
      local retval = true
      
      -- send to plc 
      self.sbUdpSender.SendMessage(identifierString..":"..measuredLoad)
      
--      -- url for luup variable
--      local url_for_load = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable="..identifierString.."&Value="..measuredLoad
      
--      -- write luup variable
--      local returnCode_for_load = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_for_load.."'")
      
--      if (returnCode_for_load == nil or tonumber(returnCode_for_load) ~= 0) then
--        retval = false
--        self.Debug("Sent measured load to PLC failed: "..measuredLoad, 0)
--      end
      
      return retval	
    end
  
  
  
    --- Sets the measured production for a specific line
    -- @param load The measured production
    -- @param line The corresponding line    
    self.SetProductionOnLine = function(measuredProduction, line)
      self.Debug("SetProductionOnLine", 1)
      
--      if self.DevicesFound() == false then
--        return false
--      end
      
      
      -- determine identifier for plc import based on line
      local identifierString = ""
      
      if line == 1 then
        identifierString = "C10"
      elseif line == 2 then
        identifierString = "C11"
      elseif line == 3 then
        identifierString = "C12"
      else 
        return false
      end
    
      
      
      local retval = true
      
      -- send to plc 
      self.sbUdpSender.SendMessage(identifierString..":"..measuredProduction)
      
--      -- url for luup variable
--      local url_for_production = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable="..identifierString.."&Value="..measuredProduction
      
--      -- write luup variable
--      local returnCode_for_production = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_for_production.."'")
      
--      if (returnCode_for_production == nil or tonumber(returnCode_for_production) ~= 0) then
--        retval = false
--        self.Debug("Sent measured production to PLC failed: "..measuredProduction, 0)
--      end
      
      return retval	
    end
    
    
    
    
    
    --- Sets the operation mode
		-- @param operationMode The operationmode to set for batteriesystem
    local super_SetOperationMode = self.SetOperationMode
    self.SetOperationMode = function(operationMode)      
      self.Debug("SetOperationMode", 1)
      
--      if self.DevicesFound() == false then
--        return false
--      end
       local retval = true
      
      self.sbUdpSender.SendMessage("C06:"..operationMode)
      
--      local url_C06 = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable=C06&Value="..operationMode
      
--      local returnCode_C06 = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_C06.."'")
      
--      if returnCode_C06 == nil or tonumber(returnCode_C06) ~= 0 then
--        retval = false
--        self.Debug("Sent C06 to PLC failed: "..operationMode, 0)
--      end
      
      return retval
    end
    
    
    
    --- Sets the automatic cellcarestatus mode
		-- @param automaticCellCareStatus The status for the automatic cellcare to set
    local super_SetAutomaticCellCareStatus = self.SetAutomaticCellCareStatus
    self.SetAutomaticCellCareStatus = function(automaticCellCareStatus)      
      self.Debug("SetAutomaticCellCareStatus", 1)
      
--      if self.DevicesFound() == false then
--        return false
--      end
      
      local retval = true
      
      self.sbUdpSender.SendMessage("S104:"..automaticCellCareStatus)
      
--      local url_S104 = "http://127.0.0.1:3480/data_request?id=variableset&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable=S104&Value="..automaticCellCareStatus
      
--      local returnCode_S104 = os.execute("curl -q -s -S -k --connect-timeout 5  -m 7 '"..url_S104.."'")
      
--      if returnCode_S104 == nil or tonumber(returnCode_S104) ~= 0 then
--        retval = false
--        self.Debug("Sent S104 to PLC failed: "..automaticCellCareStatus, 0)
--      end
      
      return retval
    end
    
    
    
    
    local super_GetVersionData = self.GetVersionData
    self.GetVersionData = function()
--      if self.DevicesFound() == false then
--        return nil
--      end
      
      local data = nil
      data = self.RequestData()
      
      if data == nil then
        return nil
      end
      
      local versionData = {}
      versionData["S15"] = data["S15"]
      versionData["S16"] = data["S16"]
      versionData["S70"] = data["S70"]
      versionData["S45"] = data["S45"]
      versionData["S66"] = data["S66"]
      versionData["S65"] = tonumber(data["S65"])
      versionData["S69"] = tonumber(data["S69"])
      versionData["S01"] = tonumber(data["S01"])
      
      local raw_json_text = JSON:encode(versionData)

      return raw_json_text
      
    end
  
  
  
    local super_GetBatteryData = self.GetBatteryData
    self.GetBatteryData = function()
--      if self.DevicesFound() == false then
--        return nil
--      end
      
      local data = nil
      data = self.RequestData()
      
      if data == nil then
        return nil
      end
      
      local batteryData = {}
      
      --[[
      batteryData["M34"] = tonumber(data["M34"])
      batteryData["M35"] = tonumber(data["M35"])
      batteryData["C23"] = tonumber(data["C23"])
      batteryData["C24"] = tonumber(data["C24"])
      batteryData["M30"] = tonumber(data["M30"])
      batteryData["S69"] = tonumber(data["S69"])
      batteryData["M31"] = tonumber(data["M31"])
      batteryData["S65"] = tonumber(data["S65"])
      batteryData["S01"] = tonumber(data["S01"])
      batteryData["S71"] = data["S71"]
      
      -- Lichtblick
      batteryData["M03"] = tonumber(data["M03"])
      batteryData["M04"] = tonumber(data["M04"])
      batteryData["M05"] = tonumber(data["M05"])
      batteryData["M06"] = tonumber(data["M06"])
      batteryData["M07"] = tonumber(data["M07"])
      batteryData["M08"] = tonumber(data["M08"])
      batteryData["M09"] = tonumber(data["M09"])
      batteryData["S07"] = tonumber(data["S07"])
      batteryData["S08"] = tonumber(data["S08"])
      --]]
  
  
  
      -- API 1.5
      batteryData["C06"] = tonumber(data["C06"])
      batteryData["C07"] = tonumber(data["C07"])
      batteryData["C08"] = tonumber(data["C08"])
      batteryData["C09"] = tonumber(data["C09"])
      batteryData["C10"] = tonumber(data["C10"])
      batteryData["C11"] = tonumber(data["C11"])
      batteryData["C12"] = tonumber(data["C12"])
      batteryData["C23"] = tonumber(data["C23"])
      batteryData["C24"] = tonumber(data["C24"])
      
      batteryData["M03"] = tonumber(data["M03"])
      batteryData["M04"] = tonumber(data["M04"])
      batteryData["M05"] = tonumber(data["M05"])
      batteryData["M06"] = tonumber(data["M06"])
      batteryData["M07"] = tonumber(data["M07"])
      batteryData["M08"] = tonumber(data["M08"])
      batteryData["M09"] = tonumber(data["M09"])
      batteryData["M30"] = tonumber(data["M30"])
      batteryData["M31"] = tonumber(data["M31"])
      batteryData["M34"] = tonumber(data["M34"])
      batteryData["M35"] = tonumber(data["M35"])
      batteryData["M37"] = tonumber(data["M37"])
      batteryData["M38"] = tonumber(data["M38"])
      batteryData["M39"] = tonumber(data["M39"])
      batteryData["M40"] = tonumber(data["M40"])
      batteryData["M41"] = tonumber(data["M41"])
      
      batteryData["S01"] = tonumber(data["S01"])
      batteryData["S07"] = data["S07"]
      batteryData["S08"] = tonumber(data["S08"])
      batteryData["S15"] = data["S15"]
      batteryData["S16"] = data["S16"]
      batteryData["S45"] = data["S45"]
      batteryData["S65"] = tonumber(data["S65"])
      batteryData["S66"] = data["S66"]
      batteryData["S69"] = tonumber(data["S69"])
      batteryData["S70"] = data["S70"]
      
      --Update 3.7
      batteryData["S160"] = data["S160"]
      batteryData["S161"] = data["S161"]
      batteryData["S162"] = data["S162"]
      
      local raw_json_text = JSON:encode(batteryData)

      return raw_json_text
    end
    
    
    
    local super_GetDataByIdentifier = self.GetDataByIdentifier
    self.GetDataByIdentifier = function(identifier)
--      if self.DevicesFound() == false then
--        return nil
--      end
      
      retval = nil
      --local body,c,l,h = self.RequestURL(LuupDataProvider.BASE_URL.."port_3480/data_request?id=variableget&DeviceNum="..batteryID.."&serviceId="..LuupDataProvider.SERVICE_BATTERY.."&Variable="..identifier)
      if c == nil or tonumber(c) ~= 200 then
        self.Debug("Error requesting data by identifier", 1)
      else
        retval = body
      end
      
      return retval
    end
    
    
    
    local super_GetEventData = self.GetEventData
    self.GetEventData = function()
      self.Debug("GetEventData", 1)
      
--      if self.DevicesFound() == false then
--        return nil
--      end
      
      -- list of all events
      local events = nil
      
      -- current time
      local timestamp = os.time() - (60 * 60 * 24) -- last 24h
      
      local eventData = {}
      local eventDataString = ""
      
      os.execute("mkdir -p "..LuupDataProvider.PATH_EVENT_SRV_FOLDER)
      for file in lfs.dir(LuupDataProvider.PATH_EVENT_SRV_FOLDER) do
        
        file = LuupDataProvider.PATH_EVENT_SRV_FOLDER.."/"..file
        
        local attributes = lfs.attributes(file) 
        if attributes.mode == "file" and attributes.modification > timestamp then
          
          self.Debug("found file, "..file, 1)
          
          local f = io.open(file, "rb")
          local content = f:read("*all")
          f:close()
          
          eventDataString = eventDataString..content
          
        end
        
      end
      
      if eventDataString ~= "" then
        events = {}
        eventData = self.Split(eventDataString, "\r\n")
        
        for k, line in pairs(eventData) do
          
          local splitData = self.Split(line, "\t")
          local timeStampOfEvent = splitData[1]
          local dataset = self.UrlDecode(splitData[2])
          local index = string.find(dataset, "?")
          
          local data = {}
          data[1] = string.sub(dataset, 1, index - 1)
          data[2] = string.sub(dataset, index + 1)
          
          local code = string.sub(data[1], -3)
          
          data = self.Split(data[2], "&")
          
          local old = data[1]
          local new = data[2]
          local entity_id = data[3]
          local note = data[4]
          
          local event = {}
          event.time = os.date("%Y.%m.%d %T", timeStampOfEvent)
          event.old = self.Split(old, "=")[2]
          event.new = self.Split(new, "=")[2]
          event.entity_id = self.Split(entity_id, "=")[2]
          event.note = self.Split(note, "=")[2]
          
          if events[code] == nil then
            events[code] = {}
          end
          
          table.insert(events[code], event)
        end
      end
      
      local raw_json_text = ""
      
      if events == nil then
        raw_json_text = "{}"
      else 
        raw_json_text = JSON:encode(events)
      end
      
      self.Debug("JSON: " ..raw_json_text, 1)
      return raw_json_text
    end
    
    
    
    self.DevicesFound = function()
      if self.devicesFound == false then
        self.InitDeviceIDs()
      end
      
      return self.devicesFound
    end
    
    
    
    self.InitDeviceIDs = function()
      local url =  LuupDataProvider.BASE_URL.."port_49451/data_request?id=lr_devices"
      local body,c,l,h = self.RequestURL(url)
      
      -- if c == 200 call done successfully
      if c == nil or tonumber(c) ~= 200 then
        self.Debug("Failed to request devices", 0)
      else
        -- print(body)
        self.ParseDeviceIds(body)
        
        if batteryID ~= nil and
          photovoltaicsID ~= nil and
          totalConsumptionID ~= nil and
          chpID ~= nil and
          heatpumpID ~= nil and
          ownConsumptionRelayID ~= nil then
          
          self.devicesFound = true
        else
          self.Debug("Device not found", 0)
        end
      end
    end
  
  
  
    self.ParseDeviceIds = function(body)
      
      -- split body by newline and discard first element (there is some strange number)
      local result= self.Split(body, "\r\n")
      body = result[2]
      
      if body == "No handler" then
        self.Debug("No handler", 0)
        return
      end
      local deviceList = JSON:decode(body)
      
      -- get list of devices from json
      local devices = deviceList["devices"]
      
      -- get id for each device 
      for i, device in pairs(devices) do 
        if device["type"] == LuupDataProvider.TYPE_BATTERY then
          batteryID = device["id"]
        elseif device["type"] == LuupDataProvider.TYPE_PHOTOVOLTAICS then
          photovoltaicsID = device["id"]
        elseif device["type"] == LuupDataProvider.TYPE_CHP then
          chpID = device["id"]
        elseif device["type"] == LuupDataProvider.TYPE_TOTALCONSUMPTION then
          totalConsumptionID = device["id"]
        elseif device["type"] == LuupDataProvider.TYPE_OWNCONSUMPTIONRELAY then
          ownConsumptionRelayID = device["id"]
        elseif device["type"] == LuupDataProvider.TYPE_HEATPUMP then
          heatpumpID = device["id"]
        end
      end
      
      self.Debug("ID of Battery: "..batteryID, 1)
      self.Debug("ID of Photovoltaics: "..photovoltaicsID, 1)
      self.Debug("ID of CHP: "..chpID, 1)
      self.Debug("ID of TotalConsumption: "..totalConsumptionID, 1)
      self.Debug("ID of OwnConsumptionRelay: "..ownConsumptionRelayID, 1)
      self.Debug("ID of Heatpump: "..heatpumpID, 1)
    end
    
    
    
    self.RequestData = function()
--      if self.DevicesFound() == false then
--        return nil
--      end
      
      local retval = {}
      local id = lul_device
      --local url = LuupDataProvider.BASE_URL.."/port_3480/data_request?id=lu_status&DeviceNum="..batteryID
      --local data = self.RequestURL(url)
      
      local data,c,l,h = self.RequestURL(url)
      if c == nil or tonumber(c) ~= 200 then
        self.Debug("Failed to request url: "..url, 0)
        return nil
      end

      local deviceList = JSON:decode(data)
      local device = deviceList["Device_Num_"..batteryID]
      local states = device["states"]
      
      for i, state in pairs(states) do
        if string.match(state["variable"], '^[A-Z][0-9][0-9]') then
          retval[state["variable"]] = state["value"]
        end
      end
      
      return retval
      
    end
    
    
    
    self.RequestURL = function(url)
      -- call url
      local http=require'socket.http'
  
      return http.request(url)
    end
    
    self.Split = function(inputstr, sep)
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
    
    
    
    self.UrlEncode = function (str)
      if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
        str = string.gsub (str, " ", "+")
      end
      return str    
    end
    
    
    
    self.UrlDecode = function(str)
      str = string.gsub (str, "+", " ")
      str = string.gsub (str, "%%(%x%x)",
          function(h) return string.char(tonumber(h,16)) end)
      str = string.gsub (str, "\r\n", "\n")
      return str
    end
    
    
    
    self.Debug = function(msg, prio)
      if self.debugLevel >= prio then
        DebugLogger.LogMsg(msg)
      end
    end
    
    
    
    self.Init()
    
    
    
    return self
  end,
  
  
  new = function(debugLevel)
    return LuupDataProvider.inherit(DataProvider.new(), debugLevel)
  end
}
