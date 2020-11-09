local util = {}
local vector = require'vector'
local vpose = require'vector'.pose
local sformat = string.format
local abs = math.abs
local min, max = math.min, math.max
local sin, cos = math.sin, math.cos

local PI, TWO_PI = math.pi, 2*math.pi


local crc16_tab = { 0x0000, 0x1021, 0x2042, 0x3063, 0x4084,
        0x50a5, 0x60c6, 0x70e7, 0x8108, 0x9129, 0xa14a, 0xb16b, 0xc18c, 0xd1ad,
        0xe1ce, 0xf1ef, 0x1231, 0x0210, 0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7,
        0x62d6, 0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c, 0xf3ff, 0xe3de,
        0x2462, 0x3443, 0x0420, 0x1401, 0x64e6, 0x74c7, 0x44a4, 0x5485, 0xa56a,
        0xb54b, 0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d, 0x3653, 0x2672,
        0x1611, 0x0630, 0x76d7, 0x66f6, 0x5695, 0x46b4, 0xb75b, 0xa77a, 0x9719,
        0x8738, 0xf7df, 0xe7fe, 0xd79d, 0xc7bc, 0x48c4, 0x58e5, 0x6886, 0x78a7,
        0x0840, 0x1861, 0x2802, 0x3823, 0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948,
        0x9969, 0xa90a, 0xb92b, 0x5af5, 0x4ad4, 0x7ab7, 0x6a96, 0x1a71, 0x0a50,
        0x3a33, 0x2a12, 0xdbfd, 0xcbdc, 0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b,
        0xab1a, 0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03, 0x0c60, 0x1c41,
        0xedae, 0xfd8f, 0xcdec, 0xddcd, 0xad2a, 0xbd0b, 0x8d68, 0x9d49, 0x7e97,
        0x6eb6, 0x5ed5, 0x4ef4, 0x3e13, 0x2e32, 0x1e51, 0x0e70, 0xff9f, 0xefbe,
        0xdfdd, 0xcffc, 0xbf1b, 0xaf3a, 0x9f59, 0x8f78, 0x9188, 0x81a9, 0xb1ca,
        0xa1eb, 0xd10c, 0xc12d, 0xf14e, 0xe16f, 0x1080, 0x00a1, 0x30c2, 0x20e3,
        0x5004, 0x4025, 0x7046, 0x6067, 0x83b9, 0x9398, 0xa3fb, 0xb3da, 0xc33d,
        0xd31c, 0xe37f, 0xf35e, 0x02b1, 0x1290, 0x22f3, 0x32d2, 0x4235, 0x5214,
        0x6277, 0x7256, 0xb5ea, 0xa5cb, 0x95a8, 0x8589, 0xf56e, 0xe54f, 0xd52c,
        0xc50d, 0x34e2, 0x24c3, 0x14a0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
        0xa7db, 0xb7fa, 0x8799, 0x97b8, 0xe75f, 0xf77e, 0xc71d, 0xd73c, 0x26d3,
        0x36f2, 0x0691, 0x16b0, 0x6657, 0x7676, 0x4615, 0x5634, 0xd94c, 0xc96d,
        0xf90e, 0xe92f, 0x99c8, 0x89e9, 0xb98a, 0xa9ab, 0x5844, 0x4865, 0x7806,
        0x6827, 0x18c0, 0x08e1, 0x3882, 0x28a3, 0xcb7d, 0xdb5c, 0xeb3f, 0xfb1e,
        0x8bf9, 0x9bd8, 0xabbb, 0xbb9a, 0x4a75, 0x5a54, 0x6a37, 0x7a16, 0x0af1,
        0x1ad0, 0x2ab3, 0x3a92, 0xfd2e, 0xed0f, 0xdd6c, 0xcd4d, 0xbdaa, 0xad8b,
        0x9de8, 0x8dc9, 0x7c26, 0x6c07, 0x5c64, 0x4c45, 0x3ca2, 0x2c83, 0x1ce0,
        0x0cc1, 0xef1f, 0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba, 0x8fd9, 0x9ff8,
        0x6e17, 0x7e36, 0x4e55, 0x5e74, 0x2e93, 0x3eb2, 0x0ed1, 0x1ef0 };


