


require ("JSON")


JsonDataProvider=
{

new = function()
		local self = {}
     
    
    --local raw_json_text    = JSON:encode(lua_table_or_value)        -- encode example
    --local pretty_json_text = JSON:encode_pretty(lua_table_or_value) -- "pretty printed" version
    JSON = (loadfile "JSON.lua")() -- one-time load of the routines
    
    
    
self.getAllStatusValues = function()
  
  -- Opens a file in read mode
  file = io.open("/tmp/prosol/status_data", "r")

  -- prints the first line of the file
  -- print(file:read())
  local raw_json_text = file:read("*all")
  -- closes the opened file
  file:close()
  
  return raw_json_text
  
end
    
    -- parses json status data provided by udp_receiver_py  . 
    -- @param key returns value for M or S key
    -- @return Returns a value in string  
self.getStatusValueByKey = function( input_key )


-- Opens a file in read mode
file = io.open("/tmp/prosol/status_data", "r")

-- prints the first line of the file
-- print(file:read())
local raw_json_text = file:read("*all")
-- closes the opened file
file:close()


-- print(raw_json_text)
local lua_value = {}
-- lua_value = JSON:decode(raw_json_text); -- decode data

raw_json_text = raw_json_text:gsub('%"', "")
raw_json_text = raw_json_text:gsub('%}', "")
raw_json_text = raw_json_text:gsub('%{', "")
raw_json_text = raw_json_text:gsub('% ', "")


status_count = 1
 
 for i in string.gmatch(raw_json_text,  "[^,]+") do
   -- print(i)
     for j in string.gmatch(i,  "[^:]+") do
       -- print(j)
       --table.insert(j, lua_value)
       lua_value[status_count] = j
       status_count = status_count + 1
  end
end

local retval = nil

for key, value in ipairs(lua_value) do
  --print(value) 
  if value == input_key then
    print(value)
    index = key + 1
    print(lua_value[index])
    retval = lua_value[index]
  end  
  --print(i, v)  
end
-- nil check
if retval == nil then
  retval = 0
end


return retval

end

return self 
end,

}