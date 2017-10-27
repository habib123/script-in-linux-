--- Class DataProvider
-- @author Christian Rothaermel
-- @class DataProvider
-- @description DataProvider builds the baseclass of all spezific DataProviders

DataProvider=
{
  --- Creates a new object of class DeviceController
  -- @return The new object
  new = function()
    local self = {}
    
    --- Initializes the created object
    self.Init = function()
    end
    
    
    --- Sets the setpoint for charging power
		-- @param setPoint The setpoint to set for batteries charging power
    self.SetSetpointForChargingPower = function(setPoint)
    end
    
    --- Sets the setpoint for discharging power
		-- @param setPoint The setpoint to set for batteries discharging power10.64.38.181
    self.SetSetpointForDischargingPower = function(setPoint)
    end
  
    --- Sets the measured load for a specific line
    -- @param load The measured load
    -- @param line The corresponding line
    self.SetLoadOnLine = function(measuredLoad, line)
    end
  
    --- Sets the measured production for a specific line
    -- @param load The measured production
    -- @param line The corresponding line    
    self.SetProductionOnLine = function(measuredProduction, line)
    end
    
    
  
    --- Sets the operation mode
		-- @param operationMode The operationmode to set for batteriesystem
    self.SetOperationMode = function(operationMode)
    end
  
    --- Sets the automatic cellcarestatus mode
		-- @param automaticCellCareStatus The status for the automatic cellcare to set
    self.SetAutomaticCellCareStatus = function(automaticCellCareStatus)
    end
  
    self.GetVersionData = function()
    end
    
    self.GetBatteryData = function()
    end
    
    self.GetDataByIdentifier = function(identifier)
    end
  
    self.GetEventData = function()
    end
    
    
    self.Init()
    return self
  end,
}