--------------------------------
-- World Communication Module
-- (c) 2013 Stephen McGill
--------------------------------
local vector = require'vector'
local memory = require'memory'

-- shared properties
local shared = {}
local shsize = {}

shared.robot = {}
shared.robot.pose = vector.zeros(3)
shared.robot.pose0 = vector.zeros(3)
shared.robot.pose_odom = vector.zeros(3)
shared.robot.pose_gps = vector.zeros(3)
shared.robot.rostime = vector.zeros(1)
shared.robot.webots = vector.zeros(1)




shared.landmark={}
shared.landmark.posx=vector.zeros(8)
shared.landmark.posy=vector.zeros(8)
shared.landmark.posa=vector.zeros(8)
shared.landmark.t=vector.zeros(8)



shared.task={}
shared.task.index=vector.ones(1)

-- Call the initializer
memory.init_shm_segment(..., shared, shsize)
