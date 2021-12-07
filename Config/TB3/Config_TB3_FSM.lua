assert(Config, 'Need a pre-existing Config table!')
local vector = require'vector'
local fsm = {}
fsm.update_rate = 100-- Update rate in Hz

fsm.enabled = {}
fsm.select = {}
fsm.Motion = {}


-- Which FSMs should be enabled?

if Config.send_motion_cmd then
  if ROBOT_TYPE=="1" then --Turtlebot with mecanum wheel
    fsm.enabled = {Motion = true,}
    fsm.select = {Motion = 'TB3',}
    fsm.Motion = {{'motionIdle', 'init', 'motionWebotsMecanum'},}
  elseif ROBOT_TYPE=="2" then --Turtlebot with mecanum wheel and arm
    fsm.enabled = {Motion = true,}
    fsm.select = {Motion = 'TB3'}
    fsm.Motion = {{'motionIdle', 'init', 'motionWebotsMecanumArm'},}
  else --Base Turtlebot
    fsm.enabled = {Motion = true,}
    fsm.select = {Motion = 'TB3',}
    fsm.Motion = {{'motionIdle', 'init', 'motionWebots'},}
  end
end

Config.fsm = fsm
-- Add all FSM directories that are in Player
for _,sm in ipairs(fsm.enabled) do
  local pname = {HOME, '/Player/', sm, 'FSM', '/?.lua;', package.path}
  package.path = table.concat(pname)
end

return Config
