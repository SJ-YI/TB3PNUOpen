#!/usr/bin/env luajit
if ... and type(...)=='string' and ...=="test_tb3" then --webots handling
  print("test_tb3:Called by webots")
else
  print("test_tb3:Separately executed")
  ROBOT_TYPE=arg[1]
end

-- (c) 2014 Team THORwIn
local ok = pcall(dofile,'../fiddle.lua')
if not ok then dofile'fiddle.lua' end
local unix=require'unix'
local rospub=require'tb3_rospub'
print("Robot type:",ROBOT_TYPE)
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
  if Config.send_motion_cmd then

    if key_char_lower==("i") then
      print("forward")
      rospub.cmdvel(0.1,0,0)
    elseif key_char_lower==("k") then
      print("stop")
      rospub.cmdvel(0,0,0)
    elseif key_char_lower==(",") then
      print("backward")
      rospub.cmdvel(-0.1,0,0)
    elseif key_char_lower==("j") then
      print("turn left")
      rospub.cmdvel(0,0,0.3)
    elseif key_char_lower==("l") then
      print("turn right")
      rospub.cmdvel(0,0,-0.3)
    elseif key_char_lower==("h") then
      print("slide left")
      rospub.cmdvel(0,0.1,0)
    elseif key_char_lower==(";") then
      print("slide right")
      rospub.cmdvel(0,-0.1,0)
    elseif key_char_lower==("1") then
      print("arm zero position")
      rospub.joint_cmd(  seq,{"Arm1","Arm2","Arm3","Arm4"}, {0,0,0,0},{0,0,0,0})
    elseif key_char_lower==("2") then
      print("arm low position")
      rospub.joint_cmd(  seq,{"Arm1","Arm2","Arm3","Arm4"}, {0,-45*DEG_TO_RAD,45*DEG_TO_RAD,0*DEG_TO_RAD},{0,0,0,0})
    elseif key_char_lower==("[") then
      print("grip open")
      rospub.joint_cmd(  seq,{"GripperL","GripperR"}, {1,1},{0,0})
    elseif key_char_lower==("]") then
      print("grip close")
      rospub.joint_cmd(  seq,{"GripperL","GripperR"}, {-1,-1},{0,0})
    end
    seq=seq+1
    return
  end



  if ROBOT_TYPE=="0" then
    if key_char_lower==("i") then
      print("forward")
      rospub.joint_cmd(  seq,Config.jointNames, {0,0},{3,3})
    elseif key_char_lower==("k") then
      print("stop")
      rospub.joint_cmd(  seq,Config.jointNames, {0,0},{0,0})
    elseif key_char_lower==(",") then
      print("backward")
      rospub.joint_cmd(  seq,Config.jointNames, {0,0},{-3,-3})
    elseif key_char_lower==("j") then
      print("turn left")
      rospub.joint_cmd(  seq,Config.jointNames, {0,0},{-3,3})
    elseif key_char_lower==("l") then
      print("turn right")
      rospub.joint_cmd(  seq,Config.jointNames, {0,0},{3,-3})
    end
  else
    if key_char_lower==("i") then
      print("forward")
      rospub.joint_cmd(  seq,{"wheel1","wheel2","wheel3","wheel4"}, {0,0,0,0},{-3,3,-3,3})
    elseif key_char_lower==("k") then
      print("stop")
      rospub.joint_cmd(  seq,{"wheel1","wheel2","wheel3","wheel4"}, {0,0,0,0},{0,0,0,0})
    elseif key_char_lower==(",") then
      print("backward")
      rospub.joint_cmd(  seq,{"wheel1","wheel2","wheel3","wheel4"}, {0,0,0,0},{3,-3,3,-3})
    elseif key_char_lower==("j") then
     print("turn left")
     rospub.joint_cmd(  seq,{"wheel1","wheel2","wheel3","wheel4"}, {0,0,0,0},{-3,-3,-3,-3})
    elseif key_char_lower==("l") then
      print("turn right")
      rospub.joint_cmd(  seq,{"wheel1","wheel2","wheel3","wheel4"}, {0,0,0,0},{3,3,3,3})
    elseif key_char_lower==("h") then
      print("slide left")
      rospub.joint_cmd(  seq,{"wheel1","wheel2","wheel3","wheel4"}, {0,0,0,0},{-3,-3,3,3})
    elseif key_char_lower==(";") then
      print("slide right")
      rospub.joint_cmd(  seq,{"wheel1","wheel2","wheel3","wheel4"}, {0,0,0,0},{3,3,-3,-3})
    elseif key_char_lower==("1") then
      print("arm zero position")
      rospub.joint_cmd(  seq,{"Arm1","Arm2","Arm3","Arm4"}, {0,0,0,0},{0,0,0,0})
    elseif key_char_lower==("2") then
      print("arm low position")
      rospub.joint_cmd(  seq,{"Arm1","Arm2","Arm3","Arm4"}, {0,-45*DEG_TO_RAD,45*DEG_TO_RAD,0*DEG_TO_RAD},{0,0,0,0})
    elseif key_char_lower==("[") then
      print("grip open")
      rospub.joint_cmd(  seq,{"GripperL","GripperR"}, {1,1},{0,0})
    elseif key_char_lower==("]") then
      print("grip close")
      rospub.joint_cmd(  seq,{"GripperL","GripperR"}, {-1,-1},{0,0})
    end
  end
  seq=seq+1
end

if ... and type(...)=='string' and ...=="test_tb3" then --webots handling
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
