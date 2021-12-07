------------------------------
--ROBOT NAMES
------------------------------
IS_LOCALHOST = false

if not ROBOT_TYPE then
	print("Setting robot type")
	ROBOT_TYPE=os.getenv("ROBOT_TYPE")
	print("ROBOT TYPE:",ROBOT_TYPE)
end

if ROBOT_TYPE=="0" then --Turtlebot 3!!!
	print("TurtleBot 3 detected")
elseif ROBOT_TYPE=="1" then --Turtlebot with mecanum wheels
	print("TurtleBot 3 Mecanum detected")
elseif ROBOT_TYPE=="2" then --Turtlebot with mecanum wheels AND a manipulator
	print("Armed TurtleBot 3 Mecanum detected")
end

Config = {PLATFORM_NAME = 'TB3'}
local exo = {'FSM','Robot','Perception'}
-- Global Config

Config.testfile = 'test_tb3' --for webots
Config.send_motion_cmd = true --enable cmd_vel relay


-----------------------------------
-- Load Paths and Configurations --
-----------------------------------
-- Custom Config files
local pname = {HOME, '/Config/',Config.PLATFORM_NAME, '/?.lua;', package.path}
package.path = table.concat(pname)
for _,v in ipairs(exo) do
	--print('Loading', v)
	local fname = {'Config_', Config.PLATFORM_NAME, '_', v}
	local filename = table.concat(fname)
  assert(pcall(require, filename))
end

-- Finite state machine paths
if Config.fsm.enabled then
	for sm, en in pairs(Config.fsm.enabled) do
		if en then
			-- print(sm)
			local selected = Config.fsm.select and Config.fsm.select[sm]
			if selected then
				local pname = {HOME, '/Player/', sm, 'FSM/', selected, '/?.lua;', package.path}
				package.path = table.concat(pname)
			else --default fsm
				local pname = {HOME, '/Player/', sm, 'FSM/', '?.lua;', package.path}
				package.path = table.concat(pname)
			end
		end
	end
end



return Config
