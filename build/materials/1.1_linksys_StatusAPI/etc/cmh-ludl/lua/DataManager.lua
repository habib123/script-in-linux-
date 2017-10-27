--- Class DataManager
-- @author Christian Rothaermel
-- @class DataManager
-- @description Creates tables for day values, week values and month values depending on data loaded by GdbReader and updates these tables with current data sent from the battery system

DataManager =
{
	DAYSLOTRESOLUTION = 360,
	WEEKSLOTRESOLUTION = 360 * 7,
	MONTHSLOTRESOLUTION = 360 * 30,
	DAYSECONDS = 86400,
	VALUEARRAYLENGTH = 240,
	
	-- Constructor
	--- Creates a new object of the DataManager class
	-- @return The new object
	new = function()
	
		local self = {}
		
		-- member vars
		self.currentTime = os.time()
		
		self.bufferValueCounter = 0

	    -- buffer for dischargingPower (m01)
	    self.buffer1 = {n=5}
	
	    -- buffer for chargingPower (m02)
	    self.buffer2 = {n=5}
	
	    -- buffer for pvPower (m03)
	    self.buffer3 = {n=5}
	
	    -- buffer for consumption(m04)
	    self.buffer4 = {n=5 }
		
		self.timeOneDayAgo = self.currentTime - (self.currentTime % DataManager.DAYSECONDS) - (DataManager.DAYSECONDS)
		self.timeOneWeekAgo = self.currentTime - (self.currentTime % DataManager.DAYSECONDS) - (DataManager.DAYSECONDS*7)
		self.timeOneMonthAgo = self.currentTime - (self.currentTime % DataManager.DAYSECONDS) - (DataManager.DAYSECONDS*30)
		
		self.dayValueArrayPointer = 0
		self.weekValueArrayPointer = 0
		self.monthValueArrayPointer = 0
		
		self.dtDayValueArrayPointer = self.timeOneDayAgo - (self.timeOneDayAgo%(DataManager.DAYSLOTRESOLUTION)) + (DataManager.DAYSLOTRESOLUTION)
		self.dtWeekValueArrayPointer = self.timeOneWeekAgo - (self.timeOneWeekAgo%(DataManager.WEEKSLOTRESOLUTION)) + (DataManager.WEEKSLOTRESOLUTION)
		self.dtMonthValueArrayPointer = self.timeOneMonthAgo - (self.timeOneMonthAgo%(DataManager.MONTHSLOTRESOLUTION)) + (DataManager.MONTHSLOTRESOLUTION)
		
		self.dtDayValueArrayPointerShouldBe = self.currentTime - (self.currentTime%(DataManager.DAYSLOTRESOLUTION)) + (DataManager.DAYSLOTRESOLUTION)
		self.dtWeekValueArrayPointerShouldBe = self.currentTime - (self.currentTime%(DataManager.WEEKSLOTRESOLUTION)) + (DataManager.WEEKSLOTRESOLUTION)
		self.dtMonthValueArrayPointerShouldBe = self.currentTime - (self.currentTime%(DataManager.MONTHSLOTRESOLUTION)) + (DataManager.MONTHSLOTRESOLUTION)
	
		-- init day values
		self.dayValueArray1 = DataManager.InitValue()
	    self.dayValueArray2 = DataManager.InitValue()
	    self.dayValueArray3 = DataManager.InitValue()
	    self.dayValueArray4 = DataManager.InitValue()
	    
		-- measuring strings for pv, consumption, charge and discharge (for mobile apps)
	    self.dayValue1 = DataManager.InitValueString()
	    self.dayValue2 = DataManager.InitValueString()
	    self.dayValue3 = DataManager.InitValueString()
	    self.dayValue4 = DataManager.InitValueString()
		
		-- init week values
		self.weekValueArray1 = DataManager.InitValue()
	    self.weekValueArray2 = DataManager.InitValue()
	    self.weekValueArray3 = DataManager.InitValue()
	    self.weekValueArray4 = DataManager.InitValue()

		-- measuring strings fpr pv, consumption, charge and discharge (for mobile apps)
	    self.weekValue1 = DataManager.InitValueString()
	    self.weekValue2 = DataManager.InitValueString()
	    self.weekValue3 = DataManager.InitValueString()
	    self.weekValue4 = DataManager.InitValueString()
	    
	    -- init month values
	    self.monthValueArray1 = DataManager.InitValue()
	    self.monthValueArray2 = DataManager.InitValue()
	    self.monthValueArray3 = DataManager.InitValue()
	    self.monthValueArray4 = DataManager.InitValue()

		-- measuring strings fpr pv, consumption, charge and discharge (for mobile apps)
	    self.monthValue1 = DataManager.InitValueString()
	    self.monthValue2 = DataManager.InitValueString()
	    self.monthValue3 = DataManager.InitValueString()
	    self.monthValue4 = DataManager.InitValueString()
		
		
		
		
		-- methods	
		--- Calculates for the last day the mean values of pv, consumption, charging and discharging based slots with lenth of 6 minutes
		-- @param measuringRecordsDay A table of datasets of the last day loaded from GDB files	
		self.PrefillDay = function(measuringRecordsDay)
			
		    local timeStamp = 0
		    local dischargingPower = 0
		    local chargingPower = 0
		    local pvPower = 0
		    local consumption = 0
		    local recordCounter = 0
		
		    for i,v in ipairs(measuringRecordsDay) do
		        local splitDataSet = Utils.Split(v, "\t+")
		
		        local timeStamp = Utils.DateStringToSeconds(splitDataSet[1])
		
		        -- if there was a lack of data
		        while timeStamp > self.dtDayValueArrayPointer + (DataManager.DAYSLOTRESOLUTION) do
		            self.dayValueArrayPointer = (self.dayValueArrayPointer % DataManager.VALUEARRAYLENGTH) + 1
		            self.dayValueArray1[self.dayValueArrayPointer] = -1
		            self.dayValueArray2[self.dayValueArrayPointer] = -1
		            self.dayValueArray3[self.dayValueArrayPointer] = -1
		            self.dayValueArray4[self.dayValueArrayPointer] = -1
		            self.dtDayValueArrayPointer = self.dtDayValueArrayPointer + (DataManager.DAYSLOTRESOLUTION)
		
		            dischargingPower = -1
		            chargingPower = -1
		            pvPower = -1
		            consumption = -1
		            recordCounter = 1
		        end
		
				-- if enough time is gone by write values to the specific array
		        if timeStamp >  self.dtDayValueArrayPointer then
		            self.dayValueArrayPointer = (self.dayValueArrayPointer % DataManager.VALUEARRAYLENGTH) + 1
		            self.dayValueArray1[self.dayValueArrayPointer] = dischargingPower/recordCounter
		            self.dayValueArray2[self.dayValueArrayPointer] = chargingPower/recordCounter
		            self.dayValueArray3[self.dayValueArrayPointer] = pvPower/recordCounter
		            self.dayValueArray4[self.dayValueArrayPointer] = consumption/recordCounter
		            self.dtDayValueArrayPointer = self.dtDayValueArrayPointer + (DataManager.DAYSLOTRESOLUTION)
					
					dischargingPower = splitDataSet[2]
		            chargingPower = splitDataSet[3]
					pvPower = splitDataSet[4]
		            consumption = splitDataSet[5]
		            recordCounter = 1
		        else
		            dischargingPower = dischargingPower + splitDataSet[2]
		            chargingPower = chargingPower + splitDataSet[3]
		            pvPower = pvPower + splitDataSet[4]
		            consumption = consumption + splitDataSet[5]
		            recordCounter = recordCounter + 1
		        end
		    end
			
		    -- while dtDayValueArrayPointerShouldBe > dtDayValueArrayPointer + (daySlotResolution) do
			while self.dtDayValueArrayPointerShouldBe > self.dtDayValueArrayPointer do
		        self.dayValueArrayPointer = (self.dayValueArrayPointer % DataManager.VALUEARRAYLENGTH) + 1
		        self.dayValueArray1[self.dayValueArrayPointer] = -1
		        self.dayValueArray2[self.dayValueArrayPointer] = -1
		        self.dayValueArray3[self.dayValueArrayPointer] = -1
		        self.dayValueArray4[self.dayValueArrayPointer] = -1
		        self.dtDayValueArrayPointer = self.dtDayValueArrayPointer + (DataManager.DAYSLOTRESOLUTION)
		    end
		    
		    self.dayValue1 = ""
		    self.dayValue2 = ""
		    self.dayValue3 = ""
		    self.dayValue4 = ""
			
			-- create the string values (for mobile apps)
		    for i = 1, DataManager.VALUEARRAYLENGTH, 1 do
		        self.dayValue1 = self.dayValue1..self.dayValueArray1[i].."|"
		        self.dayValue2 = self.dayValue2..self.dayValueArray2[i].."|"
		        self.dayValue3 = self.dayValue3..self.dayValueArray3[i].."|"
		        self.dayValue4 = self.dayValue4..self.dayValueArray4[i].."|"
		    end
			
			-- publicate string values
			 luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DayValueArrayPointer", self.dayValueArrayPointer ,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DtDayValueArrayPointer", self.dtDayValueArrayPointer ,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DayValue1", self.dayValue1,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DayValue2", self.dayValue2,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DayValue3", self.dayValue3,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DayValue4", self.dayValue4,lul_device)
		    	    
		end
		
		--- Calculates for the last seven days the mean values of pv, consumption, charging and discharging based slots with lenth of 42 minutes
		-- @param measuringRecordsWeek A table of datasets of the last seven days loaded from GDB files	
		self.PrefillWeek = function(measuringRecordsWeek)
		    local timeStamp = 0
		    local dischargingPower = 0
		    local chargingPower = 0
		    local pvPower = 0
		    local consumption = 0
		    local recordCounter = 0
		
		    for i,v in ipairs(measuringRecordsWeek) do
		        local splittedDataSet = Utils.Split(v, "\t+")
		
		        local timeStamp = Utils.DateStringToSeconds(splittedDataSet[1])
		
		        -- if there was a lack of data
		        while timeStamp > self.dtWeekValueArrayPointer + (DataManager.WEEKSLOTRESOLUTION) do
		            self.weekValueArrayPointer = (self.weekValueArrayPointer % DataManager.VALUEARRAYLENGTH) + 1
		            self.weekValueArray1[self.weekValueArrayPointer] = -1
		            self.weekValueArray2[self.weekValueArrayPointer] = -1
		            self.weekValueArray3[self.weekValueArrayPointer] = -1
		            self.weekValueArray4[self.weekValueArrayPointer] = -1
		            self.dtWeekValueArrayPointer = self.dtWeekValueArrayPointer + (DataManager.WEEKSLOTRESOLUTION)
		
		            dischargingPower = -1
		            chargingPower = -1
		            pvPower = -1
		            consumption = -1
		            recordCounter = 1
		        end
		
				-- if enough time is gone by write values to the specific array
		        if timeStamp > self.dtWeekValueArrayPointer then		
		            self.weekValueArrayPointer = (self.weekValueArrayPointer % DataManager.VALUEARRAYLENGTH) + 1
		            self.weekValueArray1[self.weekValueArrayPointer] = dischargingPower/recordCounter
		            self.weekValueArray2[self.weekValueArrayPointer] = chargingPower/recordCounter
		            self.weekValueArray3[self.weekValueArrayPointer] = pvPower/recordCounter
		            self.weekValueArray4[self.weekValueArrayPointer] = consumption/recordCounter
		            self.dtWeekValueArrayPointer = self.dtWeekValueArrayPointer + (DataManager.WEEKSLOTRESOLUTION)
		
		            dischargingPower = splittedDataSet[2]
		            chargingPower = splittedDataSet[3]
		            pvPower = splittedDataSet[4]
		            consumption = splittedDataSet[5]
		            recordCounter = 1
		        else
		            dischargingPower = dischargingPower + splittedDataSet[2]
		            chargingPower = chargingPower + splittedDataSet[3]
		            pvPower = pvPower + splittedDataSet[4]
		            consumption = consumption + splittedDataSet[5]
		            recordCounter = recordCounter + 1
		        end
		    end
		
		    -- while dtWeekValueArrayPointerShouldBe > dtWeekValueArrayPointer + (weekSlotResolution) do
			while self.dtWeekValueArrayPointerShouldBe > self.dtWeekValueArrayPointer do
		        self.weekValueArrayPointer = (self.weekValueArrayPointer % DataManager.VALUEARRAYLENGTH) + 1
		        self.weekValueArray1[self.weekValueArrayPointer] = -1
		        self.weekValueArray2[self.weekValueArrayPointer] = -1
		        self.weekValueArray3[self.weekValueArrayPointer] = -1
		        self.weekValueArray4[self.weekValueArrayPointer] = -1
		        self.dtWeekValueArrayPointer = self.dtWeekValueArrayPointer + (DataManager.WEEKSLOTRESOLUTION)
		    end
		
			self.weekValue1 = ""
			self.weekValue2 = ""
			self.weekValue3 = ""
			self.weekValue4 = ""
			
			-- create the string values (for mobile apps)
		    for i = 1, DataManager.VALUEARRAYLENGTH, 1 do
		        self.weekValue1 = self.weekValue1..self.weekValueArray1[i].."|"
		        self.weekValue2 = self.weekValue2..self.weekValueArray2[i].."|"
		        self.weekValue3 = self.weekValue3..self.weekValueArray3[i].."|"
		        self.weekValue4 = self.weekValue4..self.weekValueArray4[i].."|"
		    end
			
			-- publicate string values
			 luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","WeekValueArrayPointer", self.weekValueArrayPointer ,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DtWeekValueArrayPointer", self.dtWeekValueArrayPointer ,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","WeekValue1", self.weekValue1,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","WeekValue2", self.weekValue2,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","WeekValue3", self.weekValue3,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","WeekValue4", self.weekValue4,lul_device)
		end
		
		--- Calculates for the last thrity days the mean values of pv, consumption, charging and discharging based slots with lenth of 180 minutes
		-- @param measuringRecordsMonth A table of datasets of the last thirty days loaded from GDB files
		self.PrefillMonth = function(measuringRecordsMonth)
		    local timeStamp = 0
		    local dischargingPower = 0
		    local chargingPower = 0
		    local pvPower = 0
		    local consumption = 0
		    local recordCounter = 0
		
		    for i,v in ipairs(measuringRecordsMonth) do
		        local splittedDataSet = Utils.Split(v, "\t+")
		
		        local timeStamp = Utils.DateStringToSeconds(splittedDataSet[1])
		
		        -- if there was a lack of data
		        while timeStamp > self.dtMonthValueArrayPointer + (DataManager.MONTHSLOTRESOLUTION) do
		            self.monthValueArrayPointer = (self.monthValueArrayPointer % DataManager.VALUEARRAYLENGTH) + 1
		            self.monthValueArray1[self.monthValueArrayPointer] = -1
		            self.monthValueArray2[self.monthValueArrayPointer] = -1
		            self.monthValueArray3[self.monthValueArrayPointer] = -1
		            self.monthValueArray4[self.monthValueArrayPointer] = -1
		            self.dtMonthValueArrayPointer = self.dtMonthValueArrayPointer + (DataManager.MONTHSLOTRESOLUTION)
		
		            dischargingPower = -1
		            chargingPower = -1
		            pvPower = -1
		            consumption = -1
		            recordCounter = 1
		        end
		
		
				-- if enough time is gone by write values to the specific array
		        if timeStamp > self.dtMonthValueArrayPointer then		
		            self.monthValueArrayPointer = (self.monthValueArrayPointer % DataManager.VALUEARRAYLENGTH) + 1
		            self.monthValueArray1[self.monthValueArrayPointer] = dischargingPower/recordCounter
		            self.monthValueArray2[self.monthValueArrayPointer] = chargingPower/recordCounter
		            self.monthValueArray3[self.monthValueArrayPointer] = pvPower/recordCounter
		            self.monthValueArray4[self.monthValueArrayPointer] = consumption/recordCounter
		            self.dtMonthValueArrayPointer = self.dtMonthValueArrayPointer + (DataManager.MONTHSLOTRESOLUTION)
		
		            dischargingPower = splittedDataSet[2]
		            chargingPower = splittedDataSet[3]
		            pvPower = splittedDataSet[4]
		            consumption = splittedDataSet[5]
		            recordCounter = 1
		        else
                if splittedDataSet[5] == nil then
                  splittedDataSet[5] = 0 
                end
                
		            dischargingPower = dischargingPower + splittedDataSet[2]
		            chargingPower = chargingPower + splittedDataSet[3]
		            pvPower = pvPower + splittedDataSet[4]
		            consumption = consumption + splittedDataSet[5]
		            recordCounter = recordCounter + 1
		        end
		    end
		
		    -- while dtMonthValueArrayPointerShouldBe > dtMonthValueArrayPointer + (monthSlotResolution) do
			while self.dtMonthValueArrayPointerShouldBe > self.dtMonthValueArrayPointer do
		        self.monthValueArrayPointer = (self.monthValueArrayPointer % DataManager.VALUEARRAYLENGTH) + 1
		        self.monthValueArray1[self.monthValueArrayPointer] = -1
		        self.monthValueArray2[self.monthValueArrayPointer] = -1
		        self.monthValueArray3[self.monthValueArrayPointer] = -1
		        self.monthValueArray4[self.monthValueArrayPointer] = -1
		        self.dtMonthValueArrayPointer = self.dtMonthValueArrayPointer + (DataManager.MONTHSLOTRESOLUTION)
		    end
		
			
			self.monthValue1 = ""
			self.monthValue2 = ""
			self.monthValue3 = ""
			self.monthValue4 = ""
			
			-- create the string values (for mobile apps)
		    for i = 1, DataManager.VALUEARRAYLENGTH, 1 do
		        self.monthValue1 = self.monthValue1..self.monthValueArray1[i].."|"
		        self.monthValue2 = self.monthValue2..self.monthValueArray2[i].."|"
		        self.monthValue3 = self.monthValue3..self.monthValueArray3[i].."|"
		        self.monthValue4 = self.monthValue4..self.monthValueArray4[i].."|"
		    end
			
			-- publicate string values
			 luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","MonthValueArrayPointer", self.monthValueArrayPointer ,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DtMonthValueArrayPointer", self.dtMonthValueArrayPointer ,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","MonthValue1", self.monthValue1,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","MonthValue2", self.monthValue2,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","MonthValue3", self.monthValue3,lul_device)
		     luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","MonthValue4", self.monthValue4,lul_device)
		end
		
		
		
		--- Calculates the mean values of pv, consumption, charging and discharging if enough time went by (6 minutes)
		-- otherwise the values are buffered.
		-- @param v1 A value which represents the current discharging power
		-- @param v2 A value which represents the current charging power
		-- @param v3 A value which represents the current pv power
		-- @param v4 A value which represents the current consumption
		self.FillDay = function(v1,v2,v3,v4)
		    local dtCurrentTime = os.time()
		    local dtCurrentMessageSlotTime = dtCurrentTime - dtCurrentTime%DataManager.DAYSLOTRESOLUTION		-- e.g. 18:03 - 00:03 == 18:00 (in seconds)
		    local slotDifference = (dtCurrentMessageSlotTime - self.dtDayValueArrayPointer)/DataManager.DAYSLOTRESOLUTION
			
			-- if slotDifference greater 1.0 we can process values of buffer and fill a slot in day array
		    if(slotDifference > 1.0) then
		        local sum1 = 0
		        local sum2 = 0
		        local sum3 = 0
		        local sum4 = 0
		        for i = 1, self.bufferValueCounter, 1 do
		            sum1 = sum1 + self.buffer1[i]
		            sum2 = sum2 + self.buffer2[i]
		            sum3 = sum3 + self.buffer3[i]
		            sum4 = sum4 + self.buffer4[i]
		        end
		
		        if(self.bufferValueCounter == 0) then
		            self.bufferValueCounter = 1
		        end
		
		        -- calc mean
		        local arithmeticMean1 = sum1 / self.bufferValueCounter
		        local arithmeticMean2 = sum2 / self.bufferValueCounter
		        local arithmeticMean3 = sum3 / self.bufferValueCounter
		        local arithmeticMean4 = sum4 / self.bufferValueCounter
		
				-- increase dayValueArrayPointer and write mean to array
		        self.dayValueArrayPointer = (self.dayValueArrayPointer % DataManager.VALUEARRAYLENGTH ) + 1
		        self.dayValueArray1[self.dayValueArrayPointer] = arithmeticMean1
		        self.dayValueArray2[self.dayValueArrayPointer] = arithmeticMean2
		        self.dayValueArray3[self.dayValueArrayPointer] = arithmeticMean3
		        self.dayValueArray4[self.dayValueArrayPointer] = arithmeticMean4
		        self.dtDayValueArrayPointer = self.dtDayValueArrayPointer + DataManager.DAYSLOTRESOLUTION
		        self.bufferValueCounter = 0
		
		        self.dayValue1 = ""
		        self.dayValue2 = ""
		        self.dayValue3 = ""
		        self.dayValue4 = ""
		        for i = 1, DataManager.VALUEARRAYLENGTH, 1 do
		            self.dayValue1 = self.dayValue1..self.dayValueArray1[i].."|"
		            self.dayValue2 = self.dayValue2..self.dayValueArray2[i].."|"
		            self.dayValue3 = self.dayValue3..self.dayValueArray3[i].."|"
		            self.dayValue4 = self.dayValue4..self.dayValueArray4[i].."|"
		        end
		
				-- publicate values
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DayValueArrayPointer", self.dayValueArrayPointer ,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DtDayValueArrayPointer", self.dtDayValueArrayPointer ,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DayValue1", self.dayValue1,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DayValue2", self.dayValue2,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DayValue3", self.dayValue3,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DayValue4", self.dayValue4,lul_device)
		
		        self.FillWeek()
		
		        self.FillMonth()
		    end
		
		    self.bufferValueCounter = self.bufferValueCounter + 1
		
		    -- save received new value
		    self.buffer1[self.bufferValueCounter] = v1
		    self.buffer2[self.bufferValueCounter] = v2
		    self.buffer3[self.bufferValueCounter] = v3
		    self.buffer4[self.bufferValueCounter] = v4
		end
		
		--- Calculates the mean values of pv, consumption, charging and discharging if enough time went by (42 minutes)
		self.FillWeek = function()
			local slotDifferenceWeek = (self.dtDayValueArrayPointer - self.dtWeekValueArrayPointer) / DataManager.WEEKSLOTRESOLUTION

		    -- if slotDifference greater 1.0 we can process values of dayvaluearray and fill a slot in week array
		    if (slotDifferenceWeek > 1.0) then
		        local sum1 = 0
		        local sum2 = 0
		        local sum3 = 0
		        local sum4 = 0
		        local daySlotsToTake = math.floor(DataManager.WEEKSLOTRESOLUTION/DataManager.DAYSLOTRESOLUTION)		
				local recordCountValue1 = daySlotsToTake
				local recordCountValue2 = daySlotsToTake
				local recordCountValue3 = daySlotsToTake
				local recordCountValue4 = daySlotsToTake
				for i=1, daySlotsToTake, 1 do
		            local index = (((self.dayValueArrayPointer - i) + DataManager.VALUEARRAYLENGTH) % DataManager.VALUEARRAYLENGTH) + 1
					
					if self.dayValueArray1[index] == -1 then
						recordCountValue1 = recordCountValue1 - 1
					else
						sum1 = sum1 + (self.dayValueArray1[index])
					end
					
					if self.dayValueArray2[index] == -1 then
						recordCountValue2 = recordCountValue2 - 1
					else
						sum2 = sum2 + (self.dayValueArray2[index])
					end
					
					if self.dayValueArray3[index] == -1 then
						recordCountValue3 = recordCountValue3 - 1
					else
						sum3 = sum3 + (self.dayValueArray3[index])
					end
					
					if self.dayValueArray4[index] == -1 then
						recordCountValue4 = recordCountValue4 - 1
					else
						sum4 = sum4 + (self.dayValueArray4[index])
					end
		        end
		
		        -- calc means
		        local arithmeticMean1
		        local arithmeticMean2
		        local arithmeticMean3
		        local arithmeticMean4
				if(recordCountValue1 == 0) then 
					arithmeticMean1 = -1
				else
					arithmeticMean1 = sum1 / recordCountValue1
				end
				
				if(recordCountValue2 == 0) then 
					arithmeticMean2 = -1
				else
					arithmeticMean2 = sum2 / recordCountValue2
				end
				
				if(recordCountValue3 == 0) then 
					arithmeticMean3 = -1
				else
					arithmeticMean3 = sum3 / recordCountValue3
				end
				
				if(recordCountValue4 == 0) then 
					arithmeticMean4 = -1
				else
					arithmeticMean4 = sum4 / recordCountValue4
				end
		
				-- increase weekValueArrayPointer
		        self.weekValueArrayPointer = (self.weekValueArrayPointer % DataManager.VALUEARRAYLENGTH) + 1
		        self.weekValueArray1[self.weekValueArrayPointer] = arithmeticMean1
		        self.weekValueArray2[self.weekValueArrayPointer] = arithmeticMean2
		        self.weekValueArray3[self.weekValueArrayPointer] = arithmeticMean3
		        self.weekValueArray4[self.weekValueArrayPointer] = arithmeticMean4
		        self.dtWeekValueArrayPointer = self.dtWeekValueArrayPointer + DataManager.WEEKSLOTRESOLUTION
		
		        self.weekValue1 = ""
		        self.weekValue2 = ""
		        self.weekValue3 = ""
		        self.weekValue4 = ""
		        for i = 1, DataManager.VALUEARRAYLENGTH, 1 do
		            self.weekValue1 = self.weekValue1..self.weekValueArray1[i].."|"
		            self.weekValue2 = self.weekValue2..self.weekValueArray2[i].."|"
		            self.weekValue3 = self.weekValue3..self.weekValueArray3[i].."|"
		            self.weekValue4 = self.weekValue4..self.weekValueArray4[i].."|"
		        end
		
				-- publicate values
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","WeekValueArrayPointer", self.weekValueArrayPointer ,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DtWeekValueArrayPointer", self.dtWeekValueArrayPointer ,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","WeekValue1", self.weekValue1,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","WeekValue2", self.weekValue2,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","WeekValue3", self.weekValue3,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","WeekValue4", self.weekValue4,lul_device)
		    end
		end
		
		--- Calculates the mean values of pv, consumption, charging and discharging if enough time went by (180 minutes)
		self.FillMonth = function()
			local slotDifferenceMonth = (self.dtDayValueArrayPointer - self.dtMonthValueArrayPointer) / DataManager.MONTHSLOTRESOLUTION

		    -- if slotDifference greater 1.0 we can process values of weekvaluearray and fill a slot in month array
		    if ( slotDifferenceMonth > 1.0) then
		        local sum1 = 0
		        local sum2 = 0
		        local sum3 = 0
		        local sum4 = 0
		        local daySlotsToTake = math.floor(DataManager.MONTHSLOTRESOLUTION/DataManager.DAYSLOTRESOLUTION)
		        local recordCountValue1 = daySlotsToTake
				local recordCountValue2 = daySlotsToTake
				local recordCountValue3 = daySlotsToTake
				local recordCountValue4 = daySlotsToTake
				for i=1, daySlotsToTake, 1 do
		            local index = (((self.dayValueArrayPointer - i) + DataManager.VALUEARRAYLENGTH) % DataManager.VALUEARRAYLENGTH) + 1
					
					if self.dayValueArray1[index] == -1 then
						recordCountValue1 = recordCountValue1 - 1
					else
						sum1 = sum1 + (self.dayValueArray1[index])
					end
					
					if self.dayValueArray2[index] == -1 then
						recordCountValue2 = recordCountValue2 - 1
					else
						sum2 = sum2 + (self.dayValueArray2[index])
					end
					
					if self.dayValueArray3[index] == -1 then
						recordCountValue3 = recordCountValue3 - 1
					else
						sum3 = sum3 + (self.dayValueArray3[index])
					end
					
					if self.dayValueArray4[index] == -1 then
						recordCountValue4 = recordCountValue4 - 1
					else
						sum4 = sum4 + (self.dayValueArray4[index])
					end
		        end
		
		        -- calc means
		        local arithmeticMean1
		        local arithmeticMean2
		        local arithmeticMean3
		        local arithmeticMean4
				if(recordCountValue1 == 0) then 
					arithmeticMean1 = -1
				else
					arithmeticMean1 = sum1 / recordCountValue1
				end
				
				if(recordCountValue2 == 0) then 
					arithmeticMean2 = -1
				else
					arithmeticMean2 = sum2 / recordCountValue2
				end
				
				if(recordCountValue3 == 0) then 
					arithmeticMean3 = -1
				else
					arithmeticMean3 = sum3 / recordCountValue3
				end
				
				if(recordCountValue4 == 0) then 
					arithmeticMean4 = -1
				else
					arithmeticMean4 = sum4 / recordCountValue4
				end
				
				--increase monthValueArrayPointer
		        self.monthValueArrayPointer = (self.monthValueArrayPointer % DataManager.VALUEARRAYLENGTH) + 1
		        self.monthValueArray1[self.monthValueArrayPointer] = arithmeticMean1
		        self.monthValueArray2[self.monthValueArrayPointer] = arithmeticMean2
		        self.monthValueArray3[self.monthValueArrayPointer] = arithmeticMean3
		        self.monthValueArray4[self.monthValueArrayPointer] = arithmeticMean4
		        self.dtMonthValueArrayPointer = self.dtMonthValueArrayPointer + DataManager.MONTHSLOTRESOLUTION
		
		        self.monthValue1 = ""
		        self.monthValue2 = ""
		        self.monthValue3 = ""
		        self.monthValue4 = ""
		        for i = 1, DataManager.VALUEARRAYLENGTH, 1 do
		            self.monthValue1 = self.monthValue1..self.monthValueArray1[i].."|"
		            self.monthValue2 = self.monthValue2..self.monthValueArray2[i].."|"
		            self.monthValue3 = self.monthValue3..self.monthValueArray3[i].."|"
		            self.monthValue4 = self.monthValue4..self.monthValueArray4[i].."|"
		        end
		
				-- publicate values
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","MonthValueArrayPointer", self.monthValueArrayPointer ,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","DtMonthValueArrayPointer", self.dtMonthValueArrayPointer ,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","MonthValue1", self.monthValue1,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","MonthValue2", self.monthValue2,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","MonthValue3", self.monthValue3,lul_device)
		         luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","MonthValue4", self.monthValue4,lul_device)
		    end
		end
		
		
		
		
		--- Publishes content of measuringData and extracts charging power, discharging power, consumption and pv power from measuringData and
		-- calls FillDay
		-- @param measuringData A table which contains measuring Data from the connected PLC
		self.ProcessData = function(measuringData)
			self.PublishData(measuringData)	
			
			-- buffer for dischargingPower (m01)

    		-- buffer for chargingPower (m02)

    		-- buffer for pvPower (m03)

    		-- buffer for consumption(m04)
    		
    		if measuringData.data["M01"] ~= nil and
    			measuringData.data["M02"] ~= nil and
    			measuringData.data["M03"] ~= nil and
    			measuringData.data["M04"] ~= nil then
    			
    			self.FillDay(measuringData.data["M01"], measuringData.data["M02"], measuringData.data["M03"], measuringData.data["M04"])
			end
    		
		end
		
		--- Publishes content of measuringData 
		-- @param measuringData A table which contains measuring Data from the connected PLC
		self.PublishData = function(measuringData)
			
			-- M05
			local oldSoc = luup.variable_get("urn:upnp-org:serviceId:PSBatterie1","SOC",lul_device)			
			if measuringData.data["M05"] ~= nil and tonumber(measuringData.data["M05"]) ~= tonumber(oldSoc) then
				luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","SOC", measuringData.data["M05"] ,lul_device)				
			end

			-- M06
			local oldOperatingMode = luup.variable_get("urn:upnp-org:serviceId:PSBatterie1","OperatingMode",lul_device)	
			if measuringData.data["M06"] ~= nil and tonumber(measuringData.data["M06"]) ~= tonumber(oldOperatingMode) then
				luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","OperatingMode", measuringData.data["M06"],lul_device)				
			end
			
			-- S01
			local oldBatteryCapacity = luup.variable_get("urn:upnp-org:serviceId:PSBatterie1","BatteryCapacity",lul_device)
			if measuringData.data["S01"] ~= nil and tonumber(measuringData.data["S01"]) ~= tonumber(oldBatteryCapacity) then
				luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","BatteryCapacity", measuringData.data["S01"] ,lul_device)				
			end
			
			-- S02
			local oldPvPeakPower = luup.variable_get("urn:upnp-org:serviceId:PSBatterie1","InstalledPvPower",lul_device)
			if measuringData.data["S02"] ~= nil and tonumber(measuringData.data["S02"]) ~= tonumber(oldPvPeakPower) then
				luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","InstalledPvPower", measuringData.data["S02"] ,lul_device)
			end
			
			-- S15
			local oldSerialNumber = luup.variable_get("urn:upnp-org:serviceId:PSBatterie1","SerialNumber",lul_device)
			if measuringData.data["S15"] ~= nil and tonumber(measuringData.data["S15"]) ~= tonumber(oldSerialNumber) then
				luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","SerialNumber", measuringData.data["S15"] ,lul_device)
		
				-- set name
				local newDeviceName = "Sonnenbatterie".." #"..measuringData.data["S15"]
				luup.attr_set("name", newDeviceName,  lul_device)
			end
			
			-- S16
			local oldVersionPlc = luup.variable_get("urn:upnp-org:serviceId:PSBatterie1","VersionSPS",lul_device)
			if measuringData.data["S16"] ~= nil and tonumber(measuringData.data["S16"]) ~= tonumber(oldVersionPlc) then
				luup.variable_set("urn:upnp-org:serviceId:PSBatterie1","VersionSPS", measuringData.data["S16"] ,lul_device)
			end
			
		end
		
		
		
		return self
	end,
	
	-- Aux Methods
	--- Initializes a string with length 240 with |-1|...|-1|
	-- @return The initialized string
	InitValueString = function()
		local retval = ""
		
		 for i = 1, DataManager.VALUEARRAYLENGTH, 1 do
	        retval = retval.."-1|"
	    end
	    
	    return retval
	end,
	
	--- Initializes a table with length 240 with |-1|...|-1|
	-- @return The initialized table
	InitValue = function()
		local retval = {n = DataManager.VALUEARRAYLENGTH}
		
		 for i = 1, DataManager.VALUEARRAYLENGTH, 1 do
	        retval[i] = -1
	    end
	    
	    return retval
	end,
}