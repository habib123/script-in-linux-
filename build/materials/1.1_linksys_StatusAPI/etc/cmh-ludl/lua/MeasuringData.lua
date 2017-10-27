--- Class MeasuringData
-- @author Christian Rothaermel
-- @class MeasuringData
-- @description MeasuringData holds all data currently sent from the battery system

MeasuringData=
{
	new = function()	
		local self = {}
		
		self.data = {}
		
		--- Prints all data 
		self.Print = function()
			for k,v in pairs(self.data) do
				luup.log(k..": "..v)
			end
		end
		
		return self	
	end,
}