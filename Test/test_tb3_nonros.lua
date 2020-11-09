#!/usr/bin/env luajit
-- (c) 2014 Team THORwIn
local ok = pcall(dofile,'../fiddle.lua')
if not ok then dofile'fiddle.lua' end
local WAS_REQUIRED


local unix=require'unix'
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
	if key_char_lower==("i") then
    targetvel_new[1]=targetvel_new[1]+0.1
  elseif key_char_lower==(",") then
    targetvel_new[1]=targetvel_new[1]-0.1
  elseif key_char_lower==("j") then
    targetvel_new[3]=targetvel_new[3]+0.4
  elseif key_char_lower==("l") then
    targetvel_new[3]=targetvel_new[3]-0.4
  elseif key_char_lower==("k") then
    targetvel_new={0,0,0}
  elseif key_char_lower==("h") then
    targetvel_new[2]=targetvel_new[2]+0.05
  elseif key_char_lower==(";") then
    targetvel_new[2]=targetvel_new[2]-0.05
  end


  if key_char_lower==("1") then
    arm_ch:send'pickup'
    -- print("Arm 1")
    -- armangle={0,45*DEG_TO_RAD,  -20*DEG_TO_RAD,-25*DEG_TO_RAD}
    -- hcm.set_base_armtarget(armangle)
  elseif key_char_lower==("2") then
    print("Arm 2")
    armangle={0,0,0,0}
    hcm.set_base_armtarget(armangle)
  elseif key_char_lower==("3") then
    arm_ch:send'pickup'

  elseif key_char_lower==("]") then
    grip=2
  elseif key_char_lower==("[") then
    print("Open!")
    grip=-1
  elseif key_char_lower==("g") then
    body_ch:send'start'
    t=t-10 --hack to start movement
  end


  hcm.set_base_grippertarget(grip)

  print("Target vel:",unpack(targetvel_new))
  hcm.set_base_velocity({targetvel_new[1],targetvel_new[2],targetvel_new[3]})
  hcm.set_base_teleop_t(t)
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
