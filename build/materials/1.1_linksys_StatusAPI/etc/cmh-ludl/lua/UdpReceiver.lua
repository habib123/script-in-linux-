--- Class UdpReceiver
-- @author Christian Rothaermel
-- @class UdpReceiver
-- @description UdpReceiver listens to assigned port and calls the callback if receive was successful
UdpReceiver =
{  
  -- constants
  PERIOD = (10 * 60), -- 10 minutes 
  
	-- Constructor
	--- Creats a new object of class UdpReceiver
	-- @param ip The ip to listen to 
	-- @param port The port to listen to
	-- @param callback The function whichs is called after a upd message was received
	-- @return The new object
	new = function(ip, port, callback, parentDevice)
		local self = {}
		
		-- member vars
		self.ip = ip
		self.port = tonumber(port)
		self.callback = callback
    self.lastValidData = os.time()
    --self.parentDevice = parentDevice
		
		-- init sbIncomingSocket	
		self.sbIncomingSocket = require ("socket")
		self.sbIncomingUdp = self.sbIncomingSocket.udp()
		self.sbIncomingUdp:settimeout(0)
		self.sbIncomingUdp:setsockname('*', self.port)
		
		-- methods
		--- Starts receiving
		-- if a message is received or a timeout occured the in "new" assigned callback function is called
		self.startReceive = function()
						
			-- init message variable
		    local message = nil	
		    local host = nil
		    
			-- receive udpdata from plc
			message, host = self.sbIncomingUdp:receivefrom()
			
			-- let me know if there is no host
			if(host ~= nil) then
				-- print("Host: "..host)
			end
			
			-- show me the received message
			if(message ~= nil) then
				-- print("Message: "..message)
        self.lastValidData = os.time()
				self.callback(host, message)
        --luup.variable_set(DeviceController.BATTERY_SERVICEID,"LastValidData", self.lastValidData, self.parentDevice)
			else
				self.callback(host, "Message Unknown")
			end	
      
      -- reinitialize socket if there was no data over a period of 
      if (os.time() - self.lastValidData) > UdpReceiver.PERIOD then
        --luup.log("Socket_Reset: "..(os.time() - self.lastValidData), 02)
        self.lastValidData = os.time()
        self.reinitialzeSocket()
      end
      
		end
    
    self.reinitialzeSocket = function()
      -- quit webserver if it is running
      --luup.log("Quit Webserver",02)
      os.execute("curl http://127.0.0.1:7979/rest/quit")
      
      -- close socket
      --luup.log("Close Socket",02)
      self.sbIncomingUdp:close()
      
      -- reload luup engine
      --luup.log("Restart Luup engine",02)
      --os.execute("curl http://127.0.0.1:3480/data_request?id=reload")
      
      -- reboot system
      --os.execute("reboot")
      
    end
		
		return self
	end,
}