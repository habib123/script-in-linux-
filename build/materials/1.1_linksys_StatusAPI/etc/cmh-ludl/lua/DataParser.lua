--- Static Class DataParser
-- @author Christian Rothaermel
-- @class DataParser
-- @description DataParser validates a udp message and recognizes which seperator is used, parses the massage and create a MeasuringData object with current values of battery system 

DataParser =
{
	-- static function ParseSpaceSeperatedMessage
	--- Parses the assinged string (message) by space seperation and fills a object of MeasuringData
	-- @param message The message to parse
	-- @return A partially filled object of MeasuringData 
	ParseSpaceSeperatedMessage = function(message)
	
		local measuringData = MeasuringData.new()
	
		-- M01
		measuringData.data["M01"] = DataParser.GetValueOfVariable(message, "M01")
		
		-- M02
		measuringData.data["M02"] = DataParser.GetValueOfVariable(message, "M02")
		
		-- M03
		measuringData.data["M03"] = DataParser.GetValueOfVariable(message, "M03")
		
		-- M04
		measuringData.data["M04"] = DataParser.GetValueOfVariable(message, "M04")
		
		-- M05
		measuringData.data["M05"] = DataParser.GetValueOfVariable(message, "M05")
		
		-- M06
		measuringData.data["M06"] = DataParser.GetValueOfVariable(message, "M06")
		
		-- S01
		measuringData.data["S01"] = DataParser.GetValueOfVariable(message, "S01")
		
		-- S02
		measuringData.data["S02"] = DataParser.GetValueOfVariable(message, "S02")
		
		-- S15
		measuringData.data["S15"] = DataParser.GetValueOfVariable(message, "S15")
		
		-- S16
		measuringData.data["S16"] = DataParser.GetValueOfVariable(message, "S16")
		
		return measuringData
	end,
	
	
	--- Parses the assinged string (message) by pipe seperation and fills a object of MeasuringData
	-- @param message The message to parse
	-- @return A partially filled object of MeasuringData 
	ParseMessage = function(message)
	
		local measuringData = MeasuringData.new()
	
		-- split message by pipe
		local splitDataSet = Utils.Split(message, "|")
		
		for i,v in ipairs(splitDataSet) do
			
			-- split splitedDataSet by :
			local splitData = Utils.Split(v, ":")
		 
			-- parse list
			if table.getn(splitData) == 2 then
			
				measuringData.data[splitData[1]] = splitData[2]
				
			end
		end
		return measuringData
	end,
	
	--- Searches the assinged string (message) for the assigned variable (variable) and returns the value if variable exists
	-- @param message The message to search
	-- @return The value of the variable else nil
	GetValueOfVariable = function(message, variable)
		local index
		local amount
		local retval = nil
		
		index, amount =  string.find(message, variable)
		if index == nil then
			-- print("Cant find "..variable)
		else
			local temp = string.sub(message, index, index + 10)
			retval = string.sub(temp, string.find(temp, ":") + 1 , string.len(temp))
	        retval = string.gsub(retval, "^%s*(.-)%s*$", "%1")
		end
		
		return retval
	end,
	
	-- static function ValidateUdpMessage
	--- Validates the assigned string (message)
	-- @param message The message to validate
	-- @return true,true if message is space seperated and has the variable "M01"
	-- @return true, false if the message is pipe seperated
	-- @return false, false if the message is invalid
	ValidateUdpMessage = function(message)
	
    local _, pipes = string.gsub(message, "|", "")
		local markers = string.find(message, "M01")
	
		if(pipes == 0 and markers ~=nil) then
			-- valid sentence with space seperation
			return true, true
		elseif(pipes >= 2) then
			-- valid sentence with pipe seperation
			return true, false
		else
			-- non valid sentence
			return false, false
		end
	end,
	
	
	
	
	-- static function GetHash
	--- Returns a hash of the assigned message
	-- @param message The message to parse to
	-- @return The hash of the message
	GetHash = function (message)
		local retval = {}
		local isValid, isSpace = DataParser.ValidateUdpMessage(message)
		
		if isValid then
		
			if isSpace then
				retval["M01"] = DataParser.GetValueOfVariable(message, "M01")
				retval["M02"] = DataParser.GetValueOfVariable(message, "M02")
				retval["M03"] = DataParser.GetValueOfVariable(message, "M03")
				retval["M04"] = DataParser.GetValueOfVariable(message, "M04")
				retval["M05"] = DataParser.GetValueOfVariable(message, "M05")
				retval["M06"] = DataParser.GetValueOfVariable(message, "M06")
				retval["S01"] = DataParser.GetValueOfVariable(message, "S01")
				retval["S02"] = DataParser.GetValueOfVariable(message, "S02")
				retval["S15"] = DataParser.GetValueOfVariable(message, "S15")
				retval["S16"] = DataParser.GetValueOfVariable(message, "S16")
			else
				-- split message by pipe
				local splitDataSet = Utils.Split(message, "|")
		
				for i,v in ipairs(splitDataSet) do
			
					-- split splitedDataSet by :
					local splitData = Utils.Split(v, ":")
					retval[splitData[1]] = splitData[2]
				end
				
			end
			
		end
		
		return retval
		
	end
}


