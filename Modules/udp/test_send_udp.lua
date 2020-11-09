dofile('../../include.lua')
print('\n\t== UDP Test ==')

local ffi=require'ffi'


local udp = require 'udp'
local udp_sender = udp.new_sender('127.0.0.1',54321)
assert(udp_sender,"Bad udp sender!")
local unix = require'unix'


local byte_size = 1000*100 --100kb
--local byte_size = 1000*500 --100kb


local data=ffi.new("uint8_t[?]",byte_size)
for i=1,byte_size do data[i-1]=i end
msg=ffi.string(data,byte_size)


for i=1,100 do
	local ret, uuid = udp_sender:send_all( msg )
	if not uuid and ret==#msg then
		io.write('LOCAL | Sent ', ret, ' bytes of ', #msg, '\n')
	elseif uuid then
		io.write(uuid,' | Sent ', #msg, ' bytes in ', #ret, ' packets: ', table.concat(ret, ', '), '\n\n')
	else
		print('!!! LOCAL |  Sent '..ret..' bytes out of '..#msg..' !!!')
	end
	unix.usleep(1E6*0.5)
end

print('GOOD')

udp_sender:close()
print('DONE')
