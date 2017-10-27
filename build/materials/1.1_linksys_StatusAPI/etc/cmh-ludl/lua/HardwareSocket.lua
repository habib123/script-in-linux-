--- Class HardwareSocket
-- @author Christian Rothaermel
-- @class HardwareSocket
-- @description HardwareSocket abstracts the real socket. It contains values from luup engine and can be switched on or off

HardwareSocket =
{
	-- Constructor
	--- Creats a new object of class HardwareSocket
	-- @param id A number which represents the id of a socket device in the luup engine
	-- @return The new object
	new = function(id, parentDevice)
	
		local self = {}
		
		-- member vars
		self.id = id
		self.parentDevice = parentDevice
		self.status = -1
		self.watts = -1
		self.priority = -1
		self.threshold = -1
		self.duration = -1
		self.lastpoweron = -1
		self.automode = -1
		self.peakconsumer = -1
		self.suggestedStatus = -1
    self.lastManualSwitch = -1
    self.socForShutOff = -1
    self.socForTurnOn = -1
    self.autoModeOffgrid = -1
		
		--- Initializes the object with data from the luup engine
		self.Init = function()
			self.UpdateValues()
			self.suggestedStatus = self.status			
		end
	
		--- Prints all data of the object 
		self.Print = function()
			luup.log("ID: "..self.id, 02)
      if self.status == nil then
			   self.status = 0
			end
			luup.log("Status: "..self.status, 02)
			if self.watts == nil then
			   self.watts = 0
			end
			luup.log("Watts: "..self.watts, 02)
			luup.log("Priority: "..self.priority, 02)
			luup.log("Threshold: "..self.threshold, 02)
			luup.log("Duration: "..self.duration, 02)
			luup.log("LastPowerOn: "..self.lastpoweron, 02)
			luup.log("AutoMode: "..self.automode, 02)
			luup.log("PeakConsumer: "..self.peakconsumer, 02)
      if self.suggestedStatus == nil then
			   self.suggestedStatus = 0
			end
			luup.log("SuggestedStatus: "..self.suggestedStatus, 02)
      luup.log("LastManualSwitch: "..self.lastManualSwitch, 02)
      luup.log("SocForShutOff: "..self.socForShutOff, 02)
      luup.log("SocForTurnOn: "..self.socForTurnOn, 02)
      luup.log("AutoModeOffgrid: "..self.autoModeOffgrid, 02)
			luup.log("", 02)
		end
		
		--- Updates all data from luup engine
		self.UpdateValues = function()
			self.status = luup.variable_get("urn:upnp-org:serviceId:SwitchPower1","Status", self.id)
			
			self.watts = luup.variable_get("urn:micasaverde-com:serviceId:EnergyMetering1","Watts", self.id)
		
			self.priority = luup.variable_get("urn:psi-storage-com:serviceId:PsiSwitch1","Priority", self.id)
      self.threshold = luup.variable_get("urn:psi-storage-com:serviceId:PsiSwitch1","Threshold", self.id)
      self.duration = luup.variable_get("urn:psi-storage-com:serviceId:PsiSwitch1","Duration", self.id)
      self.lastpoweron = luup.variable_get("urn:psi-storage-com:serviceId:PsiSwitch1","LastPowerOn", self.id)
      self.automode = luup.variable_get("urn:psi-storage-com:serviceId:PsiSwitch1","AutoMode", self.id)
      self.peakconsumer = luup.variable_get("urn:psi-storage-com:serviceId:PsiSwitch1","PeakConsumer", self.id)
      self.socForShutOff = luup.variable_get("urn:psi-storage-com:serviceId:PsiSwitch1","SocForShutOff", self.id)
      self.socForTurnOn = luup.variable_get("urn:psi-storage-com:serviceId:PsiSwitch1","SocForTurnOn", self.id)
      self.autoModeOffgrid = luup.variable_get("urn:psi-storage-com:serviceId:PsiSwitch1","AutoModeOffgrid", self.id)
		end
		
		--- Switches the socket on
		self.SwitchOn = function()
			self.SwitchSocket(1)			
		end
		
		--- Switches the socket off
		self.SwitchOff = function()
			self.SwitchSocket(0)
		end
		
		--- Switches the socket state to the assigned status (newStatus)
		self.SwitchSocket = function(newStatus)
			local status, errorMsg, jobId, args = luup.call_action("urn:upnp-org:serviceId:SwitchPower1", "SetTarget", {newTargetValue = newStatus}, self.id)
			
			-- job send sucessfully
			if tonumber(status) == 0 then
			
				-- wait for job done
				while true do
					local jobstatus = luup.job.status(jobId, self.id)
					
					
					if tonumber(jobstatus) == 2 or tonumber(jobstatus) == 3 then											
						-- job error or aborted
						break
					elseif tonumber(jobstatus) == 4 then
						-- job done						
						
						if tonumber(newStatus) == 1 then
							luup.variable_set("urn:psi-storage-com:serviceId:PsiSwitch1", "LastPowerOn", os.time(), self.id)
						end
						
						if tonumber(self.peakconsumer) == 1 and tonumber(self.automode) == 1 then
							-- peakconsumer switch
							local eventList = {}
							table.insert(eventList, EventNotifier.CreateEvent("152", self.suggestedStatus, newStatus, self.id, "name:"..luup.devices[self.id].description, self.parentDevice))
							EventNotifier.NotifyEvent(eventList)
						elseif tonumber(self.peakconsumer) == 0 and tonumber(self.automode) == 1 then
							-- automode switch
							local eventList = {}
							table.insert(eventList, EventNotifier.CreateEvent("151", self.suggestedStatus, newStatus, self.id, "name:"..luup.devices[self.id].description, self.parentDevice))
							EventNotifier.NotifyEvent(eventList)
						end
						
						-- if socket is switched on set the suggestedstatus
						self.suggestedStatus = newStatus
						self.UpdateValues()
						break	
					else
						local socket = require("socket")
						 socket.select(nil, nil, 0.1)
					end	
				end
			end
		end
	
	
		self.Init()
		return self
	end,
}