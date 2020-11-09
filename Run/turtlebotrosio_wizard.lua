#!/usr/bin/env luajit
local pwd = os.getenv'PWD'
dofile'./fiddle.lua'

local si = require'simple_ipc'
local ffi=require'ffi'
local unix=require'unix'
local sr = require'serialization'
local rossub=require'rossub'
local rospub = require 'tb3_rospub'
rospub.init('turtlebot_rospub')
rossub.init('turtlebot_rossub')

local sub_idx_odom=rossub.subscribeOdometry('/odom')


local t_entry=unix.time()
local t_last_debug=unix.time()
local t_next_debug=unix.time()+0.1
local debug_interval=5.0
local seq=1

local odom_count=0

running=true

while running do
	local t=unix.time()

	local ret = rossub.checkOdometry(sub_idx_odom)
	if ret then
		-- print("Odom: ",ret[1],ret[2],ret[3]/DEG_TO_RAD)
		odom_count=odom_count+1
		rospub.tf({ret[1], ret[2],0},{0,0,ret[3]}, "odom","base_footprint")
	end

	local cmd_vel=mcm.get_walk_vel()
	rospub.baseteleop(cmd_vel[1],cmd_vel[2],cmd_vel[3])


	local posetf=rossub.checkTF(



	t=unix.time()
	if t>t_next_debug then
		local t_elapsed=t-t_last_debug
		print(string.format("Turtlebot rosIO | odom %.1f hz",
			odom_count/t_elapsed
		))
		odom_count=0
		t_next_debug=t+debug_interval
		t_last_debug=t
	end
	unix.usleep(1E6*0.01)
end
