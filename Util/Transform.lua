local Transform = {}
local mt = {}

local vector = require'vector'
local quaternion = require'quaternion'

local cos = require'math'.cos
local sin = require'math'.sin
local atan2 = require'math'.atan2
local acos = require'math'.acos
local sqrt = require'math'.sqrt
local vnew, vcopy = vector.new, vector.copy
local vnorm = vector.norm

function Transform.inv(a)
	local p = {a[1][4],a[2][4],a[3][4]}
	local r = {
	  {a[1][1],a[2][1],a[3][1]},
	  {a[1][2],a[2][2],a[3][2]},
	  {a[1][3],a[2][3],a[3][3]}
	}
	return setmetatable({
		{r[1][1], r[1][2], r[1][3], -(r[1][1]*p[1]+r[1][2]*p[2]+r[1][3]*p[3])},
		{r[2][1], r[2][2], r[2][3], -(r[2][1]*p[1]+r[2][2]*p[2]+r[2][3]*p[3])},
		{r[3][1], r[3][2], r[3][3], -(r[3][1]*p[1]+r[3][2]*p[2]+r[3][3]*p[3])},
		{0,0,0,1}
	}, mt)
end

local function eye()
  return setmetatable({
		{1, 0, 0, 0},
		{0, 1, 0, 0},
		{0, 0, 1, 0},
		{0, 0, 0, 1}
	}, mt)
end
Transform.eye = eye

function Transform.rotX(a)
  local ca = cos(a)
  local sa = sin(a)
  return setmetatable({
	  {1, 0, 0, 0},
	  {0, ca, -sa, 0},
	  {0, sa, ca, 0},
	  {0, 0, 0, 1}
	}, mt)
end

function Transform.rotY(a)
  local ca = cos(a)
  local sa = sin(a)
  return setmetatable({
	  {ca, 0, sa, 0},
	  {0, 1, 0, 0},
	  {-sa, 0, ca, 0},
	  {0, 0, 0, 1}
	}, mt)
end

function Transform.rotZ(a)
  local ca = cos(a)
  local sa = sin(a)
  return setmetatable({
	  {ca, -sa, 0, 0},
	  {sa, ca, 0, 0},
	  {0, 0, 1, 0},
	  {0, 0, 0, 1}
	}, mt)
end

function Transform.trans(dx, dy, dz)
  return setmetatable({
	  {1, 0, 0, dx},
	  {0, 1, 0, dy},
	  {0, 0, 1, dz},
	  {0, 0, 0, 1}
	}, mt)
end

-- Mutate a matrix
function Transform.rotateXdot(t, a)
  local ca = cos(a)
  local sa = sin(a)
	for i=1,3 do
		local ty = t[i][2]
		local tz = t[i][3]
		t[i][1] = 0
		t[i][2] = -sa*ty + ca*tz
		t[i][3] = -ca*ty - sa*tz
		t[i][4] = 0
	end
	return t
end

function Transform.rotateYdot(t, a)
  local ca = cos(a)
  local sa = sin(a)
	for i=1,3 do
		local tx = t[i][1]
		local tz = t[i][3]
		t[i][1] = -sa*tx - ca*tz
		t[i][2] = 0
		t[i][3] = ca*tx - sa*tz
		t[i][4] = 0
	end
	return t
end

function Transform.rotateZdot(t, a)
  local ca = cos(a)
  local sa = sin(a)
	for i=1,3 do
		local tx = t[i][1]
		local ty = t[i][2]
		t[i][1] = -sa*tx + ca*ty
		t[i][2] = -ca*tx - sa*ty
		t[i][3] = 0
		t[i][4] = 0
	end
	return t
end

function Transform.rotateX(t, a)
  local ca = cos(a)
  local sa = sin(a)
	for i=1,3 do
		local ty = t[i][2]
		local tz = t[i][3]
		t[i][2] = ca*ty + sa*tz
		t[i][3] = -sa*ty + ca*tz
	end
	return t
end

function Transform.rotateY(t, a)
  local ca = cos(a)
  local sa = sin(a)
	for i=1,3 do
		local tx = t[i][1]
		local tz = t[i][3]
		t[i][1] = ca*tx - sa*tz
		t[i][3] = sa*tx + ca*tz
	end
	return t
end