function util.get_crc16(byte_array)
  local cksum = 0
  for i=1,#byte_array do
    --cksum = crc16_tab[(((cksum >> 8) ^ *buf++) & 0xFF)] ^ (cksum << 8);
    local index0 = bit.band(    bit.bxor(  bit.rshift(cksum,8), byte_array[i] ) ,   0xff)
    cksum= bit.band( 0xffff,  bit.bxor( crc16_tab[index0+1] , bit.lshift(cksum,8) )) --Lua index start with 1...
  end
  return cksum
end

function util.bytes_to_double16(arr, index,scale)
  local n = arr[index]*256 + arr[index+1]
  n = (n > 32767) and (n - 65536) or n
  return n/scale
end

function util.bytes_to_double32(arr, index,scale)
  local n = arr[index]*16777216 + arr[index+1]*65536 + arr[index+2]*256 + arr[index+3]
  n = (n > 2147483647) and (n - 4294967296) or n
  return n/scale
end

function util.int32_to_bytes(n)
  if n > 2147483647 then error(n.." is too large",2) end
  if n < -2147483648 then error(n.." is too small",2) end
  n = (n < 0) and (4294967296 + n) or n   -- adjust for 2's complement
  return (math.modf(n/16777216))%256, (math.modf(n/65536))%256, (math.modf(n/256))%256, n%256
end

function util.bytes_to_int32(b1, b2, b3, b4)
  if not b4 then error("need four bytes to convert to int",2) end
  local n = b1*16777216 + b2*65536 + b3*256 + b4
  n = (n > 2147483647) and (n - 4294967296) or n
  return n
end

function util.bytes_to_int16(b1, b2)
  if not b2 then error("need four bytes to convert to int",2) end
  local n = b1*256 + b2
  n = (n > 32767) and (n - 65536) or n
  return n
end




function util.mod_angle(a)
  -- Reduce angle to [-pi, pi)
  local b = a % TWO_PI
	return b >= PI and (b - TWO_PI) or b
end

function util.mod_jangles(q,q0)
  q2={}
  maxerr=0
  for i=1,#q do
    local delta=util.mod_angle(q[i]-q0[i])
    q2[i]=q0[i]+delta
    if math.abs(delta)>maxerr then maxerr=math.abs(delta) end
  end
  return q2,maxerr
end


function util.diff_transform(a,b)
  local c={}
  --return transform (a-b) with rpy angle cleaned up to (-pi,pi)
  for i=1,3 do c[i]=a[i]-b[i] end
  for i=4,6 do
    c[i] = (a[i]-b[i]) % (2*math.pi)
    if c[i] >= math.pi then c[i] = (c[i] - 2*math.pi) end
  end
  return c
end


function util.sign(x)
  -- return sign of the number (-1, 0, 1)
  if x > 0 then return 1
  elseif x < 0 then return -1
  else return 0
  end
end

function util.min(t)
  -- find the minimum element in the array table
  -- returns the min value and its index
  local imin = 0
  local tmin = math.huge
  for i,v in ipairs(t)  do
    if v < tmin then
      tmin = v
      imin = i
    end
  end
  return tmin, imin
end

function util.max(t)
  -- find the maximum element in the array table
  -- returns the min value and its index
  local imax = 0
  local tmax = -math.huge
	for i,v in ipairs(t)  do
    if v > tmax then
      tmax = v
      imax = i
    end
  end
  return tmax, imax
end

function util.se2_interpolate(t, u1, u2)
  -- helps smooth out the motions using a weighted average
  return vector.new{
    u1[1]+t*(u2[1]-u1[1]),
    u1[2]+t*(u2[2]-u1[2]),
    u1[3]+t*util.mod_angle(u2[3]-u1[3])
  }
end

function util.se3_interpolate(t, u1, u2, u3)
  --Interpolation between 3 xya values
  if t<0.5 then
    local tt=t*2
    return vector.new{
      u1[1]+tt*(u2[1]-u1[1]),
      u1[2]+tt*(u2[2]-u1[2]),
      u1[3]+tt*util.mod_angle(u2[3]-u1[3])
    }
  else
    local tt=t*2-1
    return vector.new{
      u2[1]+tt*(u3[1]-u2[1]),
      u2[2]+tt*(u3[2]-u2[2]),
      u2[3]+tt*util.mod_angle(u3[3]-u2[3])
    }
  end
end

