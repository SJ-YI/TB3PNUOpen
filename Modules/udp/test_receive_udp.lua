dofile('../../include.lua')
print('\n\t== UDP Test ==')
-- Send data to MATLAB


local msg = 'hello';
local udp = require 'udp'
local udp_receiver = udp.new_receiver(54321)
assert(udp_receiver,"Bad udp receiver!")
local unix = require'unix'


for i=1,100 do	
	while udp_receiver:size()<1 do unix.usleep(1e5) end
	local full_pkt = udp_receiver:receive()
	io.write('\tLOCAL | Received ', #full_pkt, ' bytes', '\n')
end


udp_receiver:close()
