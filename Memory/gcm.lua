local memory = require'memory'
local vector = require'vector'

-- shared properties
local shared = {};
local shsize = {};


shared.game = {};
shared.game.state = vector.zeros(1)
shared.game.selfdestruct = vector.zeros(1)


shared.processes={}
--current state / count / fps
shared.processes.dynamixel = vector.zeros(3)
shared.processes.xb360 = vector.zeros(3)
--test



-- Keep track of every state machine
-- Use the Config'd FSMs
shared.fsm = {}
if Config and Config.fsm then
  for sm, en in pairs(Config.fsm.enabled) do
    shared.fsm[sm] = ''
  end
end

-- Call the initializer
memory.init_shm_segment(..., shared, shsize)
