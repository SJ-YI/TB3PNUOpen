#!/usr/bin/env luajit
-- (c) 2014 Team THORwIn
local ok = pcall(dofile,'../fiddle.lua')
if not ok then dofile'fiddle.lua' end
local WAS_REQUIRED


local unix=require'unix'
local rospub=require'tb3_rospub'
rospub.init("controller")
local t_last_pressed=unix.time()+1.0

local grip=0
local armangle={0,0,0,0}

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
    targetvel_new[1]=targetvel_new[1]+0.1
    cmd_vel=true
  elseif key_char_lower==(",") then
    targetvel_new[1]=targetvel_new[1]-0.1
    cmd_vel=true
  elseif key_char_lower==("j") then
    targetvel_new[3]=targetvel_new[3]+0.4
    cmd_vel=true
  elseif key_char_lower==("l") then
    targetvel_new[3]=targetvel_new[3]-0.4
    cmd_vel=true
  elseif key_char_lower==("k") then
    targetvel_new={0,0,0}
    cmd_vel=true
  elseif key_char_lower==("h") then
    targetvel_new[2]=targetvel_new[2]+0.05
    cmd_vel=true
  elseif key_char_lower==(";") then
    targetvel_new[2]=targetvel_new[2]-0.05
    cmd_vel=true
  end


  if key_char_lower==("w") then
    rospub.motorvel({1,1,1,1})
    cmd_motor=true
  elseif key_char_lower==("s") then
    rospub.motorvel({0,0,0,0})
    cmd_motor=true
  end
  


  if key_char_lower==("1") then
    armangle={0,0,0,0}
    rospub.joint(armangle,grip)
  elseif key_char_lower==("2") then
    armangle={0,0,90*DEG_TO_RAD,-90*DEG_TO_RAD}
    rospub.joint(armangle,grip)
  elseif key_char_lower==("[") then
    grip=1
    rospub.joint(armangle,grip)
  elseif key_char_lower==("]") then
    grip=-1
    rospub.joint(armangle,grip)
  end

  if cmd_vel then
    print("Target vel:",unpack(targetvel_new))
    rospub.baseteleop(targetvel_new[1],targetvel_new[2],targetvel_new[3])
  end

end

if ... and type(...)=='string' then --webots handling
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
