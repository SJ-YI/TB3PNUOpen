local memory = require'memory'
local vector = require'vector'


local MAX_TRAJ= 10
local MAX_J_TRAJ = 100
--Human input memory

-- shared properties
local shared = {};
local shsize = {};

shared.xb360 = {};
shared.xb360.vel = vector.zeros(3)
shared.xb360.trigger = vector.zeros(2)
shared.xb360.lstick = vector.zeros(2)
shared.xb360.rstick = vector.zeros(2)
shared.xb360.dpad = vector.zeros(2)
shared.xb360.buttons = vector.zeros(9)
shared.xb360.seq = vector.zeros(1)
shared.xb360.t = vector.zeros(1)

shared.base={}
shared.base.teleop_t=vector.zeros(1)
shared.base.velocity=vector.zeros(3)
shared.base.target=vector.zeros(3)
shared.base.velocity_t=vector.zeros(1)

shared.base.motorcmd_t=vector.zeros(1)
shared.base.command_velocity=vector.zeros(3)

shared.base.armtarget=vector.zeros(4)
shared.base.grippertarget=vector.zeros(1)


shared.base.run=vector.zeros(1)
shared.base.restart=vector.zeros(1)
shared.base.zeropos=vector.zeros(3)
shared.base.speedfactor=vector.ones(1)

shared.arm={}
shared.arm.state=vector.zeros(1)



local MAX_PATH_NO=255
shared.path={}
shared.path.targetpose=vector.zeros(3)
shared.path.execute=vector.zeros(1)
shared.path.num=vector.zeros(1)
shared.path.index=vector.zeros(1)
shared.path.x=vector.zeros(MAX_PATH_NO)
shared.path.y=vector.zeros(MAX_PATH_NO)
shared.path.maxvel=vector.zeros(1)
shared.path.maxavel=vector.zeros(1)
shared.path.approachtype=vector.zeros(1) --0 for fine mode, 1 for quick mode


-- Call the initializer
memory.init_shm_segment(..., shared, shsize)
