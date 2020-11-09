#!/usr/bin/env luajit
local pwd = os.getenv'PWD'
local ok = pcall(dofile,'../fiddle.lua')
if not ok then ok=pcall(dofile,'./fiddle.lua') end

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
local depth_ch = si.new_subscriber("depth")
local lidar_ch = si.new_subscriber("lidar")
local pose_ch = si.new_subscriber("pose")
local jointstate_ch = si.new_subscriber("jointstate")
local poller

local lidar_count,rgb_count,pose_count,depth_count,jointstate_count=0,0,0,0,0
local t_entry=unix.time()
local t_last_debug=unix.time()
local t_next_debug=unix.time()+0.1
local debug_interval=5.0
local seq=1


local function cb_lidar(skt)
	local idx = poller.lut[skt]
	local datastr = unpack(skt:recv_all())
	local n=#datastr/ffi.sizeof("float")
  rospub.webotslaserscancrop(seq,-math.pi, math.pi, n,datastr,"base_scan",0)--crop rays from left and right
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

local function cb_depth(skt)
  local idx = poller.lut[skt]
	local datastr = unpack(skt:recv_all())
	local buf_ffi= ffi.new("uint8_t[?]",640000)
  ffi.copy(buf_ffi,datastr,#datastr)
  local whfov_ffi=ffi.new("float[3]")
  ffi.copy(whfov_ffi,datastr,3*ffi.sizeof("float"))
  local w,h,fov = whfov_ffi[0],whfov_ffi[1],whfov_ffi[2]
	local fl_sz=ffi.sizeof("float")
  rospub.depthimage(seq,w,h,ffi.string(buf_ffi+3*ffi.sizeof("float"),w*h*fl_sz))
	rospub.camerainfo(seq,w,h,fov)
	depth_count=depth_count+1
	seq=seq+1
end

local function cb_pose(skt)
  local idx = poller.lut[skt]
	local datastr = unpack(skt:recv_all())
  local pose_ffi=ffi.new("float[3]")
	ffi.copy(pose_ffi,datastr,ffi.sizeof("float")*3)
	rospub.tf({pose_ffi[0], pose_ffi[1],0},{0,0,pose_ffi[2]}, "map","base_footprint")
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


rgb_ch.callback = cb_rgb
lidar_ch.callback = cb_lidar
pose_ch.callback = cb_pose
jointstate_ch.callback = cb_jointstate
depth_ch.callback=cb_depth

poller = si.wait_on_channels({rgb_ch,lidar_ch,pose_ch,jointstate_ch,depth_ch})

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

	local a1,a2,a3,a4, grip=rossub.checkJointTrajectory(sub_idx_joint)
	if a1 and t-t_entry>1 then
		print("Arm Command!")
		hcm.set_base_armtarget({a1,a2,a3,a4})
		hcm.set_base_grippertarget(grip)
	end

	t=unix.time()
	if t>t_next_debug then
		local t_elapsed=t-t_last_debug
		print(string.format("Rospub| RGB %.1f hz Depth: %.1f hz Lidar %.1f hz Pose %.1f hz Joint %.1f hz",
			rgb_count/t_elapsed,depth_count/t_elapsed,
			lidar_count/t_elapsed,pose_count/t_elapsed,jointstate_count/t_elapsed
		))
		depth_count,lidar_count,rgb_count,pose_count,jointstate_count=0,0,0,0,0
		t_next_debug=t+debug_interval
		t_last_debug=t
	end
end