function Transform.rotateZ(t, a)
  local ca = cos(a)
  local sa = sin(a)
	for i=1,3 do
		local tx = t[i][1]
		local ty = t[i][2]
		t[i][1] = ca*tx + sa*ty
		t[i][2] = -sa*tx + ca*ty
	end
	return t
end

function Transform.translate(t, px, py, pz)
	t[1][4] = t[1][4] + t[1][1]*px + t[1][2]*py + t[1][3]*pz
  t[2][4] = t[2][4] + t[2][1]*px + t[2][2]*py + t[2][3]*pz
  t[3][4] = t[3][4] + t[3][1]*px + t[3][2]*py + t[3][3]*pz
	return t
end

-- End mutations

-- Recovering Euler Angles
-- Good resource: http://www.vectoralgebra.info/eulermatrix.html
function Transform.to_zyz(t)
  -- Modelling and Control of Robot Manipulators, pg. 30
  -- Lorenzo Sciavicco and Bruno Siciliano
  local e = vector.zeros(3)
  e[1]=atan2(t[2][3],t[1][3]) -- Z (phi)
  e[2]=atan2(sqrt( t[1][3]^2 + t[2][3]^2),t[3][3]) -- Y (theta)
  e[3]=atan2(t[3][2],-t[3][1]) -- Z' (psi)


  if t[3][2]==0 and t[3][1]==0 then --singular case
    --c1c3 - s1s3=t[1][1]
    --c1s3 + s1c3=t[2][1]
    --solve for c3 (0 or pi)
    local c3 = t[1][1]*cos(e[1]) + t[2][1]*sin(e[1])
    e[3]=acos(c3)
  end
  return e
end

-- RPY is XYZ convention
function Transform.to_rpy(t)
  -- http://planning.cs.uiuc.edu/node103.html
  -- returns [roll, pitch, yaw] vector
  local e = {}
  e[1]=atan2(t[3][2],t[3][3]) --Roll
  e[2]=atan2(-t[3][1],sqrt( t[3][2]^2 + t[3][3]^2) ) -- Pitch
  e[3]=atan2(t[2][1],t[1][1]) -- Yaw
  return e
end

function Transform.position6D(tr)
  return vnew{
  tr[1][4],tr[2][4],tr[3][4],
  atan2(tr[3][2],tr[3][3]),
  -math.asin(tr[3][1]),
  atan2(tr[2][1],tr[1][1])
  }
end
function Transform.string6D(tr)
  return string.format('%.2f %.2f %.2f | %.2f %.2f %.2f',
  tr[1][4],tr[2][4],tr[3][4],
  atan2(tr[3][2],tr[3][3]) * RAD_TO_DEG,
  -math.asin(tr[3][1]) * RAD_TO_DEG,
  atan2(tr[2][1],tr[1][1]) * RAD_TO_DEG
  )
end

function Transform.position(tr)
  return {tr[1][4],tr[2][4],tr[3][4]}
end

function Transform.position4(tr)
  return vnew{tr[1][4],tr[2][4],tr[3][4],tr[4][4]}
end

-- Rotation Matrix to quaternion
-- from Yida.  Adapted to take a transformation matrix
--BUGBUGBUG... to_quatp() is wrong!
--BUGBUGBUG... to_quatp() is wrong!
--BUGBUGBUG... to_quatp() is wrong!
function Transform.to_quatp( t )
  local q = quaternion.new()
  local tr = t[1][1] + t[2][2] + t[3][3]
  if tr > 0 then
    local S = sqrt(tr + 1.0) * 2
    q[1] = 0.25 * S
    q[2] = (t[3][2] - t[2][3]) / S
    q[3] = (t[1][3] - t[3][1]) / S
    q[4] = (t[2][1] - t[1][2]) / S
  elseif t[1][1] > t[2][2] and t[1][1] > t[3][3] then
    local S = sqrt(1.0 + t[1][1] - t[2][2] - t[3][3]) * 2
    q[1] = (t[3][2] - t[2][3]) / S
    q[2] = 0.25 * S
    q[3] = (t[1][2] + t[2][1]) / S
    q[4] = (t[1][3] + t[3][1]) / S
  elseif t[2][2] > t[3][3] then
    local S = sqrt(1.0 + t[2][2] - t[1][1] - t[3][3]) * 2
    q[1] = (t[1][3] - t[3][1]) / S
    q[2] = (t[1][2] + t[2][1]) / S
    q[3] = 0.25 * S
    q[4] = (t[2][3] + t[3][2]) / S
  else
    local S = sqrt(1.0 + t[3][3] - t[1][1] - t[2][2]) * 2
    q[1] = (t[2][1] - t[1][2]) / S
    q[2] = (t[1][3] + t[3][1]) / S
    q[3] = (t[2][3] + t[3][2]) / S
    q[4] = 0.25 * S
  end
	q[5] = t[1][4]
	q[6] = t[2][4]
	q[7] = t[3][4]
  return q
