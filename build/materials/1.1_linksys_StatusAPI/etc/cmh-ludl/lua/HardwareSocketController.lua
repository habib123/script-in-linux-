--- Class HardwareSocketController
-- @author Christian Rothaermel
-- @class HardwareSocketController
-- @description HardwareSocketController searches for sockets in the luup engine, handles the automatic switching process of the sockets and documents powers and events. 

HardwareSocketController=
{

	-- static variables
	DELETE_FILES_BEFORE = (60 * 60 * 24 * 60), -- files that are older than 60 days will be deleted

	THRESHOLD = 1000, -- threshold default value of sockets
	DURATION = 1800, -- duration default value of sockets
	AUTOMODE = 0, -- automode default value of sockets
	PEAKCONSUMER = 0, -- peakconsumer default value of sockets
	LASTPOWERON = 0,  -- lastpoweron default value of sockets
  SOCFORTURNON = 90, -- socForTurnOn default value of sockets
  SOCFORSHUTOFF = 50, -- socForShutOff default value of sockets
  AUTOMODEOFFGRID = 0, -- autoModeOffgrid default value of socket
  
  AUTOMODE_TEMP_OFF_DURATION = 5*60, -- a manually switch can disable the automode temporally for this duration 
	
	
	PSBATTERIE_SERVICEID = "urn:upnp-org:serviceId:PSBatterie1", -- service id of legacy batterie plugin 
	PSI_SWITCH_SERVICE_ID = "urn:psi-storage-com:serviceId:PsiSwitch1", -- service id of variables for automatic process
	
	SOCKET_SWITCHING_DELAY = 15, -- is a socket switched on/off the next switching progress is allowed in 15 seconds
	
	LAST_WATTAGE_LOG = os.time(), -- timestamp of last log of socket powers (log all 180 seconds)
	WATTAGE_OF_SOCKETS = {}, -- accumulation table of socket powers
	LOG_DURATION = 180, -- log all 180 seconds
	
	-- constructor
	--- Creats a new object of class HardwareSocketController
	-- @param lul_device The id of the parent device. Necessary to read and write data to the parent device
	-- @return The new object
	new = function(lul_device)
		
		self={}		
		
		-- member vars
		self.timeDelaySwitchSocketOn = 0
		self.timeDelaySwitchSocketOff = 0
		
		self.sockets={}
		self.parentDevice = lul_device
		
		
		-- methods
		--- Searches luup engine for available socket devices.
		-- If socket devices were found a HardwareSocket object is created, populated with data and saved to the internal list "self.sockets".
		-- If there is a lack of data in the luup engine, data is set by default values
		self.InitSockets = function()
			luup.log("Init Sockets", 02)
			local autoSocket1 = luup.variable_get(HardwareSocketController.PSBATTERIE_SERVICEID,"AutoSocket1", self.parentDevice)
			if autoSocket1 == nil then
				autoSocket1 = 0
			end
			
			local autoSocket2 = luup.variable_get(HardwareSocketController.PSBATTERIE_SERVICEID,"AutoSocket2", self.parentDevice)
			if autoSocket2 == nil then
				autoSocket2 = 0
			end
			
			local autoSocket3 = luup.variable_get(HardwareSocketController.PSBATTERIE_SERVICEID,"AutoSocket3", self.parentDevice)
			if autoSocket3 == nil then
				autoSocket3 = 0
			end
			
			
			-- get all socket devices of smartfunction			
			local socketIdList = {}			
			for k, v in pairs(luup.devices) do
				if v.category_num == 3 then
					table.insert(socketIdList, k)
				end
			end		
			table.sort(socketIdList)			
			
			
			-- setup neccessary values for sockets if they dont exist
			local index = 1
			for k, v in pairs(socketIdList)do
				if luup.variable_get(HardwareSocketController.PSI_SWITCH_SERVICE_ID,"Priority", v) == nil then
					luup.variable_set(HardwareSocketController.PSI_SWITCH_SERVICE_ID, "Priority", index + 1 ,v)
				end
				
				if luup.variable_get(HardwareSocketController.PSI_SWITCH_SERVICE_ID,"Threshold", v) == nil then
					luup.variable_set(HardwareSocketController.PSI_SWITCH_SERVICE_ID, "Threshold", HardwareSocketController.THRESHOLD,v)
				end
				
				if luup.variable_get(HardwareSocketController.PSI_SWITCH_SERVICE_ID,"Duration", v) == nil then
					luup.variable_set(HardwareSocketController.PSI_SWITCH_SERVICE_ID, "Duration", HardwareSocketController.DURATION,v)
				end
				
				if luup.variable_get(HardwareSocketController.PSI_SWITCH_SERVICE_ID,"LastPowerOn", v) == nil then
					luup.variable_set(HardwareSocketController.PSI_SWITCH_SERVICE_ID, "LastPowerOn", HardwareSocketController.LASTPOWERON,v)
				end
				
				if luup.variable_get(HardwareSocketController.PSI_SWITCH_SERVICE_ID,"AutoMode", v) == nil then
					luup.variable_set(HardwareSocketController.PSI_SWITCH_SERVICE_ID, "AutoMode", HardwareSocketController.AUTOMODE,v)
				end
				
				if luup.variable_get(HardwareSocketController.PSI_SWITCH_SERVICE_ID,"PeakConsumer", v) == nil then
					luup.variable_set(HardwareSocketController.PSI_SWITCH_SERVICE_ID, "PeakConsumer", HardwareSocketController.PEAKCONSUMER,v)
				end
        
        if luup.variable_get(HardwareSocketController.PSI_SWITCH_SERVICE_ID,"SocForShutOff", v) == nil then
					luup.variable_set(HardwareSocketController.PSI_SWITCH_SERVICE_ID, "SocForShutOff", HardwareSocketController.SOCFORSHUTOFF,v)
				end
        
        if luup.variable_get(HardwareSocketController.PSI_SWITCH_SERVICE_ID,"SocForTurnOn", v) == nil then
					luup.variable_set(HardwareSocketController.PSI_SWITCH_SERVICE_ID, "SocForTurnOn", HardwareSocketController.SOCFORTURNON,v)
				end
        
        if luup.variable_get(HardwareSocketController.PSI_SWITCH_SERVICE_ID,"AutoModeOffgrid", v) == nil then
					luup.variable_set(HardwareSocketController.PSI_SWITCH_SERVICE_ID, "AutoModeOffgrid", HardwareSocketController.AUTOMODEOFFGRID,v)
				end
				
--				if index == 1 then
--					luup.variable_set(HardwareSocketController.PSI_SWITCH_SERVICE_ID, "AutoMode", autoSocket1, v)
--				end
				
--				if index == 2 then
--					luup.variable_set(HardwareSocketController.PSI_SWITCH_SERVICE_ID, "AutoMode", autoSocket2, v)
--				end
					
--				if index == 3 then
--					luup.variable_set(HardwareSocketController.PSI_SWITCH_SERVICE_ID, "AutoMode", autoSocket3, v)
--				end
				
				-- if index == 3 then
				-- 	break
				-- else		
				-- 	index = index + 1
				-- end
				index = index + 1				
			end
			
			-- create HardwareSocket objects for all sockets
			for k, v in pairs(socketIdList) do
				
				local tempSocket = HardwareSocket.new(v, self.parentDevice)
				self.AddSocket(tempSocket)
				
				-- HardwareSocketController.WATTAGE_OF_SOCKETS[v] = 0
			end
			
			self.SortByIdAscending()
			for index in pairs(self.sockets) do
				HardwareSocketController.WATTAGE_OF_SOCKETS[self.sockets[index].id] = 0
			end
			
			
			-- list all sockets 
			self.Print()
			
		end		
    
    
    
    self.CheckForManualSwitch = function()
      for index in pairs(self.sockets) do
				self.sockets[index].UpdateValues()
			end
      
      self.SortByIdAscending()
      
      for index in pairs(self.sockets) do
      
      
      if tonumber(self.sockets[index].suggestedStatus) ~= tonumber(self.sockets[index].status) then

					-- manual switch
					local eventList = {}
					table.insert(eventList, EventNotifier.CreateEvent("150", self.sockets[index].suggestedStatus, self.sockets[index].status, self.sockets[index].id, "name:"..luup.devices[self.sockets[index].id].description, self.parentDevice))
					EventNotifier.NotifyEvent(eventList)
					
					self.sockets[index].suggestedStatus = self.sockets[index].status
          self.sockets[index].lastManualSwitch = os.time()
          
				end  
      end
    end
    
    
    


		--- Checks if a socket changed its status
		-- if the status was changed and automode of socket is not equal to the specific autosocket of the plugin, it was a manual change, so the automode of the socket has to be set to zero
		self.CheckForSocketStatusChange = function ()
			for index in pairs(self.sockets) do
				self.sockets[index].UpdateValues()
			end
			
			self.SortByIdAscending()
			
			
			local indexForAutoMode = 1
			for index in pairs(self.sockets) do
			
				if indexForAutoMode == 1 then
					-- get AutoSocket1
					local autosocket1 = luup.variable_get("urn:upnp-org:serviceId:PSBatterie1","AutoSocket1", self.parentDevice)
					
					if self.sockets[index].automode  ~= autosocket1 then
						luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","AutoSocket1", self.sockets[index].automode, self.parentDevice)
					end
				end
				
				if indexForAutoMode == 2 then
					-- get AutoSocket2
					local autosocket2 = luup.variable_get("urn:upnp-org:serviceId:PSBatterie1","AutoSocket2", self.parentDevice)
					
					if self.sockets[index].automode  ~= autosocket2 then
						luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","AutoSocket2", self.sockets[index].automode, self.parentDevice)
					end
				end
				
				if indexForAutoMode == 3 then
					-- get AutoSocket3
					local autosocket3 = luup.variable_get("urn:upnp-org:serviceId:PSBatterie1","AutoSocket3", self.parentDevice)
					
					if self.sockets[index].automode  ~= autosocket3 then
						luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","AutoSocket3", self.sockets[index].automode, self.parentDevice)
					end
				end
				
				if tonumber(self.sockets[index].suggestedStatus) ~= tonumber(self.sockets[index].status) then

					-- manual switch
					local eventList = {}
					table.insert(eventList, EventNotifier.CreateEvent("150", self.sockets[index].suggestedStatus, self.sockets[index].status, self.sockets[index].id, "name:"..luup.devices[self.sockets[index].id].description, self.parentDevice))
					EventNotifier.NotifyEvent(eventList)
					
					self.sockets[index].suggestedStatus = self.sockets[index].status
					self.sockets[index].automode = 0		
					luup.variable_set("urn:psi-storage-com:serviceId:PsiSwitch1","AutoMode", self.sockets[index].automode, self.sockets[index].id)				
					
					
					if indexForAutoMode == 1 then								
						luup.call_action("urn:upnp-org:serviceId:PSBatterie1", "SetAutoSocket1", {newAutoSocket1 = 0}, self.parentDevice)
					end
					
					if indexForAutoMode == 2 then									
						luup.call_action("urn:upnp-org:serviceId:PSBatterie1", "SetAutoSocket2", {newAutoSocket2 = 0}, self.parentDevice)
					end
					
					if indexForAutoMode == 3 then
						luup.call_action("urn:upnp-org:serviceId:PSBatterie1", "SetAutoSocket3", {newAutoSocket3 = 0}, self.parentDevice)
					end
									
				end
				
				indexForAutoMode = indexForAutoMode + 1					 
			end
		end
		
		

		
		--- Decides if a HardwareSocket has to be switched on or off depending on data of the socket and the assigned values for current charging power, current pv power and current consumption
		-- @param chargingPower A value which represents the current charging power
		-- @param pvPower A value which represents the current pv power
		-- @param consumption A value which represents the current consumption
		-- @param localDeviceController A object of class DeviceController 
		self.ProcessDataWithFeedInRule = function(chargingPower, pvPower, consumption, socketSwitchingAllowed, chpSwitchedOn, chpPower, localDeviceController)
      
      luup.log("ProcessDataWithFeedInRule", 02)
			
      -- if plc doesn't export M36 then assume this value as TRUE
      if socketSwitchingAllowed == nil or socketSwitchingAllowed == "" or socketSwitchingAllowed == "TRUE" then
        socketSwitchingAllowed = true
      else
        socketSwitchingAllowed = false
      end
      
      if chpSwitchedOn == nil or chpSwitchedOn == "" or chpSwitchedOn == "FALSE" then
        chpSwitchedOn = false
      else
        chpSwitchedOn = true
      end
      
      
			-- update sockets and check if they need to be switched on
			if chargingPower ~= nil and pvPower ~= nil and consumption ~= nil and chpPower ~= nil then
											
				local batteryPriority = luup.variable_get("urn:psi-storage-com:serviceId:Battery1","Priority", self.parentDevice)			
			
				batteryPriority = tonumber(batteryPriority)
				chargingPower = tonumber(chargingPower)
				pvPower =  tonumber(pvPower)
				consumption = tonumber(consumption)
        chpPower = tonumber(chpPower)
        
        for index in pairs(self.sockets) do
          self.sockets[index].UpdateValues()
        end
			
        
      
				-- calc 60% rule
				-- CheckFeedInRule
				local localPvPeakPower = tonumber(localDeviceController.GetPvPeakPower()) * 1000.0
				local localMaxFeedIn = tonumber(localDeviceController.GetMaxFeedIn()) / 100.0
				
				
				
				-- check if feedinrule is broken
        if os.time() - self.timeDelaySwitchSocketOn > HardwareSocketController.SOCKET_SWITCHING_DELAY then
          if tonumber((pvPower - chargingPower - consumption)/localPvPeakPower) > localMaxFeedIn then
            self.SortByPriorityAscending()
            
            for index = 1, #self.sockets do
              self.sockets[index].Print()
              if tonumber(self.sockets[index].status) == 0 and tonumber(self.sockets[index].peakconsumer) == 1 and tonumber(self.sockets[index].automode) == 1 then
                self.sockets[index].SwitchOn()
                self.timeDelaySwitchSocketOn = os.time()
                luup.log("Switch Socket on SocketID: "..self.sockets[index].id, 02)
                luup.log("Ueberschuss: "..(pvPower - chargingPower - consumption))
                luup.log("PvPeak: "..localPvPeakPower)
                luup.log("Max Einsp.: "..localMaxFeedIn)
                break
              end 
            end
          end
        end
				
				
				-- check if a peakconsumer can be switched off
				self.SortByPriorityDescending()
				if os.time() - self.timeDelaySwitchSocketOn > HardwareSocketController.SOCKET_SWITCHING_DELAY then	
          for index = 1, #self.sockets do
            if tonumber(self.sockets[index].status) == 1 and tonumber(self.sockets[index].peakconsumer) == 1 and tonumber(self.sockets[index].automode) == 1 then
              local watts = luup.variable_get("urn:micasaverde-com:serviceId:EnergyMetering1", "Watts", self.sockets[index].id)
              local userSuppliedWattage = luup.variable_get("urn:micasaverde-com:serviceId:EnergyMetering1", "UserSuppliedWattage", self.sockets[index].id)
              watts = tonumber(watts)
              userSuppliedWattage = tonumber(userSuppliedWattage)
              
              local watt = watts
              
              if userSuppliedWattage ~= nil and userSuppliedWattage > 0 then
                watt = userSuppliedWattage
              end
              
              luup.log("Watt: "..watt, 02)
              if localMaxFeedIn > tonumber((pvPower - chargingPower - consumption + watt)/localPvPeakPower) then						
                self.sockets[index].SwitchOff()
                self.timeDelaySwitchSocketOn = os.time()
                luup.log("Switch Socket off SocketID: "..self.sockets[index].id, 02)
                luup.log("Watt: "..watt)
                luup.log("Ueberschuss: "..(pvPower - chargingPower - consumption + watt))
                luup.log("PvPeak: "..localPvPeakPower)
                luup.log("Max Einsp.: "..localMaxFeedIn)
              end
              break
            end 
          end	
        end
				
        
        -- if chp is switched on we can add chppower to pvpower
        luup.log("Steckdose: PVPower="..pvPower, 02)
        if chpSwitchedOn == true then
          luup.log("Steckdose: CHPSwitchedOn", 02)
          pvPower = pvPower + chpPower
        end
        luup.log("Steckdose: PVPower="..pvPower, 02)
        
				-- automatikschaltung on (automode) anwenden
				self.SortByPriorityAscending()
				if os.time() - self.timeDelaySwitchSocketOn > HardwareSocketController.SOCKET_SWITCHING_DELAY then
					for index = 1, #self.sockets do
						if tonumber(self.sockets[index].status) == 0 and tonumber(self.sockets[index].automode) == 1 and tonumber(self.sockets[index].peakconsumer) == 0 and (os.time() > self.sockets[index].lastManualSwitch + HardwareSocketController.AUTOMODE_TEMP_OFF_DURATION) then
							if tonumber(batteryPriority) > tonumber(self.sockets[index].priority) and tonumber(self.sockets[index].priority) ~= 0 then
								if pvPower - consumption - tonumber(self.sockets[index].threshold) > 0 then
									self.sockets[index].SwitchOn()
									self.timeDelaySwitchSocketOn = os.time()
									break								
								end
							elseif tonumber(self.sockets[index].priority) > tonumber(batteryPriority) and tonumber(self.sockets[index].priority) ~= 0 then
								if pvPower - consumption - chargingPower - tonumber(self.sockets[index].threshold) > 0 and socketSwitchingAllowed then	
									self.sockets[index].SwitchOn()
									self.timeDelaySwitchSocketOn = os.time()
									break								
								end
							end
							break
						end
					end
				end
				
				-- automatikschaltung off (automode) anwenden
				self.SortByPriorityDescending()					
				if os.time() - self.timeDelaySwitchSocketOff > HardwareSocketController.SOCKET_SWITCHING_DELAY then
					for index = 1, #self.sockets do
						if tonumber(self.sockets[index].status) == 1 and tonumber(self.sockets[index].automode) == 1  and tonumber(self.sockets[index].peakconsumer) == 0 and (os.time() > self.sockets[index].lastManualSwitch + HardwareSocketController.AUTOMODE_TEMP_OFF_DURATION) then
							local currentTime = os.time()
							if currentTime - tonumber(self.sockets[index].lastpoweron) - tonumber(self.sockets[index].duration) > 0 then
								local watts = luup.variable_get("urn:micasaverde-com:serviceId:EnergyMetering1", "Watts", self.sockets[index].id)
								local userSuppliedWattage = luup.variable_get("urn:micasaverde-com:serviceId:EnergyMetering1", "UserSuppliedWattage", self.sockets[index].id)
								watts = tonumber(watts)
								userSuppliedWattage = tonumber(userSuppliedWattage)
								
                if  watts == nil then
                   watts = 0
                end
								local watt = watts
              
                if userSuppliedWattage ~= nil and userSuppliedWattage > 0 then
                  watt = userSuppliedWattage
                end
								 
                luup.log("Watt: "..watt, 02)
								if tonumber(batteryPriority) > tonumber(self.sockets[index].priority) and tonumber(self.sockets[index].priority) ~= 0 then
									if 0 > pvPower - (consumption - watt) - tonumber(self.sockets[index].threshold) then
										self.sockets[index].SwitchOff()
										self.timeDelaySwitchSocketOff = os.time()
										break									
									end
								elseif tonumber(self.sockets[index].priority) > tonumber(batteryPriority) and tonumber(self.sockets[index].priority) ~= 0 then
                  luup.log("Steckdose: Time="..tonumber(pvPower - (consumption - watt) - chargingPower - tonumber(self.sockets[index].threshold)), 02)
									if 0 > pvPower - (consumption - watt) - chargingPower - tonumber(self.sockets[index].threshold) then
										self.sockets[index].SwitchOff()
										self.timeDelaySwitchSocketOff = os.time()
										break									
										
									end
								end							
							end
							break
						end
					end
				end
			end
		end
    
    
    
    
    self.ProcessDataInOffgridMode = function(soc)
      
      luup.log("ProcessDataInOffgridMode", 02)
      
      soc = tonumber(soc)
      
      luup.log("SOC: "..soc, 02)
      
      -- update values of sockets and check if sockets needs to be turned on or off
      for index in pairs(self.sockets) do
        
        -- update values of socket
        self.sockets[index].UpdateValues()
        
        
        -- check if sockets needs to be turned on
        if (soc >= tonumber(self.sockets[index].socForTurnOn)) and 
           (tonumber(self.sockets[index].status) == 0) and
           (os.time() - self.timeDelaySwitchSocketOn > HardwareSocketController.SOCKET_SWITCHING_DELAY) and
           (tonumber(self.sockets[index].autoModeOffgrid) == 1) then
             
          self.sockets[index].SwitchOn()
          self.timeDelaySwitchSocketOn = os.time()
        end
      
        -- check if sockets needs to be shut off
        if (tonumber(self.sockets[index].socForShutOff) >= soc) and 
           (tonumber(self.sockets[index].status) == 1) and
           (os.time() - self.timeDelaySwitchSocketOff > HardwareSocketController.SOCKET_SWITCHING_DELAY) and
           (tonumber(self.sockets[index].autoModeOffgrid) == 1)  then
          
          self.sockets[index].SwitchOff()
          self.timeDelaySwitchSocketOff = os.time()
        end
        
      end
      
    end
		
		
		
		-- aux functions
		--- Adds a object of class HardwareSocket to self.sockets
		-- @param socket A socket to add
		self.AddSocket = function(socket)
			table.insert(self.sockets, socket)
		end
		
		--- Prints all data of all HardwareSockets
		self.Print = function()
			for index in pairs(self.sockets) do 
		        self.sockets[index].Print() 
		    end
		end
		
		--- Sorts the table self.sockets ascending by id
		self.SortByIdAscending = function()
			local function comp(socket1,socket2)
		        if socket2.id > socket1.id then
		            return true
		        end
		    end
		    
		    table.sort(self.sockets,comp)
		end
		
		--- Sorts the table self.sockets descending by id
		self.SortByIdDescending = function()
			local function comp(socket1,socket2)
		        if socket1.id > socket2.id then
		            return true
		        end
		    end
		    
		    table.sort(self.sockets,comp)
		end
		
		--- Sorts the table self.sockets ascending by priority
		self.SortByPriorityAscending = function()
			local function comp(socket1,socket2)
		        if socket2.priority > socket1.priority then
		            return true
		        end
		    end
		    
		    table.sort(self.sockets,comp)
		end
		
		--- Sorts the table self.sockets descending by priority
		self.SortByPriorityDescending = function()
			local function comp(socket1,socket2)
		        if socket1.priority > socket2.priority then
		            return true
		        end
		    end
		    
		    table.sort(self.sockets,comp)
		end		
		
		self.InitSockets()
		
		-- start record of wattage
    --check sockets if no sockets do not call RecordWattage
    if table.getn(self.sockets) ~= 0 then
      luup.call_delay("RecordWattage", 1, "", 1)  
    end
		
		-- static function RecordWattage
		--- Every second the powers of sockets are accumulated and stored in "WATTAGE_OF_SOCKETS"
		--- Every "LOG_DURATION" (default 180 seconds) the mean of accumulated powers are logged to  "/tmp/prosol/DATA/Sockets_yyyy-mm-dd.csv"
		RecordWattage = function ()				
			local timestamp = os.time()
			
			self.SortByIdAscending()
			for k, v in pairs(self.sockets) do
        
				v.UpdateValues()
        
        local userSuppliedWattageLUUP = luup.variable_get("urn:micasaverde-com:serviceId:EnergyMetering1", "UserSuppliedWattage", v.id)
        local watts = tonumber(v.watts)
        local userSuppliedWattage = tonumber(userSuppliedWattageLUUP)
        
        local watt = 0
        
        if tonumber(v.status) == 1 then
          if userSuppliedWattage ~= nil and userSuppliedWattage > 0 then
            watt = userSuppliedWattage
          else
            watt = watts
          end
          
          if watt > 3500 then
            watt = 3000
          end
          
        end
        
				HardwareSocketController.WATTAGE_OF_SOCKETS[v.id] = HardwareSocketController.WATTAGE_OF_SOCKETS[v.id] + watt
        
			end
			
			
			if timestamp - HardwareSocketController.LAST_WATTAGE_LOG > HardwareSocketController.LOG_DURATION then
			
				local path = "/tmp/prosol/DATA/"
				
				os.execute("mkdir -p "..path)
							
				-- open file in append mode filename like: Sockets_2013-07-15.csv
				file = io.open(path..os.date("Sockets_".."%Y-%m-%d", tonumber(timestamp))..".csv", "a+")
				
        -- if a new file was created (size == 0) old files has to be deleted
				local size = file:seek("end")
				if size == 0 then
					-- delete old files
					Utils.DeleteFilesBefore(path, "Sockets_%d%d%d%d%-%d%d%-%d%d%.csv", (os.time() - (HardwareSocketController.DELETE_FILES_BEFORE) ))
				end
				
				
				-- write content to file
				file:write(os.date("%Y.%m.%d %X",timestamp))
				file:write("\t")
				
				for k, v in pairs(self.sockets) do
          local tempWattage = tonumber(HardwareSocketController.WATTAGE_OF_SOCKETS[v.id])/HardwareSocketController.LOG_DURATION
          tempWattage = math.floor(tempWattage + 0.5)
					file:write(tempWattage)
					file:write("\t")
					
					luup.log("SocketID: "..v.id.." Wattage: "..tempWattage, 02)
					
					HardwareSocketController.WATTAGE_OF_SOCKETS[v.id] = 0	
				end
				
				file:write("\n")	
				
				-- close file
				file:close()
					
				HardwareSocketController.LAST_WATTAGE_LOG = timestamp
			end
		
			luup.call_delay("RecordWattage", 1, "", 1)
		end
		
		return self
	end	
}


