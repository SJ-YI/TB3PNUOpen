#!/usr/bin/env luajit
local pwd = os.getenv'PWD'
dofile'./fiddle.lua'

local si = require'simple_ipc'
local ffi=require'ffi'
local unix=require'unix'
local sr = require'serialization'
local rossub=require'rossub'
local rospub = require 'tb3_rospub'
rospub.init('webots_rospub')
rossub.init('webots_rossub')

local sub_idx_cmdvel,sub_idx_joint,sub_idx_motorcmd
sub_idx_cmdvel=rossub.subscribeTwist('/cmd_vel')
sub_idx_joint=rossub.subscribeJointTrajectory('/arm_pos')

local rgb_ch = si.new_subscriber("rgb")
local lidar_ch = si.new_subscriber("lidar")
local pose_ch = si.new_subscriber("pose")
local jointstate_ch = si.new_subscriber("jointstate")
local poller

local lidar_count,rgb_count,pose_count,jointstate_count=0,0,0,0
local t_entry=unix.time()
local t_last_debug=unix.time()
local t_next_debug=unix.time()+0.1
local debug_interval=5.0
local seq=1


local function cb_lidar(skt)
	local idx = poller.lut[skt]
	local datastr = unpack(skt:recv_all())
	local n=#datastr/ffi.sizeof("float")
  rospub.webotslaserscancrop(seq,-math.pi, math.pi, n,datastr,"base_scan",Config.lidar_crop or 0)--crop rays from left and right
	lidar_count=lidar_count+1
	seq=seq+1
end