--DataParser =
--{
--	-- static function ParseSpaceSeperatedMessage
--	ParseSpaceSeperatedMessage = function(message)
--	
--		local measuringData = MeasuringData.new()
--	
--		-- M01
--		measuringData.dischargingPower = DataParser.GetValueOfVariable(message, "M01")
--		
--		-- M02
--		measuringData.chargingPower = DataParser.GetValueOfVariable(message, "M02")
--		
--		-- M03
--		measuringData.pvPower = DataParser.GetValueOfVariable(message, "M03")
--		
--		-- M04
--		measuringData.consumption = DataParser.GetValueOfVariable(message, "M04")
--		
--		-- M05
--		measuringData.soc = DataParser.GetValueOfVariable(message, "M05")
--		
--		-- M06
--		measuringData.operatingMode = DataParser.GetValueOfVariable(message, "M06")
--		
--		-- S01
--		measuringData.batteryCapacity = DataParser.GetValueOfVariable(message, "S01")
--		
--		-- S02
--		measuringData.installedPvPower = DataParser.GetValueOfVariable(message, "S02")
--		
--		-- S15
--		measuringData.serialNumber = DataParser.GetValueOfVariable(message, "S15")
--		
--		-- S16
--		measuringData.versionPlc = DataParser.GetValueOfVariable(message, "S16")
--		
--		return measuringData
--	end,
--	
--	ParseMessage = function(message)
--	
--		local measuringData = MeasuringData.new()
--	
--		-- split message by pipe
--		local splitDataSet = Utils.Split(message, "|")
--		
--		for i,v in ipairs(splitDataSet) do
--			
--			-- split splitedDataSet by :
--			local splitData = Utils.Split(v, ":")
--		 
--			-- parse list
--			if table.getn(splitData) == 2 then
--			
--				-- M01: newDischargingPower
--				-- M02: newChargingPower
--				-- M03: newPvPower
--				-- M04: newConsumption
--				-- M05: newSoc
--				-- M06: newOperatingMode
--				-- S01: newBatteryCapacity
--				-- S02: newInstalledPvPower
--				-- S15: newSerialNumber
--				-- S16: newVersionSPS
--				
--				if splitData[1] == "M01" then measuringData.dischargingPower = splitData[2]
--				elseif splitData[1] == "M02" then measuringData.chargingPower = splitData[2]
--				elseif splitData[1] == "M03" then measuringData.pvPower = splitData[2]
--				elseif splitData[1] == "M04" then measuringData.consumption = splitData[2]
--				elseif splitData[1] == "M05" then measuringData.soc = splitData[2]
--				elseif splitData[1] == "M06" then measuringData.operatingMode = splitData[2]	
--				
--				elseif splitData[1] == "S01" then measuringData.batteryCapacity = splitData[2]
--				elseif splitData[1] == "S02" then measuringData.installedPvPower = splitData[2]
--				elseif splitData[1] == "S15" then measuringData.serialNumber = splitData[2]		
--				elseif splitData[1] == "S16" then measuringData.versionPlc = splitData[2]
--				else 
--					-- print("Index: "..splitData[1].."  ".."Value: "..splitData[2])
--				end
--			end
--		end
--		return measuringData
--	end,
--	
--	
--	GetValueOfVariable = function(message, variable)
--		-- get capacity of battery system
--		local index
--		local amount
--		local retval = nil
--		
--		index, amount =  string.find(message, variable)
--		if index == nil then
--			-- print("Cant find "..variable)
--		else
--			local temp = string.sub(message, index, index + 10)
--			retval = string.sub(temp, string.find(temp, ":") + 1 , string.len(temp))
--	        retval = string.gsub(retval, "^%s*(.-)%s*$", "%1")
--		end
--		
--		return retval
--	end,
--	
--	-- static function ValidateUdpMessage
--	ValidateUdpMessage = function(message)
--	
--		local splitPipe = Utils.Split(message, "|")
--		local pipes = table.getn(splitPipe) - 1 
--		local markers = string.find(message, "M01")
--	
--		if(pipes == 0 and markers ~=nil) then
--			-- valid sentence with space seperation
--			return true, true
--		elseif(pipes > 0) then
--			-- valid sentence with pipe seperation
--			return true, false
--		else
--			-- non valid sentence
--			return false, false
--		end
--	end
--}