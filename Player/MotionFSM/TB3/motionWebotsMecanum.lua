local state = {}
state._NAME = ...
require'mcm'
-- IDLE IS A RELAX STATE
-- NOTHING SHOULD BE TORQUED ON HERE!
local Body = require'Body'
local t_entry, t_update, t_debug,t_command
local cmd_vel={0,0,0}
local rossub=require'rossub'
local sub_idx_cmdvel


function state.entry()
  print(state._NAME..' Entry' )
  -- Update the time of entry
  local t_entry_prev = t_entry -- When entry was previously called
  t_entry = Body.get_time()
  t_update = t_entry
  t_debug=t_entry
  t_last=t_entry
  t_command=t_entry

  Body.set_wheel_torque_enable(3) --velocity mode
  poseLast=wcm.get_robot_pose()
  rossub.init('motioncontrol')
  sub_idx_cmdvel=rossub.subscribeTwist('/cmd_vel')
  hcm.set_base_teleop_t(0)
  hcm.set_base_velocity({0,0,0})
end


function move_base_webots(t,dt)
  --vx = 2*pi*r * rpm/60s
  --rpm = vx/2/pi/r * 60
  local t_last=hcm.get_base_teleop_t()
  if(t-t_last<1.0) then
    cmd_vel=hcm.get_base_velocity()
    local wheel_r = Config.wheels.r
    local wheel_wid = Config.wheels.wid
    local rps_limit = Config.wheels.rps_limit
    local fwd_component = vector.new({1,1,1,1})*cmd_vel[1]/wheel_r
    local side_component = vector.new({1,-1,-1,1})*cmd_vel[2] * math.sqrt(2)/wheel_r
    local rot_component = 0.5*vector.new({1,-1,1,-1})*cmd_vel[3]/wheel_r * wheel_wid
    local rps=fwd_component+side_component+rot_component

    local rps_max=math.max(
      math.max(math.abs(rps[1]),math.abs(rps[2])),
      math.max(math.abs(rps[3]),math.abs(rps[4]))
    )
    if rps_max>rps_limit then
      rps[1]=rps[1]*rps_limit/rps_max
      rps[2]=rps[2]*rps_limit/rps_max
      rps[3]=rps[3]*rps_limit/rps_max
      rps[4]=rps[4]*rps_limit/rps_max
    end
    Body.set_wheel_command_velocity(rps)
  else
    Body.set_wheel_command_velocity({0,0,0,0})
  end
end

--Set actuator commands to resting position, as gotten from joint encoders.
function state.update()
  local t = Body.get_time()
  local dt = t - t_update -- Save this at the last update time
  t_update = t
  local ret = rossub.checkTwist(sub_idx_cmdvel)
  if ret and t-t_entry>1 then
    hcm.set_base_velocity({ret[1],ret[2],ret[6]})
    hcm.set_base_teleop_t(t)
  end
  if IS_WEBOTS then move_base_webots(t,dt) end
end

function state.exit()
  print(state._NAME..' Exit' )
  Body.set_wheel_command_velocity({0,0,0,0})
end

return state
