local state = {}
state._NAME = ...
require'mcm'
-- IDLE IS A RELAX STATE
-- NOTHING SHOULD BE TORQUED ON HERE!
local Body = require'Body'
local t_entry, t_update, t_debug,t_command
local cmd_vel={0,0,0}


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
  hcm.set_base_teleop_t(0)
  hcm.set_base_velocity({0,0,0})
end

local function get_motor_velocity()
  --vx = 2*pi*r * rpm/60s
  --rpm = vx/2/pi/r * 60
  cmd_vel=hcm.get_base_velocity()
  local wheel_r = Config.wheels.r
  local wheel_wid = Config.wheels.wid
  local rps_limit = Config.wheels.rps_limit
  local fwd_component = cmd_vel[1]/wheel_r
  local rot_component = cmd_vel[3]/wheel_r * wheel_wid
  local rpm_l = fwd_component - 0.5*rot_component
  local rpm_r = fwd_component + 0.5*rot_component
  local rpm_max=math.max(math.abs(rpm_l),math.abs(rpm_r))
  if rpm_max>rps_limit then
    rpm_l = rpm_l*rps_limit/rpm_max
    rpm_r = rpm_r*rps_limit/rpm_max
  end
  return {rpm_l,rpm_r}
end

function move_base_webots(t,dt)
  local t_last=hcm.get_base_teleop_t()
  if(t-t_last<1.0) then
    local motor_rpm=get_motor_velocity()
    Body.set_wheel_command_velocity(motor_rpm) --in rpm
  else
    Body.set_wheel_command_velocity({0,0}) --in rpm
  end
end


--Set actuator commands to resting position, as gotten from joint encoders.
function state.update()
  local t = Body.get_time()
  local dt = t - t_update -- Save this at the last update time
  t_update = t
  if IS_WEBOTS then move_base_webots(t,dt) end
end

function state.exit()
  print(state._NAME..' Exit' )
  Body.set_wheel_command_velocity({0,0})
end

return state
