local state = {}
state._NAME = ...
require'mcm'
-- IDLE IS A RELAX STATE
-- NOTHING SHOULD BE TORQUED ON HERE!
local Body = require'Body'
local t_entry, t_update, t_debug,t_command
local cmd_vel={0,0,0}

local poseMoveStart={0,0,0}
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
  Body.set_gripper_torque_enable(2) --torque mode

  q0=Body.get_arm_position()
  Body.set_arm_command_position(q0)
  hcm.set_base_armtarget({q0[1],q0[2],q0[3],q0[4]})
  print("Q0:",unpack(q0/DEG_TO_RAD))
  -- Body.set_arm_torque_enable({1,1,1,1,1})
  poseLast=wcm.get_robot_pose()
  hcm.set_base_teleop_t(0)
  hcm.set_base_motorcmd_t(0)
  hcm.set_base_velocity({0,0,0})
  mcm.set_walk_vel({0,0,0})

  rossub.init('motioncontrol')
  sub_idx_cmdvel=rossub.subscribeTwist('/cmd_vel')
end


local function get_motor_velocity()
  local wheel_r = Config.wheels.r
  local wheel_wid = Config.wheels.wid
  local rps_limit = Config.wheels.rps_limit
  --FL FR RL RR
  local cmd_vel=hcm.get_base_velocity()

  mcm.set_walk_vel(cmd_vel)
  local fwd_component = vector.new({-1,1,-1,1})*cmd_vel[1]/wheel_r
  local side_component = vector.new({-1,-1,1,1})*cmd_vel[2]/wheel_r
  local rot_component = 0.5*vector.new({-1,-1,-1,-1})*cmd_vel[3]/wheel_r * wheel_wid
  local rps=fwd_component+side_component+rot_component
  local rps_max=math.max(
    math.max(math.abs(rps[1]),math.abs(rps[2])),
    math.max(math.abs(rps[3]),math.abs(rps[4]))
  )
  if rps_max>rps_limit then
    -- print("RPS MAX!!!")
    rps[1]=rps[1]*rps_limit/rps_max
    rps[2]=rps[2]*rps_limit/rps_max
    rps[3]=rps[3]*rps_limit/rps_max
    rps[4]=rps[4]*rps_limit/rps_max
  end
  return rps
end


function move_base_webots(t,dt)
  local t_last=hcm.get_base_teleop_t()
  if(t-t_last<1.0) then
    local motor_rpm=get_motor_velocity()
    Body.set_wheel_command_velocity(motor_rpm) --in rpm
  else
    Body.set_wheel_command_velocity({0,0,0,0}) --in rpm
  end
end


--Set actuator commands to resting position, as gotten from joint encoders.
function state.update()
  local t = Body.get_time()
  local dt = t - t_update -- Save this at the last update time
  t_update = t

  -- local grip=hcm.get_base_grippertarget()
  -- Body.set_arm_command_position(hcm.get_base_armtarget())
  -- Body.set_gripper_command_torque({-grip,-grip})

  local ret = rossub.checkTwist(sub_idx_cmdvel)
  if ret and t-t_entry>1 then
    hcm.set_base_velocity({ret[1],ret[2],ret[6]})
    hcm.set_base_teleop_t(t)
  end
  move_base_webots(t,dt)
end

function state.exit()
  print(state._NAME..' Exit' )
  Body.set_wheel_command_velocity({0,0,0,0})
end

return state
