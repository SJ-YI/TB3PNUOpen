#!/usr/bin/env luajit
local pwd = os.getenv'PWD'
if string.find(pwd,"Run") then	dofile('../include.lua')
else	dofile('../../include.lua') end
local si = require'simple_ipc'
local ffi=require'ffi'
local unix=require'unix'


local rospub = require 'tb3_rospub'
rospub.init('test')
local t_last_debug=unix.time()
local debug_interval=5.0
local seq=1

while true do
  t=unix.time()
  local w,h=320,240
  local fov=1.1
  local buf_rgb=ffi.new("uint8_t[?]",w*h*3)
  local hh=seq%h
  for i=1,w do
    buf_rgb[(i-1 +(w*hh))*3]=255
  end
  rospub.rgbimage(seq,w,h,ffi.string(buf_rgb,w*h*3))
  rospub.camerainfo(seq,w,h,fov)
  local n=360
  local ranges=ffi.new("float[?]",n)
  local fl_sz = ffi.sizeof('float')
  local aa=seq%n
  for i=1,n do ranges[i-1]=0.5 end
  for i=1,10 do ranges[(aa+i)%n]=1.0 end
  rospub.laserscan(seq,0, 6.26573181152,n,ffi.string(ranges,n*fl_sz),"base_scan")
  rospub.tf({1.0*math.cos(seq*DEG_TO_RAD),1.0*math.sin(seq*DEG_TO_RAD),0},{0,0,0}, "map","base_link")



  rospub.baseteleop(1,0,0)

  seq=seq+1
  if t-t_last_debug>debug_interval then

    t_last_debug=t
    collectgarbage()
  end
  unix.usleep(1E6*0.1)
end
