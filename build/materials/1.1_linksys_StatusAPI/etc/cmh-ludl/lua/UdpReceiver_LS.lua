 
require ("socket")

UdpReceiver_LS =
{  

--udp = sock.udp()
--udp:setpeername("*", 1202)
--udp:settimeout(0)

new = function(ip, port)
		local self = {}
		
		-- member vars
		self.ip = ip
		self.port = tonumber(port)
		--self.callback = callback
    self.lastValidData = os.time()
    --self.parentDevice = parentDevice
		
		-- init sbIncomingSocket	
		self.sbIncomingSocket = require ("socket")
		self.sbIncomingUdp = self.sbIncomingSocket.udp()
		self.sbIncomingUdp:settimeout(0)
		self.sbIncomingUdp:setsockname('*', self.port)

self.connectToServer = function( ip, port )
--local function connectToServer( ip, port )
    local sock, err = socket.connect( ip, port )
    if sock == nil then
        return false
    end
    sock:settimeout( 0 )
    sock:setoption( "tcp-nodelay", true )   
    sock:send( "we are connected\n" )
    return sock
  end


self.createClientLoop = function(sock, ip, port )
    
    
    local buffer = {}
    local clientPulse
 
    local function cPulse()
        local allData = {}
        local data, err
 
        repeat
            data, err = self.sbIncomingUdp:receive()
            if data then
                allData[#allData+1] = data
            end
            if ( err == "closed" and clientPulse ) then  --try again if connection closed
                connectToServer( ip, port )
                data, err = self.sbIncomingUdp:receive()
                self.Debug(data, 1)
                if data then
                    allData[#allData+1] = data
                end
            end
        until not data
 
        if ( #allData > 0 ) then
            for i, thisData in ipairs( allData ) do
                print( "thisData: ", thisData )
                self.Debug("thisData: ", 1)

                --react to incoming data 
            end
        end
 
        for i, msg in pairs( buffer ) do
            local data, err = self.sbIncomingUdp:send(msg)
            if ( err == "closed" and clientPulse ) then  --try to reconnect and resend
                connectToServer( ip, port )
                data, err = self.sbIncomingUdp:send( msg )
            end
        end
    end
    
    --cPulse()
    --sleep(10)
    --cPulse()
    
    
     --pulse 10 times per second
    --timer=Timer:new()
    --clientPulse = timer.performWithDelay( 100, cPulse, 0 )
      
 
    local function stopClient()
        timer.cancel( clientPulse )  --cancel timer
        clientPulse = nil
        sock:close()
    end
    return stopClient
  end
  
  return self 
end,
}