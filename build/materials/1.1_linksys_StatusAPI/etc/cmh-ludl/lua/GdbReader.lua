--- Class GdbReader 
-- @author Christian Rothaermel
-- @class GdbReader
-- @description GdbReader reads gdb files from an folder and creates tables for historic day values, week values and month values

GdbReader =
{
	DAYSECONDS = 86400,
	
	-- Constructor
	--- Creats a new object of class GdbReader
	-- @return The new object
	new = function(folder)
		local self = {}
		
		-- member vars
		self.folder = folder
		self.currentTime = os.time()
	    self.dateToday = self.currentTime - (self.currentTime % GdbReader.DAYSECONDS)
	    self.dateOneDayAgo = self.currentTime - (self.currentTime % GdbReader.DAYSECONDS) - (GdbReader.DAYSECONDS)
	    self.dateSevenDaysAgo = self.currentTime - (self.currentTime % GdbReader.DAYSECONDS) - (GdbReader.DAYSECONDS*7)
	    self.dateThirtyDaysAgo = self.currentTime - (self.currentTime % GdbReader.DAYSECONDS) - (GdbReader.DAYSECONDS*30)
	    
	    self.timeStampRecordStartForDay = self.currentTime - 1*GdbReader.DAYSECONDS
	    self.timeStampRecordStartForWeek = self.currentTime - 7*GdbReader.DAYSECONDS
	    self.timeStampRecordStartForMonth = self.currentTime - 30*GdbReader.DAYSECONDS
	    
	    self.measuringRecordsDay = {}
	    self.measuringRecordsWeek = {}
	    self.measuringRecordsMonth = {}
		
		-- methods
		
		-- function loadGDB
		--- Reads all available GDB files for the last thirty days
		-- @return A table whichs contains all datasets for the last day
		-- @return A table whichs contains all datasets for the last seven days
		-- @return A table whichs contains all datasets for the last thirty days	 
		self.LoadGdb = function()
      while self.dateToday + GdbReader.DAYSECONDS >= self.dateThirtyDaysAgo 
      do
        local fileName = self.folder..os.date("%Y-%m-%d", self.dateThirtyDaysAgo)..".GDB"
        self.dateThirtyDaysAgo = self.dateThirtyDaysAgo + GdbReader.DAYSECONDS

        if Utils.FileExists(fileName) then
            self.ReadFile(fileName)
        end
      end
      return self.measuringRecordsDay, self.measuringRecordsWeek, self.measuringRecordsMonth
		end
		
		-- function ReadFile
		--- Opens the file with the assigned path (name), discards all headerinformation and populates the tables for the last day, for the last seven days and for the last thrity days
		-- @param name A path of a file to read
		self.ReadFile = function (name)
      local file = io.open(name, "r")
		
      while true do
        local line = file.read(file)
		
        if not line then
            break
        end
			   
			  -- discard headers of gdb files
			  if string.find(line, "File") or
				  string.find(line, "Graph Block No") or
				  string.find(line, "Tag Count") or
				  string.find(line, "Time Span In Sec") or
				  string.find(line, "Start Time") or
				  string.find(line, "Start Time File") or
				  string.find(line, "Stop Time") or
				  string.find(line, "Sample Count") or
				  string.find(line, "Comments") or
				  string.find(line, "Failures") or
				  string.find(line, "#GDB#") or 
				  string.find(line, "DD.MM.YYYY hh:mm:ss") then
			  else
          if line ~= nil and line ~= "" then
            local splitedDataSet = Utils.Split(line, "\t")
            
            if table.getn(splitedDataSet) > 1 then            
              -- parse time of read value line to unix time
              local timeStamp = Utils.DateStringToSeconds(splitedDataSet[1])
        
              -- insert read line in specific list (month, week, day)
              if timeStamp > self.timeStampRecordStartForMonth then
                table.insert(self.measuringRecordsMonth, line)			
              end
        
              if timeStamp > self.timeStampRecordStartForWeek then
                table.insert(self.measuringRecordsWeek, line)
              end
        
              if timeStamp > self.timeStampRecordStartForDay then
                table.insert(self.measuringRecordsDay, line)
              end
            end
          end
			  end        
      end
      io.close(file)
		end
		
		return self
	end,
}