local function cb_rgb(skt)
  local idx = poller.lut[skt]
	local datastr = unpack(skt:recv_all())
	local buf_ffi= ffi.new("uint8_t[?]",370000)
  ffi.copy(buf_ffi,datastr,#datastr)
  local whfov_ffi=ffi.new("float[3]")
  ffi.copy(whfov_ffi,datastr,3*ffi.sizeof("float"))
  local w,h,fov = whfov_ffi[0],whfov_ffi[1],whfov_ffi[2]
  rospub.rgbimage(seq,w,h,ffi.string(buf_ffi+3*ffi.sizeof("float"),w*h*3))
  rospub.camerainfo(seq,w,h,fov)
	rgb_count=rgb_count+1
	seq=seq+1
end

local function cb_pose(skt)
  local idx = poller.lut[skt]
	local datastr = unpack(skt:recv_all())
  local pose_ffi=ffi.new("float[3]")
	ffi.copy(pose_ffi,datastr,ffi.sizeof("float")*3)
	rospub.tf({pose_ffi[0], pose_ffi[1],0},{0,0,pose_ffi[2]}, "odom","base_footprint")
	rospub.tf({pose_ffi[0], pose_ffi[1],0},{0,0,pose_ffi[2]}, "map","base_footprint_ground_truth")
  rospub.odom({pose_ffi[0],pose_ffi[1],pose_ffi[2]})
	pose_count=pose_count+1
	seq=seq+1
end

local function cb_jointstate(skt)
	local idx = poller.lut[skt]
	local datastr = unpack(skt:recv_all())
	local data_ffi=ffi.new("char[?]",#datastr)
	ffi.copy(data_ffi,datastr,#datastr)
	local datasizes_ffi=ffi.new("int[2]")
	ffi.copy(datasizes_ffi,data_ffi,2*ffi.sizeof("int"))
	local jointnames_size, jointangles_size=datasizes_ffi[0],datasizes_ffi[1]
	jointnames=sr.deserialize(ffi.string(data_ffi+2*ffi.sizeof("int"),jointnames_size))
	jointangles=sr.deserialize(ffi.string(data_ffi+2*ffi.sizeof("int")+jointnames_size,jointangles_size))

  rospub.jointstate(seq,jointnames, jointangles)
	jointstate_count=jointstate_count+1
	seq=seq+1
end

local function update_markers()
	if not Config.pose_targets then
		print("NO POSE")
	return end
	local types,posx,posy,posz,yaw,names,scales,colors={},{},{},{},{},{},{},{}
	local scale, color1, color2, arrowlen = 1,2,4,0.20
	local mc=0

	for i=1,#Config.pose_targets do
	  mc=mc+1        --LOCATION NAMES (string)
	  types[mc],posx[mc],posy[mc],posz[mc],yaw[mc],names[mc],scales[mc],colors[mc]=
	    2,     Config.pose_targets[i][2][1]-0.1,Config.pose_targets[i][2][2],0,
			0, Config.pose_targets[i][1],1, 2

	  mc=mc+1  --arrow
	  types[mc],posx[mc],posy[mc],posz[mc],yaw[mc],names[mc],scales[mc],colors[mc]=
	    5, 	Config.pose_targets[i][2][1],Config.pose_targets[i][2][2],0.01,
	    Config.pose_targets[i][2][3],"x", arrowlen, color1

	  mc=mc+1 --flat cylinder
	  types[mc],posx[mc],posy[mc],posz[mc],yaw[mc],names[mc],scales[mc],colors[mc]=
	    7,   Config.pose_targets[i][2][1],Config.pose_targets[i][2][2],0,
	    Config.pose_targets[i][2][3],"x", 1, color2
	end
  rospub.marker(mc,types,posx,posy,posz,yaw,names,scales,colors)
end


rgb_ch.callback = cb_rgb
lidar_ch.callback = cb_lidar
pose_ch.callback = cb_pose
jointstate_ch.callback = cb_jointstate
poller = si.wait_on_channels({rgb_ch,lidar_ch,pose_ch,jointstate_ch})


running=true
-- Timeout in milliseconds (100 Hz)
local TIMEOUT = 1e3 / 500
while running do
	local t=unix.time()
	npoll = poller:poll(TIMEOUT)

	-- local ret = rossub.checkTwist(sub_idx_cmdvel)
	-- if ret and t-t_entry>1 then
	-- 	print("Velocity Command!")
	-- 	hcm.set_base_velocity({ret[1],ret[2],ret[6]})
	-- 	hcm.set_base_teleop_t(t)
	-- end
	-- local a1,a2,a3,a4, grip=rossub.checkJointTrajectory(sub_idx_joint)
	-- if a1 and t-t_entry>1 then
	-- 	print("Arm Command!")
	-- 	hcm.set_base_armtarget({a1,a2,a3,a4})
	-- 	hcm.set_base_grippertarget(grip)
	-- end

	local cmd_vel=mcm.get_walk_vel()
	rospub.baseteleop(cmd_vel[1],cmd_vel[2],cmd_vel[3])

	local pathplan=hcm.get_path_execute()
	rospub.job(pathplan)

  local robot_pose=rossub.checkTF("map","base_footprint")
	if robot_pose then
		local pose={robot_pose[1],robot_pose[2],robot_pose[6]}
		-- print(string.format("Pose: %.2f %.2f %.1f",pose[1],pose[2],pose[3]/DEG_TO_RAD))
		wcm.set_robot_pose(pose)
	end

	local arposex=wcm.get_landmark_posx()
	local arposey=wcm.get_landmark_posy()
	local arposea=wcm.get_landmark_posa()
	local arposet=wcm.get_landmark_t()
	for i=1,8 do
		local arpose=rossub.checkTF("base_link","/ar_marker_"..(i-1))
		if arpose then
			arposex[i],arposey[i],arposea[i],arposet[i]=arpose[1],arpose[2],arpose[6]+math.pi/2,t
		end
	end
	wcm.set_landmark_posx(arposex)
	wcm.set_landmark_posy(arposey)
	wcm.set_landmark_posa(arposea)
	wcm.set_landmark_t(arposet)


	t=unix.time()
	if t>t_next_debug then
		update_markers()
		local t_elapsed=t-t_last_debug
		print(string.format("Rospub| Image %.1f hz Lidar %.1f hz Pose %.1f hz Joint %.1f hz",
			rgb_count/t_elapsed,lidar_count/t_elapsed,pose_count/t_elapsed,jointstate_count/t_elapsed
		))
		lidar_count,rgb_count,pose_count,jointstate_count=0,0,0,0
		t_next_debug=t+debug_interval
		t_last_debug=t
	end
end