end

function Transform.from_quatp(q)
  return setmetatable({
		{
			1 - 2 * q[3] * q[3] - 2 * q[4] * q[4],
			2 * q[2] * q[3] - 2 * q[4] * q[1],
			2 * q[2] * q[4] + 2 * q[3] * q[1],
			q[5],
		},
		{
			2 * q[2] * q[3] + 2 * q[4] * q[1],
			1 - 2 * q[2] * q[2] - 2 * q[4] * q[4],
			2 * q[3] * q[4] - 2 * q[2] * q[1],
			q[6]
		},
		{
			2 * q[2] * q[4] - 2 * q[3] * q[1],
			2 * q[3] * q[4] + 2 * q[2] * q[1],
			1 - 2 * q[2] * q[2] - 2 * q[3] * q[3],
			q[7],
		},
		{0,0,0,1}
	}, mt)
end

function Transform.from_quaternion(q, pos)
  return setmetatable({
		{
			1 - 2 * q[3] * q[3] - 2 * q[4] * q[4],
			2 * q[2] * q[3] - 2 * q[4] * q[1],
			2 * q[2] * q[4] + 2 * q[3] * q[1],
			pos[1],
		},
		{
			2 * q[2] * q[3] + 2 * q[4] * q[1],
			1 - 2 * q[2] * q[2] - 2 * q[4] * q[4],
			2 * q[3] * q[4] - 2 * q[2] * q[1],
			pos[2]
		},
		{
			2 * q[2] * q[4] - 2 * q[3] * q[1],
			2 * q[3] * q[4] + 2 * q[2] * q[1],
			1 - 2 * q[2] * q[2] - 2 * q[3] * q[3],
			pos[3],
		},
		{0,0,0,1}
	}, mt)
end

-- Can give the position
local trans = Transform.trans
function Transform.from_quaternion2(q, pos)
  local t = Transform.eye()
  t[1][1] = 1 - 2 * q[3] * q[3] - 2 * q[4] * q[4]
  t[1][2] = 2 * q[2] * q[3] - 2 * q[4] * q[1]
  t[1][3] = 2 * q[2] * q[4] + 2 * q[3] * q[1]
  t[2][1] = 2 * q[2] * q[3] + 2 * q[4] * q[1]
  t[2][2] = 1 - 2 * q[2] * q[2] - 2 * q[4] * q[4]
  t[2][3] = 2 * q[3] * q[4] - 2 * q[2] * q[1]
  t[3][1] = 2 * q[2] * q[4] - 2 * q[3] * q[1]
  t[3][2] = 2 * q[3] * q[4] + 2 * q[2] * q[1]
  t[3][3] = 1 - 2 * q[2] * q[2] - 2 * q[3] * q[3]
  if pos then return trans(unpack(pos))*t end
  return t
end

function Transform.transform6DXYZ(p)
  --  t = t.translate(p[0],p[1],p[2]).rotateX(p[3]).rotateY(p[4]).rotateZ(p[5]);
  local cwx = cos(p[4])
  local swx = sin(p[4])
  local cwy = cos(p[5])
  local swy = sin(p[5])
  local cwz = cos(p[6])
  local swz = sin(p[6])
  return setmetatable({
    {cwy*cwz, -cwy*swz, swy, p[1]},
    {cwx*swz+cwz*swx*swy, cwx*cwz-swx*swy*swz, -cwy*swx, p[2]},
    {swx*swz-cwx*cwz*swy, cwz*swx+cwx*swy*swz, cwx*cwy, p[3]},
    {0,0,0,1},
    }, mt)
end

function Transform.position6DXYZ(tr)
  return vnew{
  tr[1][4],tr[2][4],tr[3][4],
  atan2(-tr[2][3],tr[3][3]), --Roll
  math.asin(tr[1][3]), -- Pitch
  atan2(-tr[1][2],tr[1][1]) -- Yaw
  }
