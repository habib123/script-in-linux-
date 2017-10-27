--- Static class Utils
-- @author Christian Rothaermel
-- @class Utils
-- @description Static class for global auxiliary functions
Utils =
{
	-- static function Split
	--- Splits inputstr by sep
	-- splits the assigned string (inputstr) by the assigned seperator (sep).
	-- @param inputstr The string to split
	-- @param sep The seperator to use
	-- @return Returns a table with the split string
	Split = function(inputstr, sep)
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
	end,
	
	-- static function DateToSeconds
	--- Converts the assigned string (dateString) to seconds
	-- @param dateString The string to convert to seconds	
	-- @return The date as seconds
	DateStringToSeconds = function(dateString)
	    local dateTimeSplit = Utils.Split(dateString, " ")
	    date = Utils.Split(dateTimeSplit[1], ".")
	    time = Utils.Split(dateTimeSplit[2], ":")
	
	    Y = date[3]
	    M = date[2]
	    D = date[1]
	    H = time[1]
	    m = time[2]
	    S = time[3]
	
	    return os.time({day=D, year=Y, month=M, hour=H, min=m, sec=S})
	end,
	
	-- static function FileExists
	--- Checks if a file exists
	-- @param name The path with filename to check
	-- @return true if the file exists else false
	FileExists = function(name)			
	    local file = io.open(name, "r")
	    if file ~= nil then
	        io.close(file)
	        return true
	    else
	        return false
	    end
	end,
	
	-- static function FolderExists
	--- Checks if s folder exists
	-- @param folderPathName The path of the folder to check
	-- @return true is the folder exists else false
	FolderExists = function(folderPathName)
		require "lfs"
		if lfs.attributes(folderPathName,"mode") == "directory" then
			return true
		else
			return false
		end
	end,
	
	-- static function DeleteFilesBefore
	--- Deletes all files that are older than "timestamp", matches the assigned "pattern" and are in the assigned "folderPathName"
	-- @param folderPathName The path to the Folder of the files to delete  
	-- @param pattern The pattern which the filename has to match to be deleted
	-- @param timestamp The timestamp which files must be older to be deleted
	DeleteFilesBefore = function(folderPathName, pattern, timestamp)
		require "lfs"
		
		if Utils.FolderExists(folderPathName) then
			for file in lfs.dir(folderPathName) do
				local attributes = lfs.attributes(folderPathName..file)
				if attributes.mode == "file" and timestamp > attributes.modification then
					if pattern == nil and pattern == "" then
						luup.log("Delete file: "..folderPathName..file.." older than "..os.date("%c", timestamp), 02)
            os.remove(folderPathName..file)
          else
            if string.gmatch(file, pattern) ~= nil then
              luup.log("Delete file: "..folderPathName..file.." older than "..os.date("%c", timestamp), 02)
              os.remove(folderPathName..file)
            end
					end
				end
			end
		end
	end
}