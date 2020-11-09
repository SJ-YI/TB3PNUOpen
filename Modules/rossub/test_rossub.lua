#!/usr/bin/env luajit
local pwd = os.getenv'PWD'
if string.find(pwd,"Run") then	dofile('../include.lua')
else	dofile('../../include.lua') end
local si = require'simple_ipc'
local ffi=require'ffi'
local unix=require'unix'
require'wcm'



local rossub = require 'rossub'
rossub.init('test')
local sub_idx_FT = rossub.subscribeFT('/hsrb/wrist_wrench/compensated')
local sub_idx_Joint = rossub.subscribeJoint('/hsrb/joint_states')


local c_ft,j_ft=0,0
local t_last_debug=unix.time()
local debug_interval=1.0


while true do
  local buf
  local t = unix.time()
  -- buf=rossub.checkFT(sub_idx_FT)
  -- if buf then
  --   c_ft=c_ft+1
  --   wcm.set_robot_wristforce_t(t)
  --   wcm.set_robot_wristforce(buf)
  -- end
  buf,buf2=rossub.checkJoint(sub_idx_Joint)
  if buf then
    j_ft=j_ft+1
    wcm.set_robot_joints_t(t)
    wcm.set_robot_joints(buf)
    wcm.set_robot_jointsvel(buf2)
  end


  if t-t_last_debug>debug_interval then
    print("FT: ",c_ft/(t-t_last_debug), " hz")
    print("Joint: ",j_ft/(t-t_last_debug), " hz")

    local jbuf=wcm.get_robot_joints()
    local jbufvel=wcm.get_robot_jointsvel()
    print(string.format("Armlift: %.2f Armflex: %.2f Armroll: %.2f Wflex%.2f Wroll%.2f Hy %.2f HP %.2f",
      jbuf[1],jbuf[2],jbuf[3],jbuf[4],jbuf[5],jbuf[6]/DEG_TO_RAD,jbuf[7]/DEG_TO_RAD
    ))
    print(string.format("headvel: %.2f neckvel: %.2f",
	jbufvel[6],jbufvel[7]
    ))

    c_ft,j_ft=0,0
    t_last_debug=t
    collectgarbage()
  end
  unix.usleep(1E6*0.005)
end