end


function Transform.transform6D(p)
  local cwx = cos(p[4])
  local swx = sin(p[4])
  local cwy = cos(p[5])
  local swy = sin(p[5])
  local cwz = cos(p[6])
  local swz = sin(p[6])
  return setmetatable({
    {cwy*cwz, swx*swy*cwz-cwx*swz, cwx*swy*cwz+swx*swz, p[1]},
    {cwy*swz, swx*swy*swz+cwx*cwz, cwx*swy*swz-swx*cwz, p[2]},
    {-swy, swx*cwy, cwx*cwy, p[3]},
    {0,0,0,1},
    }, mt)
end

function Transform.getangularvel(T0,T1,dt)
  local t = Transform.eye()
  t[1][1]=(T1[1][1]-T0[1][1])/dt
  t[1][2]=(T1[1][2]-T0[1][2])/dt
  t[1][3]=(T1[1][3]-T0[1][3])/dt
  t[2][1]=(T1[2][1]-T0[2][1])/dt
  t[2][2]=(T1[2][2]-T0[2][2])/dt
  t[2][3]=(T1[2][3]-T0[2][3])/dt
  t[3][1]=(T1[3][1]-T0[3][1])/dt
  t[3][2]=(T1[3][2]-T0[3][2])/dt
  t[3][3]=(T1[3][3]-T0[3][3])/dt

  local vx=(T1[1][4]-T0[1][4])/dt
  local vy=(T1[2][4]-T0[2][4])/dt
  local vz=(T1[3][4]-T0[3][4])/dt

  -- local t_ws= t*Transform.inv(T1)
	local t_ws= Transform.inv(T1)*t
  -- print("=================")
  -- print(Transform.tostring(t_ws))
  -- print("=================")
  return{vx,vy,vz, -t_ws[2][3], t_ws[1][3], -t_ws[1][2]}
end




-- http://planning.cs.uiuc.edu/node102.html
function Transform.from_rpy_trans(rpy, trans)
  local gamma, beta, alpha = unpack(rpy)
  return setmetatable({
    {cos(alpha) * cos(beta), cos(alpha) * sin(beta) * sin(gamma) - sin(alpha) * cos(gamma), cos(alpha) * sin(beta) * cos(gamma) + sin(alpha) * sin(gamma), trans[1]},
    {sin(alpha) * cos(beta), sin(alpha) * sin(beta) * sin(gamma) + cos(alpha) * cos(gamma), sin(alpha) * sin(beta) * cos(gamma) - cos(alpha) * sin(gamma), trans[2]},
    {-sin(beta), cos(beta) * sin(gamma), cos(beta) * cos(gamma), trans[3]},
    {0, 0, 0, 1}
  }, mt)
end

