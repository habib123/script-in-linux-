--- Class DeviceController
-- @author Christian Rothaermel
-- @class DeviceController
-- @description DeviceController contains all additional devices (photovoltaics, heatpump, ownconsumptionrealy, chp, total consumption and the battery device itself), publicates current values of the devices to luup engine and logs status changes of ownconsumptionrelay

DeviceController=
{
	-- service ids of devices
	PSBATTERIE_SERVICEID = "urn:upnp-org:serviceId:PSBatterie1",
	
	BATTERY_SERVICEID = "urn:psi-storage-com:serviceId:Battery1",
	PHOTOVOLTAICS_SERVICEID = "urn:psi-storage-com:serviceId:Photovoltaics1",
	HEATPUMP_SERVICEID = "urn:psi-storage-com:serviceId:Heatpump1",
	OWNCONSUMPTIONRELAY_SERVICEID = "urn:psi-storage-com:serviceId:OwnConsumptionRelay1",
	CHP_SERVICEID = "urn:psi-storage-com:serviceId:CHP1",
	TOTALCONSUMPTION_SERVICEID = "urn:psi-storage-com:serviceId:TotalConsumption1",
	
	PHOTOVOLTAICS_DEFAULT = 1,
	HEATPUMP_DEFAULT = 1,
	CHP_DEFAULT = 1,
	TOTALCONSUMPTION_DEFAULT = 1,
	OWNCONSUMPTIONRELAY_DEFAULT = 1,
	
	
	DELETE_FILES_BEFORE = (60 * 60 * 24 * 60), -- files that are older than 60 days will be deleted
	
	--- Creates a new object of class DeviceController
	-- @return The new object
	new = function(lul_device, numberOfPv, numberOfTotalConsumption, numberOfHeatpump, numberOfCHP, numberOfOwnConsumptionRelay)
		local self = {}
		
		self.parentDevice = lul_device
		self.nOfPv = numberOfPv
		self.nOfTotalConsumption = numberOfTotalConsumption
		self.nOfHeatpump = numberOfHeatpump
		self.nOfCHP = numberOfCHP
		self.nOfOwnConsumptionRelay = numberOfOwnConsumptionRelay
		
		self.child_id_lookup_table = {}
		
		--- Initializes the battery device with data form luup
		self.initBatteryDevice = function()
			-- Legacy --
			-- current operation mode of the battery system send by plc
		    if luup.variable_get(DeviceController.PSBATTERIE_SERVICEID, "OperatingMode", self.parentDevice) == nil then
		        luup.variable_set(DeviceController.PSBATTERIE_SERVICEID,"OperatingMode", -1 ,self.parentDevice)
		    end
		
			-- capacity of the battery send by plc 
		    if luup.variable_get(DeviceController.PSBATTERIE_SERVICEID, "BatteryCapacity", self.parentDevice) == nil then
		        luup.variable_set(DeviceController.PSBATTERIE_SERVICEID, "BatteryCapacity", -1 ,self.parentDevice)
		    end
		
			-- current soc of the battery send by plc
		    if luup.variable_get(DeviceController.PSBATTERIE_SERVICEID, "SOC", self.parentDevice) == nil then
		        luup.variable_set(DeviceController.PSBATTERIE_SERVICEID,"SOC", -1 ,self.parentDevice)
		    end
		
			-- power of the installed solar panel send by plc
		    if luup.variable_get(DeviceController.PSBATTERIE_SERVICEID, "InstalledPvPower", self.parentDevice) == nil then
		        luup.variable_set(DeviceController.PSBATTERIE_SERVICEID,"InstalledPvPower", -1 ,self.parentDevice)
		    end
		    
		    if luup.variable_get(DeviceController.PSBATTERIE_SERVICEID, "AutoSocket1", self.parentDevice) == nil then
		        luup.variable_set(DeviceController.PSBATTERIE_SERVICEID, "AutoSocket1", 0, self.parentDevice)
		    end
		    
		    if luup.variable_get(DeviceController.PSBATTERIE_SERVICEID, "AutoSocket2", self.parentDevice) == nil then
		        luup.variable_set(DeviceController.PSBATTERIE_SERVICEID, "AutoSocket2", 0, self.parentDevice)
		    end
		    
		    if luup.variable_get(DeviceController.PSBATTERIE_SERVICEID, "AutoSocket3", self.parentDevice) == nil then
		        luup.variable_set(DeviceController.PSBATTERIE_SERVICEID, "AutoSocket3", 0, self.parentDevice)
		    end
		    -- /Legacy --
			
			
			local versionPlugin = "3.7"
			luup.variable_set(DeviceController.BATTERY_SERVICEID, "VersionSmartFunction", versionPlugin, self.parentDevice)
      luup.variable_set(DeviceController.BATTERY_SERVICEID, "S70", versionPlugin, self.parentDevice)
            
      local buildNumber = "21"
      
			luup.variable_set(DeviceController.BATTERY_SERVICEID, "BuildNumber", buildNumber, self.parentDevice)
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"Watts", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"Watts", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"WattsDischarge", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"WattsDischarge", -1, self.parentDevice)
			end		
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"WattsCharge", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"WattsCharge", -1, self.parentDevice)		
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"SOC", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"SOC", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"OperationMode", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"OperationMode", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"Temperature", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"Temperature", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"ChargingContactor", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"ChargingContactor", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"ConsumptionContactor", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"ConsumptionContactor", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"NoCharging", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"NoCharging", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"Capacity", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"Capacity", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"ChargingPowerManual", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"ChargingPowerManual", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"ChargingBuffer", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"ChargingBuffer", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"SwitchingThresholdGrid", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"SwitchingThresholdGrid", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"SwitchingThresholdBattery", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"SwitchingThresholdBattery", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"SerialNumber", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"SerialNumber", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"VersionPLC", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"VersionPLC", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"NominalVoltage", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"NominalVoltage", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"Priority", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"Priority", 1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"LowerLimitSoc", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"LowerLimitSoc", -1, self.parentDevice)
			end
			
			if luup.variable_get(DeviceController.BATTERY_SERVICEID,"Location", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"Location", -1, self.parentDevice)
			end
      
      if luup.variable_get(DeviceController.BATTERY_SERVICEID,"LastOperationModeChange", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"LastOperationModeChange", -1, self.parentDevice)
			end
      
      if luup.variable_get(DeviceController.BATTERY_SERVICEID,"LastValidData", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"LastValidData", -1, self.parentDevice)
			end
      
      if luup.variable_get(DeviceController.BATTERY_SERVICEID,"C07", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"C07", 0, self.parentDevice)
			end
      
      if luup.variable_get(DeviceController.BATTERY_SERVICEID,"C08", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"C08", 0, self.parentDevice)
			end
      
      if luup.variable_get(DeviceController.BATTERY_SERVICEID,"C09", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"C09", 0, self.parentDevice)
			end
      
      if luup.variable_get(DeviceController.BATTERY_SERVICEID,"C10", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"C10", 0, self.parentDevice)
			end
      
      if luup.variable_get(DeviceController.BATTERY_SERVICEID,"C11", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"C11", 0, self.parentDevice)
			end
      
      if luup.variable_get(DeviceController.BATTERY_SERVICEID,"C12", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"C12", 0, self.parentDevice)
			end
      
      if luup.variable_get(DeviceController.BATTERY_SERVICEID,"C23", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"C23", 0, self.parentDevice)
			end
      
      if luup.variable_get(DeviceController.BATTERY_SERVICEID,"C24", self.parentDevice) == nil then
				luup.variable_set(DeviceController.BATTERY_SERVICEID,"C24", 0, self.parentDevice)
			end
			
			local newDeviceName = "Sonnenbatterie #"..luup.variable_get(DeviceController.BATTERY_SERVICEID,"SerialNumber", self.parentDevice)
			luup.attr_set("name", newDeviceName,  self.parentDevice)
			
      
			
			self.GetNumberOfAdditionalDevices()	
			
		end
		
		--- Reads the number of additional devices such as Photovoltaics, Heatpump, CHP and TotalConsumption from luup
		self.GetNumberOfAdditionalDevices = function()
		
			-- number of photovoltaics
			self.nOfPv = luup.variable_get(DeviceController.BATTERY_SERVICEID, "NumberOfPhotovoltaics", self.parentDevice)
	        if (self.nOfPv == nil) then
	            self.nOfPv = DeviceController.PHOTOVOLTAICS_DEFAULT
	            luup.variable_set(DeviceController.BATTERY_SERVICEID, "NumberOfPhotovoltaics", self.nOfPv, self.parentDevice)
	        end
			
			-- number of heatpumps
			self.nOfHeatpump = luup.variable_get(DeviceController.BATTERY_SERVICEID, "NumberOfHeatpumps", self.parentDevice)
	        if (self.nOfHeatpump == nil) then
	            self.nOfHeatpump = DeviceController.HEATPUMP_DEFAULT
	            luup.variable_set(DeviceController.BATTERY_SERVICEID, "NumberOfHeatpumps", self.nOfHeatpump, self.parentDevice)
	        end	
			
			-- number of chps
			self.nOfCHP = luup.variable_get(DeviceController.BATTERY_SERVICEID, "NumberOfCHPs", self.parentDevice)
	        if (self.nOfCHP == nil) then
	            self.nOfCHP = DeviceController.CHP_DEFAULT
	            luup.variable_set(DeviceController.BATTERY_SERVICEID, "NumberOfCHPs", self.nOfCHP, self.parentDevice)
	        end
			
			-- number of totalconsumption
			self.nOfTotalConsumption = luup.variable_get(DeviceController.BATTERY_SERVICEID, "NumberOfTotalConsumptions", self.parentDevice)
	        if (self.nOfTotalConsumption == nil) then
	            self.nOfTotalConsumption = DeviceController.TOTALCONSUMPTION_DEFAULT
	            luup.variable_set(DeviceController.BATTERY_SERVICEID, "NumberOfTotalConsumptions", self.nOfTotalConsumption,self. parentDevice)
	        end
	        
	        -- number of ownconsumptionrelay
			self.nOfOwnConsumptionRelay = luup.variable_get(DeviceController.BATTERY_SERVICEID, "NumberOfOwnConsumptionRelais", self.parentDevice)
	        if (self.nOfOwnConsumptionRelay == nil) then
	            self.nOfOwnConsumptionRelay = DeviceController.OWNCONSUMPTIONRELAY_DEFAULT
	            luup.variable_set(DeviceController.BATTERY_SERVICEID, "NumberOfOwnConsumptionRelais", self.nOfOwnConsumptionRelay,self. parentDevice)
	        end
		end
		
		--- Creates additional devices such as Photovoltaics, Heatpump, CHP and TotalConsumption 
		self.createDevices = function()
			
			local children = luup.chdev.start(self.parentDevice)	
			-- create Photovoltaics
			if(tonumber(self.nOfPv) > 0) then
				for i = 1, self.nOfPv do
					luup.chdev.append(self.parentDevice, children,
	                string.format("Photovoltaics-%d", i), string.format("Photovoltaik %d", i),
	                "urn:schemas-psi-storage-com:device:Photovoltaics:1", "D_Photovoltaics1.xml",
	                "", "urn:psi-storage-com:serviceId:Photovoltaics1,Watts=0\n"..
					"urn:psi-storage-com:serviceId:Photovoltaics1,MaxFeedIn=0\n"..
					"urn:psi-storage-com:serviceId:Photovoltaics1,PvPeakPower=0",true)
				end
			end
			
			-- create Heatpumps
			if(tonumber(self.nOfHeatpump) > 0) then
				for i = 1, self.nOfHeatpump do
					luup.chdev.append(self.parentDevice, children,
	                string.format("Heatpump-%d", i), string.format("Waermepumpe %d", i),
	                "urn:schemas-psi-storage-com:device:Heatpump:1", "D_Heatpump1.xml",
	                "", "urn:psi-storage-com:serviceId:Heatpump1,IsHeatPumpGrid=0\n"..
					"urn:psi-storage-com:serviceId:Heatpump1,IsHeatPumpBattery=0\n"..
					"urn:psi-storage-com:serviceId:Heatpump1,IsHeatPumpInstalled=0", true)
				end
			end
			
			-- create CHPs
			if(tonumber(self.nOfCHP) > 0) then
				for i = 1, self.nOfCHP do
					luup.chdev.append(self.parentDevice, children,
	                string.format("CHP-%d", i), string.format("BHKW %d", i),
	                "urn:schemas-psi-storage-com:device:CHP:1", "D_CHP1.xml",
	                "", "urn:psi-storage-com:serviceId:CHP1,Watts=0\n"..
					"urn:psi-storage-com:serviceId:CHP1,CHPPeakPower=0\n", true)
				end
			end
			
			-- create TotalConsumption			
			if(tonumber(self.nOfTotalConsumption) > 0) then
				for i = 1, self.nOfTotalConsumption do
					luup.chdev.append(self.parentDevice, children,
	                string.format("TotalConsumption-%d", i), string.format("Gesamtverbauch %d", i),
	                "urn:schemas-psi-storage-com:device:TotalConsumption:1", "D_TotalConsumption1.xml",
	                "", "urn:psi-storage-com:serviceId:TotalConsumption1,Watts=0\n"..
					"urn:psi-storage-com:serviceId:TotalConsumption1,WattsL1=0\n"..
					"urn:psi-storage-com:serviceId:TotalConsumption1,WattsL2=0\n"..
					"urn:psi-storage-com:serviceId:TotalConsumption1,WattsL3=0\n"..
					"urn:psi-storage-com:serviceId:TotalConsumption1,MaxWattsL1=0\n"..
					"urn:psi-storage-com:serviceId:TotalConsumption1,MaxWattsL2=0\n"..
					"urn:psi-storage-com:serviceId:TotalConsumption1,MaxWattsL3=0\n"..
					"urn:psi-storage-com:serviceId:TotalConsumption1,IsCounterCumulated=0", true)
				end
			end
			
			-- create OwnConsumptionRelays
			if(tonumber(self.nOfOwnConsumptionRelay) > 0) then
				for i = 1, self.nOfOwnConsumptionRelay do
					luup.chdev.append(parentDevice, children,
	                string.format("OwnConsumptionRelay-%d", i), string.format("Eigenverbrauchsrelais %d", i),
	                "urn:schemas-psi-storage-com:device:OwnConsumptionRelay:1", "D_OwnConsumptionRelay1.xml",				
	                "", "urn:psi-storage-com:serviceId:OwnConsumptionRelay1,AutoMode=0\n"..
					"urn:psi-storage-com:serviceId:OwnConsumptionRelay1,Duration=0\n"..
					"urn:psi-storage-com:serviceId:OwnConsumptionRelay1,Threshold=0\n"..
					"urn:psi-storage-com:serviceId:OwnConsumptionRelay1,Status=0\n", true)
				end
			end
			
			luup.chdev.sync(self.parentDevice, children)
			
			------------------------------------------------------------
			-- Find my children and build lookup table of altid -> id
			------------------------------------------------------------
			-- loop over all the devices registered on Vera			
			for k, v in pairs(luup.devices) do
				 -- if I am the parent device
				 
				 if v.device_num_parent == luup.device then
					 self.child_id_lookup_table[v.id] = k
				 end
			end
		end		
		
		
		
		--- Publishes the content of assigned table (measuringData) to the specific device
		-- @param measuringData A object of MeasuringData
		self.PublishData = function(measuringData)
		
			local devices = {}
			for k, v in pairs(luup.devices) do
				 -- if I am the parent device
				 
				 if v.device_num_parent == luup.device then
					 devices[v.id] = k
				 end
			end
			self.child_id_lookup_table = devices
			
			
			-- legacy variables operatingmode, batterycapacity, soc, installed pv power
			local oldSoc = luup.variable_get(DeviceController.PSBATTERIE_SERVICEID, "SOC", self.parentDevice)	
			if measuringData.data["M05"] ~= nil and tonumber(measuringData.data["M05"]) ~= tonumber(oldSoc) then
				luup.variable_set(DeviceController.PSBATTERIE_SERVICEID, "SOC", measuringData.data["M05"], self.parentDevice)
			end
			
			local oldOperationMode = luup.variable_get(DeviceController.PSBATTERIE_SERVICEID, "OperatingMode", self.parentDevice)
			if measuringData.data["M06"] ~= nil and tonumber(measuringData.data["M06"]) ~= tonumber(oldOperationMode) then
				luup.variable_set(DeviceController.PSBATTERIE_SERVICEID, "OperatingMode", measuringData.data["M06"], self.parentDevice)
			end
			
			local oldCapacity = luup.variable_get(DeviceController.PSBATTERIE_SERVICEID, "BatteryCapacity", self.parentDevice)
			if measuringData.data["S01"] ~= nil and tonumber(measuringData.data["S01"]) ~= tonumber(oldCapacity) then
				luup.variable_set(DeviceController.PSBATTERIE_SERVICEID, "BatteryCapacity", measuringData.data["S01"], self.parentDevice)
			end
			
			local oldPvPeakPower = luup.variable_get(DeviceController.PSBATTERIE_SERVICEID, "InstalledPvPower", self.parentDevice)
			if measuringData.data["S02"] ~= nil and tonumber(measuringData.data["S02"]) ~= tonumber(oldPvPeakPower) then
				luup.variable_set(DeviceController.PSBATTERIE_SERVICEID, "InstalledPvPower", measuringData.data["S02"], self.parentDevice)
			end
			
			
			
			
			
			-- M01 wattsDischarge
			-- M02 wattsCharge
			-- M05 SOC
			-- M06 OperatingMode
			-- M13 Watts
			-- M14 Temperature
			-- M16 ChargingContactor
			-- M17 ConsumptionContactor
			-- M20 NoCharging
			-- S01 BatteryCapacity
			-- S03 ChargingPowerManual
			-- S04 ChargingBuffer
			-- S05 SwitchingThresholdGrid
			-- S06 SwitchingThresholdBattery
			-- S07 Location
			-- S08 LowerLimitSoc 
			-- S15 SerialNumber
			-- S16 VersionSPS
			-- S19 NominalVoltage

			-- BATTERY
			local oldWattsDischarge = luup.variable_get(DeviceController.BATTERY_SERVICEID, "WattsDischarge", self.parentDevice)
			if measuringData.data["M01"] ~= nil and tonumber(measuringData.data["M01"]) ~= tonumber(oldWattsDischarge) then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "WattsDischarge", measuringData.data["M01"], self.parentDevice)
			end
			
			local oldWattsCharge = luup.variable_get(DeviceController.BATTERY_SERVICEID, "WattsCharge", self.parentDevice)
			if measuringData.data["M02"] ~= nil and tonumber(measuringData.data["M02"]) ~= tonumber(oldWattsCharge) then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "WattsCharge", measuringData.data["M02"], self.parentDevice)
			end
				
			local oldSoc = luup.variable_get(DeviceController.BATTERY_SERVICEID, "SOC", self.parentDevice)	
			if measuringData.data["M05"] ~= nil and tonumber(measuringData.data["M05"]) ~= tonumber(oldSoc) then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "SOC", measuringData.data["M05"], self.parentDevice)
			end
			
			local oldOperationMode = luup.variable_get(DeviceController.BATTERY_SERVICEID, "OperationMode", self.parentDevice)
			if measuringData.data["M06"] ~= nil and tonumber(measuringData.data["M06"]) ~= tonumber(oldOperationMode) then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "OperationMode", measuringData.data["M06"], self.parentDevice)
        luup.variable_set(DeviceController.BATTERY_SERVICEID, "LastOperationModeChange", os.time(), self.parentDevice)
			end
			
			local oldWatts = luup.variable_get(DeviceController.BATTERY_SERVICEID, "Watts", self.parentDevice)
			if measuringData.data["M13"] ~= nil and tonumber(measuringData.data["M13"]) ~= tonumber(oldWatts) then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "Watts", measuringData.data["M13"], self.parentDevice)
			end
			
			local oldTemperature = luup.variable_get(DeviceController.BATTERY_SERVICEID, "Temperature", self.parentDevice)
			if measuringData.data["M14"] ~= nil and tonumber(measuringData.data["M14"]) ~= tonumber(oldTemperature) then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "Temperature", measuringData.data["M14"], self.parentDevice)
			end
			
			local oldChargingContactor = luup.variable_get(DeviceController.BATTERY_SERVICEID, "ChargingContactor", self.parentDevice)
			if measuringData.data["M16"] ~= nil and measuringData.data["M16"] ~= oldChargingContactor then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "ChargingContactor", measuringData.data["M16"], self.parentDevice)
			end
			
			local oldConsumptionContactor = luup.variable_get(DeviceController.BATTERY_SERVICEID, "ConsumptionContactor", self.parentDevice)
			if measuringData.data["M17"] ~= nil and measuringData.data["M17"] ~= oldConsumptionContactor then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "ConsumptionContactor", measuringData.data["M17"], self.parentDevice)
			end
			
			local oldNoCharging = luup.variable_get(DeviceController.BATTERY_SERVICEID, "NoCharging", self.parentDevice)
			if measuringData.data["M20"] ~= nil and measuringData.data["M20"] ~= oldNoCharging then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "NoCharging", measuringData.data["M20"], self.parentDevice)
			end
			
			local oldCapacity = luup.variable_get(DeviceController.BATTERY_SERVICEID, "Capacity", self.parentDevice)
			if measuringData.data["S01"] ~= nil and tonumber(measuringData.data["S01"]) ~= tonumber(oldCapacity) then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "Capacity", measuringData.data["S01"], self.parentDevice)
			end
			
			local oldChargingPowerManual = luup.variable_get(DeviceController.BATTERY_SERVICEID, "ChargingPowerManual", self.parentDevice)
			if measuringData.data["S03"] ~= nil and tonumber(measuringData.data["S03"]) ~= tonumber(oldChargingPowerManual) then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "ChargingPowerManual", measuringData.data["S03"], self.parentDevice)
			end
			
			local oldChargingBuffer = luup.variable_get(DeviceController.BATTERY_SERVICEID, "ChargingBuffer", self.parentDevice)
			if measuringData.data["S04"] ~= nil and tonumber(measuringData.data["S04"]) ~= tonumber(oldChargingBuffer) then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "ChargingBuffer", measuringData.data["S04"], self.parentDevice)
			end
			
			local oldSwitchingThresholdGrid = luup.variable_get(DeviceController.BATTERY_SERVICEID, "SwitchingThresholdGrid", self.parentDevice)
			if measuringData.data["S05"] ~= nil and tonumber(measuringData.data["S05"]) ~= tonumber(oldSwitchingThresholdGrid) then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "SwitchingThresholdGrid", measuringData.data["S05"], self.parentDevice)
			end
			
			local oldSwitchingThresholdBattery = luup.variable_get(DeviceController.BATTERY_SERVICEID, "SwitchingThresholdBattery", self.parentDevice)
			if measuringData.data["S06"] ~= nil and tonumber(measuringData.data["S06"]) ~= tonumber(oldSwitchingThresholdBattery) then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "SwitchingThresholdBattery", measuringData.data["S06"], self.parentDevice)
			end
			
			local oldLocation = luup.variable_get(DeviceController.BATTERY_SERVICEID, "Location", self.parentDevice)
			if measuringData.data["S07"] ~= nil and measuringData.data["S07"] ~= oldLocation then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "Location", measuringData.data["S07"], self.parentDevice)
			end
			
			local oldLowerLimitSoc = luup.variable_get(DeviceController.BATTERY_SERVICEID, "LowerLimitSoc", self.parentDevice)
			if measuringData.data["S08"] ~= nil and tonumber(measuringData.data["S08"]) ~= tonumber(oldLowerLimitSoc) then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "LowerLimitSoc", measuringData.data["S08"], self.parentDevice)
			end
			
			local oldSerialNumber = luup.variable_get(DeviceController.BATTERY_SERVICEID, "SerialNumber", self.parentDevice)
			if measuringData.data["S15"] ~= nil and tonumber(measuringData.data["S15"]) ~= tonumber(oldSerialNumber) then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "SerialNumber", measuringData.data["S15"], self.parentDevice)
			end
						
			local oldVersionPLC = luup.variable_get(DeviceController.BATTERY_SERVICEID, "VersionPLC", self.parentDevice)
			if measuringData.data["S16"] ~= nil and measuringData.data["S16"] ~= oldVersionPLC then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "VersionPLC", measuringData.data["S16"], self.parentDevice)
			end
			
			local oldNominalVoltage = luup.variable_get(DeviceController.BATTERY_SERVICEID, "NominalVoltage", self.parentDevice)
			if measuringData.data["S19"] ~= nil and tonumber(measuringData.data["S19"]) ~= tonumber(oldNominalVoltage) then
				luup.variable_set(DeviceController.BATTERY_SERVICEID, "NominalVoltage", measuringData.data["S19"], self.parentDevice)
			end
			-- /Battery --
			
			
			-- PHOTOVOLTAICS --
			-- M03 Watts
			-- S02 PVPeakPower
			-- S41 MaxFeedIn			
			if measuringData.data["M03"] ~= nil and self.child_id_lookup_table["Photovoltaics-1"] then
				local oldPvWatts = luup.variable_get(DeviceController.PHOTOVOLTAICS_SERVICEID, "Watts", self.child_id_lookup_table["Photovoltaics-1"])
				if tonumber(measuringData.data["M03"]) ~= tonumber(oldPvWatts) then
					luup.variable_set(DeviceController.PHOTOVOLTAICS_SERVICEID, "Watts", measuringData.data["M03"], self.child_id_lookup_table["Photovoltaics-1"])
				end
			end
			
			if measuringData.data["S02"] ~= nil and self.child_id_lookup_table["Photovoltaics-1"] then
				local oldPvPeakPower = luup.variable_get(DeviceController.PHOTOVOLTAICS_SERVICEID, "PvPeakPower", self.child_id_lookup_table["Photovoltaics-1"])
				if tonumber(measuringData.data["S02"]) ~= tonumber(oldPvPeakPower) then
					luup.variable_set(DeviceController.PHOTOVOLTAICS_SERVICEID, "PvPeakPower", measuringData.data["S02"], self.child_id_lookup_table["Photovoltaics-1"])
				end
			end
			
			if measuringData.data["S41"] ~= nil and self.child_id_lookup_table["Photovoltaics-1"] then
				local oldMaxFeedIn = luup.variable_get(DeviceController.PHOTOVOLTAICS_SERVICEID, "MaxFeedIn", self.child_id_lookup_table["Photovoltaics-1"])
				if tonumber(measuringData.data["S41"]) ~= tonumber(oldMaxFeedIn) then
					luup.variable_set(DeviceController.PHOTOVOLTAICS_SERVICEID, "MaxFeedIn", measuringData.data["S41"], self.child_id_lookup_table["Photovoltaics-1"])
				end
			end
			-- /Photovoltaics --
			
			
			-- TOTALCONSUMPTION --
			-- M04 Watts
			-- M07 WattsL1
			-- M08 WattsL2
			-- M09 WattsL3
			-- M10 MaxWattsL1
			-- M11 MaxWattsL2
			-- M12 MaxWattsL3
			-- S34 IsCounterCumulated
			if measuringData.data["M04"] ~= nil and self.child_id_lookup_table["TotalConsumption-1"] then
				local oldTotalConsumptionWatts = luup.variable_get(DeviceController.TOTALCONSUMPTION_SERVICEID, "Watts", self.child_id_lookup_table["TotalConsumption-1"])
				if tonumber(measuringData.data["M04"]) ~= tonumber(oldTotalConsumptionWatts) then
					luup.variable_set(DeviceController.TOTALCONSUMPTION_SERVICEID, "Watts", measuringData.data["M04"], self.child_id_lookup_table["TotalConsumption-1"])
				end
			end
			
			if measuringData.data["M07"] ~= nil and self.child_id_lookup_table["TotalConsumption-1"] then
				local oldWattsL1 = luup.variable_get(DeviceController.TOTALCONSUMPTION_SERVICEID, "WattsL1", self.child_id_lookup_table["TotalConsumption-1"])
				if tonumber(measuringData.data["M07"]) ~= tonumber(oldWattsL1) then
					luup.variable_set(DeviceController.TOTALCONSUMPTION_SERVICEID, "WattsL1", measuringData.data["M07"], self.child_id_lookup_table["TotalConsumption-1"])
				end
			end
			
			if measuringData.data["M08"] ~= nil and self.child_id_lookup_table["TotalConsumption-1"] then
				local oldWattsL2 = luup.variable_get(DeviceController.TOTALCONSUMPTION_SERVICEID, "WattsL2", self.child_id_lookup_table["TotalConsumption-1"])
				if tonumber(measuringData.data["M08"]) ~= tonumber(oldWattsL2) then
					luup.variable_set(DeviceController.TOTALCONSUMPTION_SERVICEID, "WattsL2", measuringData.data["M08"], self.child_id_lookup_table["TotalConsumption-1"])
				end
			end
			
			if measuringData.data["M09"] ~= nil and self.child_id_lookup_table["TotalConsumption-1"] then
				local oldWattsL3 = luup.variable_get(DeviceController.TOTALCONSUMPTION_SERVICEID, "WattsL3", self.child_id_lookup_table["TotalConsumption-1"])
				if tonumber(measuringData.data["M09"]) ~= tonumber(oldWattsL3) then
					luup.variable_set(DeviceController.TOTALCONSUMPTION_SERVICEID, "WattsL3", measuringData.data["M09"], self.child_id_lookup_table["TotalConsumption-1"])
				end
			end
			
			if measuringData.data["M10"] ~= nil and self.child_id_lookup_table["TotalConsumption-1"] then
				local oldMaxWattsL1 = luup.variable_get(DeviceController.TOTALCONSUMPTION_SERVICEID, "MaxWattsL1", self.child_id_lookup_table["TotalConsumption-1"])
				if tonumber(measuringData.data["M10"]) ~= tonumber(oldMaxWattsL1) then
					luup.variable_set(DeviceController.TOTALCONSUMPTION_SERVICEID, "MaxWattsL1", measuringData.data["M10"], self.child_id_lookup_table["TotalConsumption-1"])
				end
			end

			if measuringData.data["M11"] ~= nil and self.child_id_lookup_table["TotalConsumption-1"] then
				local oldMaxWattsL2 = luup.variable_get(DeviceController.TOTALCONSUMPTION_SERVICEID, "MaxWattsL2", self.child_id_lookup_table["TotalConsumption-1"])
				if tonumber(measuringData.data["M11"]) ~= tonumber(oldMaxWattsL2) then
					luup.variable_set(DeviceController.TOTALCONSUMPTION_SERVICEID, "MaxWattsL2", measuringData.data["M11"], self.child_id_lookup_table["TotalConsumption-1"])
				end
			end
			
			if measuringData.data["M12"] ~= nil and self.child_id_lookup_table["TotalConsumption-1"] then
				local oldMaxWattsL3 = luup.variable_get(DeviceController.TOTALCONSUMPTION_SERVICEID, "MaxWattsL3", self.child_id_lookup_table["TotalConsumption-1"])
				if tonumber(measuringData.data["M12"]) ~= tonumber(oldMaxWattsL3) then
					luup.variable_set(DeviceController.TOTALCONSUMPTION_SERVICEID, "MaxWattsL3", measuringData.data["M12"], self.child_id_lookup_table["TotalConsumption-1"])
				end
			end
			
			if measuringData.data["S34"] ~= nil and self.child_id_lookup_table["TotalConsumption-1"] then
				local oldIsCounterCumulated = luup.variable_get(DeviceController.TOTALCONSUMPTION_SERVICEID, "IsCounterCumulated", self.child_id_lookup_table["TotalConsumption-1"])
				if measuringData.data["S34"] ~= oldIsCounterCumulated then
					luup.variable_set(DeviceController.TOTALCONSUMPTION_SERVICEID, "IsCounterCumulated", measuringData.data["S34"], self.child_id_lookup_table["TotalConsumption-1"])
				end
			end
			-- /TOTALCONSUMPTION --
			
			
			-- HEATPUMP --
			-- M18 IsHeatPumpGrid
			-- M19 IsHeatPumpBattery
			-- S17 HeatPumpInstalled
			if measuringData.data["M18"] ~= nil and self.child_id_lookup_table["Heatpump-1"] then
				local oldIsHeatPumpGrid = luup.variable_get(DeviceController.HEATPUMP_SERVICEID, "IsHeatPumpGrid", self.child_id_lookup_table["Heatpump-1"])
				if measuringData.data["M18"] ~= oldIsHeatPumpGrid then
					luup.variable_set(DeviceController.HEATPUMP_SERVICEID, "IsHeatPumpGrid", measuringData.data["M18"], self.child_id_lookup_table["Heatpump-1"])
				end
			end
			
			if measuringData.data["M19"] ~= nil and self.child_id_lookup_table["Heatpump-1"] then
				local oldIsHeatPumpBattery = luup.variable_get(DeviceController.HEATPUMP_SERVICEID, "IsHeatPumpBattery", self.child_id_lookup_table["Heatpump-1"])
				if measuringData.data["M19"] ~= oldIsHeatPumpBattery then
					luup.variable_set(DeviceController.HEATPUMP_SERVICEID, "IsHeatPumpBattery", measuringData.data["M19"], self.child_id_lookup_table["Heatpump-1"])
				end
			end
			
			if measuringData.data["S17"] ~= nil and self.child_id_lookup_table["Heatpump-1"] then
				local oldIsHeatPumpInstalled = luup.variable_get(DeviceController.HEATPUMP_SERVICEID, "IsHeatPumpInstalled", self.child_id_lookup_table["Heatpump-1"])
				if measuringData.data["S17"] ~= oldIsHeatPumpInstalled then
					luup.variable_set(DeviceController.HEATPUMP_SERVICEID, "IsHeatPumpInstalled", measuringData.data["S17"], self.child_id_lookup_table["Heatpump-1"])
				end
			end
			-- /HEATPUMP --
			
			
			-- CHP --
			-- S18 ChpPeakPower
			if measuringData.data["S18"] ~= nil and self.child_id_lookup_table["CHP-1"] then
				local oldChpPeakPower = luup.variable_get(DeviceController.CHP_SERVICEID, "CHPPeakPower", self.child_id_lookup_table["CHP-1"])
				if tonumber(measuringData.data["S18"]) ~= tonumber(oldChpPeakPower) then
					luup.variable_set(DeviceController.CHP_SERVICEID, "CHPPeakPower", measuringData.data["S18"], self.child_id_lookup_table["CHP-1"])
				end
			end
			
			if measuringData.data["M21"] ~= nil and self.child_id_lookup_table["CHP-1"] then
				local chpWatts = 0
				if measuringData.data["M21"] == "FALSE" then
					chpWatts = 0
				else
					local chpPower = luup.variable_get(DeviceController.CHP_SERVICEID, "CHPPeakPower", self.child_id_lookup_table["CHP-1"])					
					chpWatts = chpPower 
				end
				
				luup.variable_set(DeviceController.CHP_SERVICEID, "Watts", chpWatts, self.child_id_lookup_table["CHP-1"])
			end			
			-- /CHP --
			
			
			-- OWNCONSUMPTIONRELAY --
			-- M17 IsOwnConsumptionRelayOn
			-- S43 IsOwnConsumptionRelayAutoMode
			-- S09 OwnConsumptionRelayThreshold
			-- S10 OwnConsumptionRelayDuration
			if measuringData.data["M17"] ~= nil and self.child_id_lookup_table["OwnConsumptionRelay-1"] then
				local oldIsOwnConsumptionRelayOn = luup.variable_get("urn:psi-storage-com:serviceId:OwnConsumptionRelay1", "Status", self.child_id_lookup_table["OwnConsumptionRelay-1"])
				if tonumber(oldIsOwnConsumptionRelayOn) == 0 and measuringData.data["M17"] == "TRUE" then
					luup.variable_set("urn:psi-storage-com:serviceId:OwnConsumptionRelay1", "Status", 1, self.child_id_lookup_table["OwnConsumptionRelay-1"])
					self.LogOwnConsumptionRelayStatus(1)
				elseif tonumber(oldIsOwnConsumptionRelayOn) == 1 and measuringData.data["M17"] == "FALSE" then
					luup.variable_set("urn:psi-storage-com:serviceId:OwnConsumptionRelay1", "Status", 0, self.child_id_lookup_table["OwnConsumptionRelay-1"])
					self.LogOwnConsumptionRelayStatus(0)
				end
			end
			
			if measuringData.data["S43"] ~= nil and self.child_id_lookup_table["OwnConsumptionRelay-1"] then
				local oldIsOwnConsumptionRelayAutoMode = luup.variable_get("urn:psi-storage-com:serviceId:OwnConsumptionRelay1", "AutoMode", self.child_id_lookup_table["OwnConsumptionRelay-1"])
				if tonumber(oldIsOwnConsumptionRelayAutoMode) == 0 and measuringData.data["S43"] == "TRUE" then
					luup.variable_set("urn:psi-storage-com:serviceId:OwnConsumptionRelay1", "AutoMode", 1, self.child_id_lookup_table["OwnConsumptionRelay-1"])
				elseif tonumber(oldIsOwnConsumptionRelayAutoMode) == 1 and measuringData.data["S43"] == "FALSE" then
					luup.variable_set("urn:psi-storage-com:serviceId:OwnConsumptionRelay1", "AutoMode", 0, self.child_id_lookup_table["OwnConsumptionRelay-1"])
				end
			end
			
			if measuringData.data["S09"] ~= nil and self.child_id_lookup_table["OwnConsumptionRelay-1"] then
				local oldOwnConsumptionRelayThreshold = luup.variable_get("urn:psi-storage-com:serviceId:OwnConsumptionRelay1", "Threshold", self.child_id_lookup_table["OwnConsumptionRelay-1"])
				if tonumber(measuringData.data["S09"]) ~= tonumber(oldOwnConsumptionRelayThreshold) then
					luup.variable_set("urn:psi-storage-com:serviceId:OwnConsumptionRelay1", "Threshold", measuringData.data["S09"], self.child_id_lookup_table["OwnConsumptionRelay-1"])
				end
			end
			
			if measuringData.data["S10"] ~= nil and self.child_id_lookup_table["OwnConsumptionRelay-1"] then
				local oldOwnConsumptionRelayDuration = luup.variable_get("urn:psi-storage-com:serviceId:OwnConsumptionRelay1", "Duration", self.child_id_lookup_table["OwnConsumptionRelay-1"])
				if tonumber(measuringData.data["S10"]) ~= tonumber(oldOwnConsumptionRelayDuration) then
					luup.variable_set("urn:psi-storage-com:serviceId:OwnConsumptionRelay1", "Duration", measuringData.data["S10"], self.child_id_lookup_table["OwnConsumptionRelay-1"])
				end
			end
			-- /OWNCONSUMPTIONRELAY --)
			
			self.WriteSettingsToLuup(measuringData)
		end
		
				
		--- Writes all udp values to luup 
		self.WriteSettingsToLuup = function(measuringData)
		
			-- for k,v in pairs(measuringData.data) do
			--	if string.sub(k, 1, 1) == "S" then
			--		luup.log("True", 02)
			--		local temp = luup.variable_get(DeviceController.BATTERY_SERVICEID, k, self.parentDevice)
			--		if temp ~= v then
			--			luup.variable_set(DeviceController.BATTERY_SERVICEID, k, v, self.parentDevice)
			--		end
			--	end 
			-- end
			
			
			for k,v in pairs(measuringData.data) do				
				local temp = luup.variable_get(DeviceController.BATTERY_SERVICEID, k, self.parentDevice)
				if temp ~= v then
					luup.variable_set(DeviceController.BATTERY_SERVICEID, k, v, self.parentDevice)
				end
			end			
		end	
		
			
		
		
		--- Returns the current value of the variable "PvPeakPower" of the first photovoltaic device
		-- @return The current value of the variable "PvPeakPower"
		self.GetPvPeakPower = function()
			local retval = nil
			if self.child_id_lookup_table["Photovoltaics-1"] ~= nil then
				retval = luup.variable_get(DeviceController.PHOTOVOLTAICS_SERVICEID, "PvPeakPower", self.child_id_lookup_table["Photovoltaics-1"])
			end
			
			return retval
		end
		
		--- Returns the current value of the variable "MaxFeedIn" of the first photovoltaic device
		-- @return The current value of the variable "MaxFeedIn"
		self.GetMaxFeedIn = function()
			local retval = nil
			if self.child_id_lookup_table["Photovoltaics-1"] ~= nil then
				retval = luup.variable_get(DeviceController.PHOTOVOLTAICS_SERVICEID, "MaxFeedIn", self.child_id_lookup_table["Photovoltaics-1"])
			end
			
			return retval
		end
    
    
    --- Returns the value for the given identifier
    -- @return The value for the given identifier
    -- @param The identifier
    self.GetValueForIdentifier = function(identifier)
      return luup.variable_get(DeviceController.BATTERY_SERVICEID, identifier, self.parentDevice)
    end
    
		
		--- Prints the id of the parent device
		self.PrintParent = function()
			luup.log ("Parent: "..self.parentDevice, 02)
		end
		
		--- Logs the status of the ownconsoumptionrelay to "/tmp/prosol/DATA/Relay_yyyy-mm-dd.csv"
		-- @param status The current status of the ownconsumptionrelay to log
		self.LogOwnConsumptionRelayStatus = function(status)
			local timestamp = os.time()
			local path = "/tmp/prosol/DATA/"
				
			os.execute("mkdir -p "..path)
									
			-- open file in append mode filename like: Relay_2013-07-15.csv
			file = io.open(path..os.date("Relay_".."%Y-%m-%d", tonumber(timestamp))..".csv", "a+")
			
			local size = file:seek("end")
			if size == 0 then
				-- delete old files
				Utils.DeleteFilesBefore(path, "Relay_%d%d%d%d%-%d%d%-%d%d%.csv", (os.time() - (DeviceController.DELETE_FILES_BEFORE) ))	
			end
			
			-- write content to file
			file:write(os.date("%Y.%m.%d %X",timestamp))
			file:write("\t")			
			file:write(status)			
			file:write("\n")	
			
			-- close file
			file:close()
		end
		
		
		self.initBatteryDevice()
		return self	
	end,
}