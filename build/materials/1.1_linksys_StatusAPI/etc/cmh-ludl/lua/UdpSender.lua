--- Class UdpSender
-- @author Christian Rothaermel
-- @class UdpSender
-- @description Sends data via udp to assigned ip and port

UdpSender=
{
	-- Constructor
	--- Creates a new objectof class UdpSender
	-- @param ip The ip to send the message to
	-- @param port The port to send the message to
	-- @return The new object 
	new = function(ip, port, parentDevice)
		local self = {}
		
		-- member vars
		self.ip = ip
		self.port = port
    self.parentDevice =  parentDevice
		
		-- init sbOutgoingSocket
    self.socket = require ("socket")
    self.socketUdp = self.socket.try(self.socket.udp())
    	
    --- Calls self.SendMessage and handles a exception if fails
    -- @param message The string to send 
    self.Send = function(message)
			local err, errmsg = pcall(self.SendMessage, message)
			
			if err ~= true then
				-- raised an error: take appropriate actions
		    	-- print("Ip: "..self.ip.." and Port: "..self.port.." not reachable!")
		    	-- print("Msg: "..errmsg)
		    end
		end
		
		--- Sends the assigned string (message) to the ip, port
		-- -- @param message The string to send
		self.SendMessage = function(message)
			self.socketUdp:sendto(message, self.ip, self.port)
		end
		
		return self		
	end,
}