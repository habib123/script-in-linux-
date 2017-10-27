RequestLogger=
{
  MAX_FILE_SIZE = 1024 * 512, -- 512 kb
  PATH_REQUEST_LOG_FOLDER = "/tmp/prosol/logs/webserver", -- folder of events for srv
  LOG_FILE_NAME = "Requests.log", -- filename of log of requests
  
  LogRequest = function(timestamp, peername, method, url, parameter)
    
    os.execute("mkdir -p "..RequestLogger.PATH_REQUEST_LOG_FOLDER)
    
    local filePathName = RequestLogger.PATH_REQUEST_LOG_FOLDER.."/"..RequestLogger.LOG_FILE_NAME
    
    -- open file in append mode
		local logfile = io.open(filePathName, "a+")
		
    local size = logfile:seek("end")
    if size > RequestLogger.MAX_FILE_SIZE then
      -- close file
      logfile:close()
      
      -- do backup
      os.execute("mv "..filePathName.." "..string.gsub(filePathName, ".log$", ".bak"))
      
      -- reopen file
      logfile = io.open(filePathName, "a+")
    end
      
      
    if peername == nil then 
      peername = ""
    end
    
    if method == nil then 
      method = ""
    end
    
    if url == nil then 
      url = ""
    end
    
    if parameter == nil then 
      parameter = ""
    end
		
		-- write content to file
		logfile:write(timestamp.."\t")
    logfile:write(peername.."\t")
    logfile:write(method.."\t")
    logfile:write(url.."\t")
    
    logfile:write(parameter.."\n")
    
    -- logfile:write("\n")
		
		-- close file
		logfile:close()
  end,
  
}