function util.quatp_interpolate(t, u1, u2) --interpolate two quaternion+pos
  return vector.new{
    u1[1]+t*(u2[1]-u1[1]),
    u1[2]+t*(u2[2]-u1[2]),
    u1[3]+t*(u2[3]-u1[3]),
    u1[4]+t*(u2[4]-u1[4]),
    u1[5]+t*(u2[5]-u1[5]),
    u1[6]+t*(u2[6]-u1[6]),
    u1[7]+t*(u2[7]-u1[7])
  }
end

function util.shallow_copy(a)
  --copy the table by value
  local ret={}
  for k,v in pairs(a) do ret[k]=v end
  return ret
end


--Piecewise linear function for IMU feedback
local function procFunc(a,deadband,maxvalue)
  local b = min( max(0,abs(a)-deadband), maxvalue)
  if a<=0 then return -b end
  return b
end

local function procFunc2(a,deadband, minvalue,maxvalue)
  if abs(a)<deadband then return 0
  else
    local b = min( max(0,abs(a)-deadband), maxvalue)+minvalue
    if a<=0 then return -b end
    return b
  end
end


local function p_feedback(org,target, p_gain, max_vel, dt)
  local err = target-org
  local vel = max(-max_vel,min( max_vel, err*p_gain ))
  return org + vel*dt
end

function util.pid_feedback(err, vel, dt)
  err_deadband = 0*math.pi/180
  max_vel = 2.5 --close to spec
  vel_p_gain = 30 --at 3 degree (3*math.pi/180) reach max accelleration
  acc_p_gain = 20 --Very stiff


  --very soft
  max_vel = 2
  acc_p_gain = 2

  max_acc =  math.huge --max accelleration (m/s^2)
  vel_d_gain = -1

  local velTarget=vector.zeros(7)
  local accTarget=vector.zeros(7)
  local acc=vector.zeros(7)
  for i=1,#err do
    local err_clamped = math.max(0,math.abs(err[i])-err_deadband)
    if err[i]<0 then err_clamped = -err_clamped end
    velTarget[i] = math.max(-max_vel,math.min( max_vel, err_clamped*vel_p_gain ))
    accTarget[i] = math.max(-max_acc,math.min( max_acc,  acc_p_gain*(velTarget[i]-vel[i]) ))
    acc[i] = accTarget[i] + vel[i]*vel_d_gain
  end
  return acc,velTarget
end

