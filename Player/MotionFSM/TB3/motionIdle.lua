local state = {}
state._NAME = ...
require'mcm'
-- IDLE IS A RELAX STATE
-- NOTHING SHOULD BE TORQUED ON HERE!
local Body = require'Body'
local t_entry, t_update

function state.entry()
  print(state._NAME..' Entry' )
  -- Update the time of entry
  local t_entry_prev = t_entry -- When entry was previously called
  t_entry = Body.get_time()
  t_update = t_entry
end

---
--Set actuator commands to resting position, as gotten from joint encoders.
function state.update()
  local t = Body.get_time()
  local t_diff = t - t_update
  t_update = t
  if t-t_entry>0.1 then  return "init" end
end

function state.exit()
  print(state._NAME..' Exit' )
  mcm.set_walk_vel({0,0,0})
end

return state
