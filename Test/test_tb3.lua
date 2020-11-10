#!/usr/bin/env luajit
ROBOT_TYPE=arg[1]
-- (c) 2014 Team THORwIn
local ok = pcall(dofile,'../fiddle.lua')
if not ok then dofile'fiddle.lua' end
local unix=require'unix'
local rospub=require'tb3_rospub'

rospub.init("controller")
local t_last_pressed=unix.time()+1.0
local seq=0

local function update(key_code)
  local t=unix.time()
	if type(key_code)~='number' or key_code==0 then return end

  if t-t_last_pressed<0.2 then return end
  t_last_pressed=t
	local key_char = string.char(key_code)
	local key_char_lower = string.lower(key_char)
  local targetvel_new=hcm.get_base_velocity()
  local targetvel=hcm.get_base_velocity()

  local cmd_vel=false
  local cmd_motor=false

  if key_char_lower==("i") then
    print("all forward")
    rospub.joint_cmd(  seq,Config.jointNames, {0,0},{3,3})
    cmd_motor=true
  elseif key_char_lower==("k") then
    print("stop")
    rospub.joint_cmd(  seq,Config.jointNames, {0,0},{0,0})
    cmd_motor=true
  elseif key_char_lower==(",") then
    print("all backward")
    rospub.joint_cmd(  seq,Config.jointNames, {0,0},{-3,-3})
    cmd_motor=true
  elseif key_char_lower==("j") then
    print("left")
    rospub.joint_cmd(  seq,Config.jointNames, {0,0},{-3,3})
    cmd_motor=true
  elseif key_char_lower==("l") then
    print("right")
    rospub.joint_cmd(  seq,Config.jointNames, {0,0},{3,-3})
    cmd_motor=true
  end
  seq=seq+1
end

if ... and type(...)=='string' and ...=="test_tb3" then --webots handling
  print("CALLED BY WEBOTS!")
  WAS_REQUIRED = true
  return {entry=nil, update=update, exit=nil}
end


local getch = require'getch'
local running = true
local key_code
while running do
  key_code = getch.nonblock()
  update(key_code)
  unix.usleep(1E6*0.02)
end
