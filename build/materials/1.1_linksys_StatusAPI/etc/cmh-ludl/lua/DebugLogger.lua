DebugLogger=
{
  MAX_FILE_SIZE = 1024 * 512, -- 512 kb
  PATH_LOG_FOLDER = "/tmp/prosol/logs/webserver", -- folder of events for srv
  LOG_FILE_NAME = "debug.log", -- filename of log of requests
  
  LogMsg = function(msg)
    
    os.execute("mkdir -p "..DebugLogger.PATH_LOG_FOLDER)
    
    local filePathName = DebugLogger.PATH_LOG_FOLDER.."/"..DebugLogger.LOG_FILE_NAME
    
    -- open file in append mode
		local logfile = io.open(filePathName, "a+")
		
    local size = logfile:seek("end")
    if size > DebugLogger.MAX_FILE_SIZE then
      -- close file
      logfile:close()
      
      -- do backup
      os.execute("mv "..filePathName.." "..string.gsub(filePathName, ".log$", ".bak"))
      
      -- reopen file
      logfile = io.open(filePathName, "a+")
    end
      
		
		-- write content to file
		logfile:write(os.time().."\t")
    logfile:write(msg.."\n")
		
		-- close file
		logfile:close()
  end,
  
}
