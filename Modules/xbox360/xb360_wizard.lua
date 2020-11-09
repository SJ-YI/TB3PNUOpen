#!/usr/bin/env luajit
-- (c) 2014 Team THORwIn
local ok = pcall(dofile,'../fiddle.lua')
if not ok then ok=pcall(dofile,'./fiddle.lua') end
if not ok then ok=dofile'../../fiddle.lua' end

local use_ros,rospub=false,nil
local is_granny=false
local cmd_type=0


local util = require'util'
local xbox360 = require 'xbox360'
local signal = require'signal'.signal
local gettime = require'unix'.time


print("XB360!!!!")

if #arg>0 then
	if arg[1]=="tb3" then
		print("Turtlebot 3 xbox 360 ros sender!!!")
		use_ros=true
		rospub=require'tb3_rospub'
		rospub.init('xb360_pub')
	elseif arg[1]=="granny" then
		print("Granny xbox 360 ros sender!!!")
		use_ros=true
		is_granny=true
		rospub=require'tb3_rospub'
		rospub.init('xb360_pub')
	else
		print("UNKNOWN XB360 ROS SENDER!!")
	end
else
	print("NO ARG FOR XB360 SENDER!")
end
require'gcm'
require'hcm'

gcm.set_processes_xb360({1,0,0})
local si = require'simple_ipc'

local tDelay = 0.005*1E6
local running = true

-- Cleanly exit on Ctrl-C
local function shutdown()
	io.write('\n Soft shutdown!\n')
	running=false
  gcm.set_processes_xb360({0,0,0})
end
signal("SIGINT", shutdown)
signal("SIGTERM", shutdown)


--local product_id = 0x0291
--local product_id = 0x028e
local product_id1 = 0x0719 --standard black receiver
--local product_id = 0x02a9
local product_id2 = 0x0291 --white receiver
local product_id3 = 0x028e --short white receiver
local dongle_not_found=true
gcm.set_processes_xb360({1,0,0})

while dongle_not_found and running do
	ret=xbox360.check({product_id1,product_id2,product_id3})
	if ret then dongle_not_found=false;
	else
		print("XB360: Dongle not found, waiting...")
		unix.usleep(1e6*1) --20fps
	end
end


local seq=0
local head_pitch=0
local t_last_head_toggle=0
local t_last_sent=Body.get_time()
local t_last_update=Body.get_time()
local t_last = gettime()
local t_last_debug = gettime()
local t_debug_interval = 1
local t_last_button= gettime()
local slam_started=false
local slam_ended=false
local targetvel={0,0,0}
local last_control_t = gettime()

local gtarget=0


local armtarget={0,0,0,0}
local griptarget=0

local function update(ret)
  local t = gettime()
  local dt = t-t_last
  t_last=t

--BACK START LB RB XBOX X Y A B
  local x_db,x_max = 10,255
  local y_db,y_max = 8000,32768
	local y_db_rot = 14000

  --Left/right trigger: forward and backward
  --Left stick L/R: rotate
  --Left stick U/D: look up/down
  --Right stick L/R: strafe

	local lt =( util.procFunc(ret.trigger[1],x_db,x_max )/ (x_max-x_db))
	local rt =( util.procFunc(ret.trigger[2],x_db,x_max )/ (x_max-x_db))
	local lax =util.procFunc(ret.lstick[1],y_db,y_max )/(y_max-y_db)
	local lay =util.procFunc(ret.lstick[2],y_db_rot,y_max )/(y_max-y_db)
	local rax =util.procFunc(ret.rstick[1],y_db,y_max )/(y_max-y_db)
	local ray =util.procFunc(ret.rstick[2],y_db,y_max )/(y_max-y_db)

	local maxvel=Config.max_vel or {0.50,0.50,1.0}
	targetvel={(rt-lt) * maxvel[1],ray*maxvel[2],lay*maxvel[3]}





	if use_ros then
		if t-t_last_button>0.5 then
			t_last_button= gettime()
			if ret.buttons[1]==1 then --START and STOP MAPPING
				print("MAPPING START!!!!!!!!!")
				os.execute("espeak 'mapping'")
				rospub.mapcmd(1)
			end
			if ret.buttons[2]==1 then --START and STOP MAPPING
				print("GAME START!!!!!!!!!")
				os.execute("espeak 'start'")
				rospub.mapcmd(9)
			end
			if ret.buttons[4]==1 then --ADD MARKER
				os.execute("espeak 'added'")
				rospub.mapcmd(3)
			end
			if ret.buttons[3]==1 then --REMOVE MARKER
				os.execute("espeak 'removed'")
				rospub.mapcmd(4)
			end
		end


		if ret.buttons[7]==1 then
			rospub.motorpower(1)
			armtarget={0,0,85*DEG_TO_RAD,-90*DEG_TO_RAD}
			rospub.joint(armtarget,griptarget)
		elseif ret.buttons[8]==1 then
			armtarget={0,0*DEG_TO_RAD,45*DEG_TO_RAD,-45*DEG_TO_RAD}
			rospub.joint(armtarget,griptarget)

		elseif ret.dpad[1]~=0 then
			griptarget=0
			rospub.joint(armtarget,griptarget)
		elseif ret.dpad[2]==1 then
			griptarget=-200
			rospub.joint(armtarget,griptarget)
		elseif ret.dpad[2]==-1 then
			griptarget=200
			rospub.joint(armtarget,griptarget)
		end
	end

  if ret.buttons[1]==1 and ret.buttons[2]==1 then
    -- gcm.set_game_selfdestruct(1)
    -- running=false
  end

  if t-t_last_debug>t_debug_interval then
    print(
      string.format(
      "Dpad:%d %d LStick:%d %d RStick:%d %d LT%d RT%d",
      ret.dpad[1],ret.dpad[2],
      ret.lstick[1],ret.lstick[2],
      ret.rstick[1],ret.rstick[2],
      ret.trigger[1],ret.trigger[2])
      ..
      string.format("Buttons:%d%d%d%d%d%d%d%d%d",
        unpack(ret.buttons))
    )
    t_last_debug=t
  end


	hcm.set_xb360_dpad({ret.dpad[1],ret.dpad[2]})
	hcm.set_xb360_buttons(ret.buttons)
	hcm.set_xb360_lstick(ret.lstick)
	hcm.set_xb360_rstick(ret.rstick)
	hcm.set_xb360_trigger(ret.trigger)