local function mul(t1, t2)
  local t = {}
  if type(t2[1]) == "number" then
    -- Matrix * Vector
    for i = 1,4 do
      t[i] = t1[i][1] * t2[1]
      + t1[i][2] * t2[2]
      + t1[i][3] * t2[3]
      + t1[i][4] * (t2[4] or 1)
    end
    return vnew(t)
  elseif type(t2[1]) == "table" then
    -- Matrix * Matrix
		----[[
    for i = 1,4 do
      t[i] = {}
      for j = 1,4 do
        t[i][j] = t1[i][1] * t2[1][j]
        + t1[i][2] * t2[2][j]
        + t1[i][3] * t2[3][j]
        + t1[i][4] * t2[4][j]
      end
    end
		--]]
		--[[
		t[1] = {
			t1[1][1] * t2[1][1] + t1[1][2] * t2[2][1] + t1[1][3] * t2[3][1] + t1[1][4] * t2[4][1],
			t1[1][1] * t2[1][2] + t1[1][2] * t2[2][2] + t1[1][3] * t2[3][2] + t1[1][4] * t2[4][2],
			t1[1][1] * t2[1][3] + t1[1][2] * t2[2][3] + t1[1][3] * t2[3][3] + t1[1][4] * t2[4][3],
			t1[1][1] * t2[1][4] + t1[1][2] * t2[2][4] + t1[1][3] * t2[3][4] + t1[1][4] * t2[4][4]
		}
		t[2] = {
			t1[2][1] * t2[1][1] + t1[2][2] * t2[2][1] + t1[2][3] * t2[3][1] + t1[2][4] * t2[4][1],
			t1[2][1] * t2[1][2] + t1[2][2] * t2[2][2] + t1[2][3] * t2[3][2] + t1[2][4] * t2[4][2],
			t1[2][1] * t2[1][3] + t1[2][2] * t2[2][3] + t1[2][3] * t2[3][3] + t1[2][4] * t2[4][3],
			t1[2][1] * t2[1][4] + t1[2][2] * t2[2][4] + t1[2][3] * t2[3][4] + t1[2][4] * t2[4][4]
		}
		t[3] = {
			t1[3][1] * t2[1][1] + t1[3][2] * t2[2][1] + t1[3][3] * t2[3][1] + t1[3][4] * t2[4][1],
			t1[3][1] * t2[1][2] + t1[3][2] * t2[2][2] + t1[3][3] * t2[3][2] + t1[3][4] * t2[4][2],
			t1[3][1] * t2[1][3] + t1[3][2] * t2[2][3] + t1[3][3] * t2[3][3] + t1[3][4] * t2[4][3],
			t1[3][1] * t2[1][4] + t1[3][2] * t2[2][4] + t1[3][3] * t2[3][4] + t1[3][4] * t2[4][4]
		}
		t[4] = {
			t1[4][1] * t2[1][1] + t1[4][2] * t2[2][1] + t1[4][3] * t2[3][1] + t1[4][4] * t2[4][1],
			t1[4][1] * t2[1][2] + t1[4][2] * t2[2][2] + t1[4][3] * t2[3][2] + t1[4][4] * t2[4][2],
			t1[4][1] * t2[1][3] + t1[4][2] * t2[2][3] + t1[4][3] * t2[3][3] + t1[4][4] * t2[4][3],
			t1[4][1] * t2[1][4] + t1[4][2] * t2[2][4] + t1[4][3] * t2[3][4] + t1[4][4] * t2[4][4]
		}
		--]]
    return setmetatable(t, mt)
  end
end

-- Copy
function Transform.copy(tt, t0)
  if type(tt)=='table' and not t0 then
    -- Copy the table
    return setmetatable({
    	{unpack(tt[1])},
    	{unpack(tt[2])},
    	{unpack(tt[3])},
    	{unpack(tt[4])},
		}, mt)
  end
  local t = t0 or setmetatable({{},{},{},{}}, mt)
  for i=1,3 do
    for j=1,4 do
      t[i][j] = tt[i][j]
    end
  end
  -- copy a tensor
  return t
end

function Transform.from_flat(flat)
  return setmetatable({
    {unpack(flat, 1, 4)},
    {unpack(flat, 5, 8)},
    {unpack(flat, 9, 12)},
    {unpack(flat, 13, 16)}
  }, mt)
end

function Transform.from_flatrot(flat)
  return setmetatable({
    {flat[1],flat[2],flat[3],0},
    {flat[4],flat[5],flat[6],0},
    {flat[7],flat[8],flat[9],0},
    {0,0,0,1}
  }, mt)
end

-- Do it unsafe; assume a table
function Transform.flatten(t)
  return vnew{t[1][1], t[1][2], t[1][3], t[1][4], t[2][1], t[2][2], t[2][3], t[2][4], t[3][1], t[3][2], t[3][3], t[3][4], t[4][1], t[4][2], t[4][3], t[4][4]}
end

-- Do it unsafe; assume a table
function Transform.new(tt)
	--[[
  vnew(tt[1])
  vnew(tt[2])
  vnew(tt[3])
  vnew(tt[4])
	--]]
  return setmetatable(tt, mt)
end

-- Use the 6D vector
local function tostring(t, formatstr)
  return tostring( Transform.position6D(t), formatstr )
end
-- Full matrix for the library tostring helper
function Transform.tostring(tr)
  local pr = {}
  for i=1,4 do
    local row = {}
    for j=1,4 do
      table.insert(row,string.format('%6.3f',tr[i][j] or math.huge))
    end
    local c = table.concat(row,', ')
    table.insert(pr,string.format('[%s]',c))
  end
  return table.concat(pr,'\n')
end

mt.__mul = mul
mt.__tostring = Transform.tostring --tostring
--mt.__call = function(self,idx) print('idx',idx,type(idx),self[idx]); return self[idx] end

return Transform