function util.linearize(torque0, vel, damping_factor, static_friction)
  local torque=vector.zeros(#torque0);
  for i=1,#torque0 do
    local t1 = torque0[i]+vel[i]*damping_factor[i];
    if t1>0.05 then
      torque[i]=static_friction[i]+t1;
    elseif t1<-0.05 then
      torque[i]=-static_friction[i]+t1;
    else
      torque[i]=0;
    end
  end
  return torque
end



function util.clamp_vector(values,min_values,max_values)
	local clamped = vector.new()
	for i,v in ipairs(values) do
		clamped[i] = max(min(v,max_values[i]),min_values[i])
	end
	return clamped
end

-- Tolerance approach to a vector
-- Kinda like a gradient descent
function util.approachTol(values, targets, speedlimits, dt, tolerance)
  -- Tolerance check (Asumme within tolerance)
  local within_tolerance = true
  -- Iterate through the limits of movements to approach
  --SJ: Now can be used for scalar
  if type(values)=="table" then
    local tp = type(tolerance)
    tolerance = tp=='table' and tolerance or (vector.ones(#speedlimits) * (tp=='number' and tolerance or 1e-6))
    for i,speedlimit in ipairs(speedlimits) do
      -- Target value minus present value
      local delta = targets[i] - values[i]
      -- If any values is out of tolerance,
      -- then we are not within tolerance
      if abs(delta) > tolerance[i] then
        within_tolerance = false
        -- Ensure that we do not move motors too quickly
        delta = procFunc(delta, 0, speedlimit * dt)
        values[i] = values[i] + delta
      end
    end
  else
    tolerance = tolerance or 1e-6
    local delta = targets - values
    if abs(delta) > tolerance then
      within_tolerance = false
      -- Ensure that we do not move motors too quickly
      delta = procFunc(delta, 0, speedlimits * dt)
      values = values + delta
    end
  end
  -- Return the next values to take and if we are within tolerance
  return values, within_tolerance
end

function util.limitVelocity(vel, speedlimits)
  local max_factor=1
  local lim_vel={}
  for i=1,#vel do
    local factor = vel[i]/speedlimits[i]
    if factor>max_factor then max_factor=factor end
  end
  for i=1,#vel do
    lim_vel[i]=vel[i]/max_factor
  end
  return lim_vel
end


-- Tolerance approach to a vector
-- Kinda like a gradient descent

--SJ: This approaches to the DIRECTION of the target position

function util.approachTolTransform(values, targets, vellimit, dt, tol_dist, tol_angle)
  local tolerance_dist = tol_dist or 0.001
  local tolerance_angle = tol_angle or 0.1*math.pi/180

  -- Tolerance check (Asumme within tolerance)
  local within_tolerance = true
  -- Iterate through the limits of movements to approach
  local linearvellimit = vellimit[1] --hack for now

  local cur_pos = vector.slice(values,1,3)
  local target_pos = vector.slice(targets,1,3)
  local delta = target_pos - cur_pos
  local mag_delta = math.sqrt(delta[1]*delta[1] + delta[2]*delta[2] + delta[3]*delta[3])

  if math.abs(mag_delta)>tolerance_dist then
    movement = math.min(mag_delta, linearvellimit*dt)
    values[1] = values[1] + delta[1]/mag_delta * movement
    values[2] = values[2] + delta[2]/mag_delta * movement
    values[3] = values[3] + delta[3]/mag_delta * movement
    within_tolerance = false
  else
    values[1] = targets[1]
    values[2] = targets[2]
    values[3] = targets[3]
  end


  for i=4,6 do --Transform
    -- Target value minus present value
    local delta = targets[i] - values[i]
    if math.abs(delta) > tolerance_angle then
      within_tolerance = false
      -- Ensure that we do not move motors too quickly
      delta = util.procFunc(delta,0,vellimit[i]*dt)
      values[i] = values[i]+delta
    else
      values[i]=targets[i]
    end
  end

  -- Return the next values to take and if we are within tolerance
  return values, within_tolerance
end

function util.approachTolWristTransform( values, targets, vellimit, dt, tolerance )
  tolerance = tolerance or 1e-6
  -- Tolerance check (Asumme within tolerance)
  local within_tolerance = true
  -- Iterate through the limits of movements to approach

  for i=4,6 do --Transform
    -- Target value minus present value
    local delta = targets[i] - values[i]
    if math.abs(delta) > tolerance then
      within_tolerance = false
      -- Ensure that we do not move motors too quickly
      delta = util.procFunc(delta,0,vellimit[i]*dt)
      values[i] = values[i]+delta
    end
  end

  -- Return the next values to take and if we are within tolerance
  return values, within_tolerance
end


-- Tolerance approach to a radian value (to correct direction)
-- Kinda like a gradient descent
--SJ: modangle didnt work for whatever reason so just used math.mod


function util.approachTolRad( values, targets, speedlimits, dt, tolerance, absolute )
  tolerance = tolerance or 1e-6
  -- Tolerance check (Asumme within tolerance)
  local within_tolerance = true
  -- Iterate through the limits of movements to approach
  for i,speedlimit in ipairs(speedlimits) do
    -- Target value minus present value
    local delta = util.mod_angle(targets[i]-values[i])
    if absolute then delta = targets[i]-values[i] end

    -- If any values is out of tolerance,
    -- then we are not within tolerance
    if math.abs(delta) > tolerance then
      within_tolerance = false
      -- Ensure that we do not move motors too quickly
      delta = util.procFunc(delta,0,speedlimit*dt)
      values[i] = values[i] + delta
    end
  end
  -- Return the next values to take and if we are within tolerance
  return values, within_tolerance
end

function util.velProfile(pStart, pCurrent, pEnd)



end






function util.pose_global(pRelative, pose)
  local ca = cos(pose[3])
  local sa = sin(pose[3])
  return vpose{pose[1] + ca*pRelative[1] - sa*pRelative[2],
                    pose[2] + sa*pRelative[1] + ca*pRelative[2],
--                    util.mod_angle(pose[3] + pRelative[3])}
                    pose[3] + pRelative[3]}

--SJ: Using modangle here makes the yaw angle jump which kills walk

end

function util.pose_relative(pGlobal, pose)
  local ca = cos(pose[3])
  local sa = sin(pose[3])
  local px = pGlobal[1]-pose[1]
  local py = pGlobal[2]-pose[2]
  local pa = pGlobal[3]-pose[3]
  return vpose{ca*px + sa*py, -sa*px + ca*py, util.mod_angle(pa)}
end

---table of uniform distributed random numbers
--@param n length of table to return
--@return table of n uniformly distributed random numbers
function util.randu(n)
  local t = {}
  for i = 1,n do t[i] = math.random() end
  return t
end

---Table of normal distributed random numbers.
--@param n length of table to return
--@return table of n normally distributed random numbers
function util.randn(n)
  local t = {}
  for i = 1,n do
    --Inefficient implementation:
    t[i] = math.sqrt(-2.0*math.log(1.0-math.random())) *
                      math.cos(math.pi*math.random())
  end
  return t
end

function util.norm(v,n)
  local t=0
  for i=1,n or #v do
    t=t+v[i]*v[i]
  end
  t=math.sqrt(t)
  return t
end

function util.norm2(v)
  return math.sqrt(v[1]*v[1]+v[2]*v[2])
end

function util.factorial(n)
  if n == 0 then
    return 1
  else
    return n * factorial(n - 1)
  end
end

function util.polyval_bz(alpha, s)
  local b = 0
  local M = #alpha-1
  for k =0,M do
    b = b + alpha[k+1] * factorial(M)/(factorial(k)*factorial(M-k)) * s^k * (1-s)^(M-k)
  end
  return b
end

function util.bezier( alpha, s )

  local n = #alpha
  local m = #alpha[1]
  local M = m-1

  -- Pascal's triangle
  local k = {}
  if M==3 then
    k={1,3,3,1}
  elseif M==4 then
    k={1,4,6,4,1}
  elseif M==5 then
    k={1,5,10,10,5,1}
  elseif M==6 then
    k={1,6,15,20,15,6,1}
  end

  local x = vector.ones(M+1)
  local y = vector.ones(M+1)
  for i=1,M do
    x[i+1] = s*x[i]
    y[i+1] = (1-s)*y[i]
  end

  local value = vector.zeros(n)
  for i=1,n do
    --value[i] = 0
    for j=1,M+1 do value[i] = value[i] + alpha[i][j]*k[j]*x[j]*y[M+2-j] end
  end

  return value
end

function util.spline(breaks,coefs,ph)
  local x_offset, xf = 0,0
  for i=1,#breaks do
    if ph<=breaks[i] then
      local x=ph - x_offset
      xf = coefs[i][1]*x^3 + coefs[i][2]*x^2 + coefs[i][3]*x + coefs[i][4]
      break;
    end
    x_offset = breaks[i]
  end
  return xf
end

function util.get_ph_single(ph,phase1,phase2)
  return math.min(1, math.max(0, (ph-phase1)/(phase2-phase1) ))
end


function util.tablesize(table)
  local count = 0
  for _ in pairs(table) do count = count + 1 end
  return count
end

function util.ptable(t)
  -- print a table key, value pairs
  for k,v in pairs(t) do print(k,v) end
end

function util.print_transform(tr,digit)
  if not tr then return end
  local fdigit=sformat("%d",digit or 2)
  local format_str="%."..fdigit.."f %."..fdigit.."f %."..fdigit.."f (%.1f %.1f %.1f)"
  local str= sformat(format_str,
    tr[1],tr[2],tr[3],tr[4]*180/math.pi,tr[5]*180/math.pi,tr[6]*180/math.pi)
  return str
end

function util.print_jangle(q)
  if #q==6 then
    return sformat("%d %d %d %d %d %d", unpack(vector.new(q)*180/math.pi)  )
  elseif #q==7 then
    return sformat("%d %d %d %d %d %d %d", unpack(vector.new(q)*180/math.pi)  )
  end
end

function util.filesize(fd)
  local current = fd:seek()
  local size = fd:seek("end")
  fd:seek("set", current)
  return size
end

function util.ptorch(data, W, Precision)
  local w = W or 5
  local precision = Precision or 10
  local torch = require'torch'
  local tp = type(data)
  if tp == 'userdata' then
    tp = torch.typename(data) or ''
    local dim = data:dim()
    local row = data:size(1)
    local col = 1
    if dim == 1 then
      for i = 1, row do print(data[i]) end
      print('\n'..tp..' - size: '..row..'\n')
    elseif dim == 2 then
      col = data:size(2)
      for r = 1, row do
        for c = 1, col do
          io.write(string.format("%"..w.."."..precision.."f",data[r][c])..' ')
        end
        io.write('\n')
      end
      print('\n'..tp..' - size: '..row..'x'..col..'\n')
    else
      print'Printing torch objects with more than 2 dimensions is not support'
    end
  else
    print(data)
  end
  io.flush()
end

function util.get_file_size(fd)
	local current=fd:seek()
	local size=fd:seek("end")
	fd:seek("set",current)
	return size
end

function util.get_spline_coeff(t,x)
  local n,m = #t,{}
  local s,dt,slope = vector.zeros(n),vector.zeros(n),vector.zeros(n)
  local a,b,c,d = vector.zeros(n),vector.zeros(n),vector.zeros(n),vector.zeros(n)
  for i=1,n do m[i]=vector.zeros(n) end
  for i=2,n do
    dt[i-1]=t[i]-t[i-1]
    slope[i]=(x[i]-x[i-1])/dt[i-1]
  end
  for i=2,n-1 do
    m[i][i] = 2*(dt[i-1]+dt[i])
    if i>2 then  m[i][i-1],m[i-1][i] = dt[i-1], dt[i-1]  end
    m[i][n] = 6*(slope[i+1]-slope[i])
  end
  for i=2,n-1 do   --forward elimination
    local temp=m[i+1][i]/m[i][i]
    for j=2,n do
      m[i+1][j] = m[i+1][j]-temp*m[i][j]
    end
  end
  for i=n-1, 2, -1 do --backward substitution
    local sum=0
    for j=i,n-1 do sum=sum+m[i][j]*s[j] end
    s[i]=(m[i][n]-sum)/m[i][i]
  end
  for i=1,n-1 do
    a[i]=(s[i+1]-s[i])/(6*dt[i])
    b[i]=s[i]/2
    c[i]=(x[i+1]-x[i])/dt[i] - (2*dt[i]*s[i]+s[i+1]*dt[i])/6
    d[i]=x[i]
  end
  local ret={}
  ret.n,ret.a, ret.b, ret.c, ret.d, ret.t = n,a,b,c,d,t
  return ret
end

function util.spline_eval(coeff, val)
  local t = coeff.t
  for i=1,coeff.n-1 do
    if t[i]<=val and val<t[i+1] then
      sum=coeff.a[i]*math.pow(val-t[i], 3)+
          coeff.b[i]*math.pow(val-t[i],2)+
          coeff.c[i]*(val-t[i]) +  coeff.d[i]
      return sum
    end
  end
  return coeff.d[0]
end

function util.print_pose(pose,acc)
  local str=string.format("%.2f %.2f %.1f",pose[1],pose[2],pose[3]*DEG_TO_RAD)
  if acc then
    str=string.format("%.3f %.3f %.1f",pose[1],pose[2],pose[3]*DEG_TO_RAD)
  end
  return str
end

--https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
--[[
Color table[7]
Intensity 0 1 2 3 4 5 6 7
Normal  Black Red Green Yellow  Blue  Magenta Cyan  White
Bright  Black Red Green Yellow  Blue  Magenta Cyan  White
--]]
local ctable = {
  ['black'] = 0,
  ['red'] = 1,
  ['green'] = 2,
  ['yellow'] = 3,
  ['blue'] = 4,
  ['magenta'] = 5,
  ['cyan'] = 6,
  ['white'] = 7,
}
local color_end = '\027[0m'
--if blink then "\027[31;5m" end

util.color = function(str,fg,bg,blink)
  assert(ctable[fg],string.format('Foreground Color %s does not exist',fg))
  local begin_fg = string.format('\027[%dm',30+ctable[fg])
  if bg then
    assert(ctable[bg],string.format('Background Color %s does not exist',bg))
    local begin_bg = string.format('\027[%dm',40+ctable[bg])
    return begin_bg..begin_fg..str..color_end
  end
  return begin_fg..str..color_end
end


util.colorcode = function(val, max, c1, c2, str)
  str= str or "%d"
  c1 = c1 or 'green'
  c2 = c2 or 'red'
  if math.abs(val)<max then
    return util.color(string.format(str,val), c1)
  else
    return util.color(string.format(str,val), c2)
  end
end


util.procFunc = procFunc
util.procFunc2 = procFunc2
util.p_feedback = p_feedback

return util