end


local function send_motor_cmd(cmd_vel)
	Config.wheels={
		r=0.05,
		wid=0.33,
		rps_limit = 8.06318 --77RPM for XM430-210-R
	}

	local wheel_r = Config.wheels.r
  local wheel_wid = Config.wheels.wid
  local rps_limit = Config.wheels.rps_limit
  mcm.set_walk_vel(cmd_vel)
  local fwd_component = vector.new({-1,1,-1,1})*cmd_vel[1]/wheel_r
  local side_component = vector.new({-1,-1,1,1})*cmd_vel[2] * math.sqrt(2)/wheel_r
  local rot_component = 0.5*vector.new({-1,-1,-1,-1})*cmd_vel[3]/wheel_r * wheel_wid
  local rps=fwd_component+side_component+rot_component
  local rps_max=math.max(math.max(math.abs(rps[1]),math.abs(rps[2])),
    						math.max(math.abs(rps[3]),math.abs(rps[4])))
  if rps_max>rps_limit then
    rps[1]=rps[1]*rps_limit/rps_max
    rps[2]=rps[2]*rps_limit/rps_max
    rps[3]=rps[3]*rps_limit/rps_max
    rps[4]=rps[4]*rps_limit/rps_max
  end

	--HACK
	rps[1]=-rps[1]/DEG_TO_RAD
	rps[2]=rps[2]/DEG_TO_RAD
	rps[3]=-rps[3]/DEG_TO_RAD
	rps[4]=rps[4]/DEG_TO_RAD

	print(string.format("%.3f %.3f %.3f %.3f",unpack(rps)))
  rospub.motorvel(rps)
end





local function sendcmd()
  local t=gettime()
  local dt=t-t_last_sent
  local vel=hcm.get_base_velocity()

  local acc=Config.max_acc or {0.80,0.80,2.00}
	local maxvel=Config.max_vel or {0.50,0.50,1.0}
  vel[1]=util.procFunc(targetvel[1]-vel[1],0,dt*acc[1])+vel[1]
  vel[2]=util.procFunc(targetvel[2]-vel[2],0,dt*acc[2])+vel[2]
  vel[3]=util.procFunc(targetvel[3]-vel[3],0,dt*acc[3])+vel[3]
  vel[1]=util.procFunc(vel[1],0,maxvel[1])
  vel[2]=util.procFunc(vel[2],0,maxvel[2])
  vel[3]=util.procFunc(vel[3],0,maxvel[3])
  local d1=math.sqrt(vel[1]*vel[1]+vel[2]*vel[2])
  local d2=math.sqrt(targetvel[1]*targetvel[1]+targetvel[2]*targetvel[2])

  if not (targetvel[1]==0 and targetvel[2]==0 and targetvel[3]==0) then
    last_control_t = t
    -- print"UPD"
  end
  if t-last_control_t<1.5 then
    hcm.set_base_teleop_t(t)
    hcm.set_base_velocity({vel[1],vel[2],vel[3]})

		if use_ros then			
			rospub.baseteleop(vel[1],vel[2],vel[3])
			--send_motor_cmd({vel[1],vel[2],vel[3]})
		end
  end
  t_last_sent=t
end


while running do
  local ret = xbox360.read()
  update(ret)
  sendcmd()
  unix.usleep(1e6*0.05) --20fps
  local gccount = gcm.get_processes_xb360()
  gcm.set_processes_xb360({2,gccount[2]+1,gccount[3]})
  if gcm.get_game_selfdestruct()==1 then
  	os.execute("mpg321 ~/Desktop/ARAICodes/Media/selfdestruct.mp3")
  	os.execute('sync')
  	os.execute('systemctl poweroff -i')
  end
end
