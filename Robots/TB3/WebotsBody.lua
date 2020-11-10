local WebotsBody = {}
local ww, cw, mw, kw, sw, fw, rw, vw, kb, rosw
local ffi = require'ffi'
require'wcm'
require'hcm'
local util = require'util'
local T = require'Transform'
local si = require'simple_ipc'
local sr = require'serialization'
local rospub, rgb_ch,lidar_ch,pose_ch,jointstate_ch

rgb_ch = si.new_publisher("rgb")
depth_ch = si.new_publisher("depth")
lidar_ch = si.new_publisher("lidar")
pose_ch = si.new_publisher("pose")
jointstate_ch = si.new_publisher("jointstate")
jointcmd_ch = si.new_subscriber("jointcmd")

hcm.set_base_zeropos({0,0,0})

local get_time = webots.wb_robot_get_time
local nJoint = Config.nJoint
local jointNames = Config.jointNames
local servo = Config.servo

-- Added to Config rather than hard-coded
local ENABLE_POSE = Config.sensors.pose
local ENABLE_IMU = Config.sensors.imu
local ENABLE_CAMERA, NEXT_CAMERA = Config.sensors.front_camera, 0
local ENABLE_HEAD_LIDAR, NEXT_HEAD_LIDAR = Config.sensors.head_lidar, 0
local ENABLE_KINECT, NEXT_KINECT = Config.sensors.kinect, 0

local broadcast_count=0
local set_pos, get_pos = webots.wb_motor_set_position, webots.wb_position_sensor_get_value

local PID_P = 32 * vector.ones(nJoint)

-- Acquire the timesteps
local timeStep = webots.wb_robot_get_basic_time_step()
local camera_timeStep = math.max(Config.camera_timestep or 33, timeStep)
local lidar_timeStep = math.max(Config.lidar_timestep or 25, timeStep)
local velodyne_timeStep = math.max(Config.velodyne_timestep or 50, timeStep) --max 20fps
local kinect_timeStep = math.max(Config.kinect_timestep or 30, timeStep)

local NEXT_PATHPLAN=get_time()


-- Setup the webots tags
local tags = {}
local t_last_error = -math.huge

tags.receiver = webots.wb_robot_get_device("receiver")
if tags.receiver>0 then
	webots.wb_receiver_enable(tags.receiver, timeStep)
	webots.wb_receiver_set_channel(tags.receiver, 13)
end

-- Ability to turn on/off items
local t_last_keypress = get_time()
--webots.wb_robot_keyboard_enable(100)
webots.wb_keyboard_enable(100) --8.5.0 change

local gps_pose0 = nil
local seq=0


local key_action = {
		h = function(override)
			if override~=nil then en=override else en=ENABLE_HEAD_LIDAR==false end
      if en==false and tags.head_lidar then
        print(util.color('HEAD_LIDAR disabled!','yellow'))
--        webots.wb_camera_disable(tags.head_lidar)
        webots.wb_lidar_disable(tags.head_lidar)
        ENABLE_HEAD_LIDAR = false
      elseif tags.head_lidar then
        print(util.color('HEAD_LIDAR enabled!','green'))
--        webots.wb_camera_enable(tags.head_lidar,lidar_timeStep)
        webots.wb_lidar_enable(tags.head_lidar,lidar_timeStep)
				NEXT_HEAD_LIDAR = get_time() + lidar_timeStep / 1000
        ENABLE_HEAD_LIDAR = true
      end
    end,
    l = function(override)
			if override~=nil then en=override else en=ENABLE_CHEST_LIDAR==false end
      if en==false and tags.chest_lidar then
        print(util.color('CHEST_LIDAR disabled!','yellow'))
--        webots.wb_camera_disable(tags.chest_lidar)
        webots.wb_lidar_disable(tags.chest_lidar)
        ENABLE_CHEST_LIDAR = false
      elseif tags.chest_lidar then
        print(util.color('CHEST_LIDAR enabled!','green'))
--        webots.wb_camera_enable(tags.chest_lidar,lidar_timeStep)
        webots.wb_lidar_enable(tags.chest_lidar,lidar_timeStep)
				NEXT_CHEST_LIDAR = get_time() + lidar_timeStep / 1000
        ENABLE_CHEST_LIDAR = true
      end
    end,
    y = function(override)
			if override~=nil then en=override else en=ENABLE_VELODYNE1==false end
      if en==false and tags.velodyne1 then
        print(util.color('VELODYNE #1 disabled!','yellow'))
        webots.wb_lidar_disable(tags.velodyne1,velodyne_timeStep)
        ENABLE_VELODYNE1 = false
      elseif tags.velodyne1 then
        print(util.color('VELODYNE #1 enabled!','green'))
        webots.wb_lidar_enable(tags.velodyne1,velodyne_timeStep)
				NEXT_VELODYNE1 = get_time() + lidar_timeStep / 1000
        ENABLE_VELODYNE1 = true
      end
    end,
    k = function(override)
      if override~=nil then en=override else en=ENABLE_KINECT==false end
      if en==false and tags.kinect then
        print(util.color('KINECT disabled!','yellow'))
        webots.wb_camera_disable(tags.kinectRGB)
        webots.wb_range_finder_disable(tags.kinectD)

        ENABLE_KINECT = false
      elseif tags.kinectRGB then

        print(util.color('KINECT enabled!','green'))
        webots.wb_camera_enable(tags.kinectRGB, kinect_timeStep)
        webots.wb_range_finder_enable(tags.kinectD,kinect_timeStep)
				NEXT_KINECT = get_time() + kinect_timeStep / 1000
        ENABLE_KINECT = true
      end
    end,
    c = function(override)
      if override~=nil then en=override else en=ENABLE_CAMERA==false end
      if en==false then
        print(util.color('CAMERA disabled!','yellow'))
        webots.wb_camera_disable(tags.front_camera)
				-- webots.wb_camera_disable(tags.back_camera)
        ENABLE_CAMERA = false
      else
        print(util.color('CAMERA enabled!','green'))
        webots.wb_camera_enable(tags.front_camera,camera_timeStep)
				-- webots.wb_camera_enable(tags.back_camera,camera_timeStep)
				NEXT_CAMERA = get_time() + camera_timeStep / 1000
        ENABLE_CAMERA = true
      end
    end,
		p = function(override)
			if override~=nil then en=override else en=ENABLE_POSE==false end
      if tags.gps>0 then
        if en==false then
          print(util.color('POSE disabled!','yellow'))
          webots.wb_gps_disable(tags.gps)
  	  		webots.wb_compass_disable(tags.compass)
  				webots.wb_inertial_unit_disable(tags.inertialunit)
          ENABLE_POSE = false
        else
          print(util.color('POSE enabled!','green'))
          webots.wb_gps_enable(tags.gps, timeStep)
  	  		webots.wb_compass_enable(tags.compass, timeStep)
  				webots.wb_inertial_unit_enable(tags.inertialunit, timeStep)
          ENABLE_POSE = true
        end
      end
    end,
		i = function(override)
			if override~=nil then en=override else en=ENABLE_IMU==false end
      if tags.accelerometer>0 then
        if en==false then
          print(util.color('IMU disabled!','yellow'))
          webots.wb_accelerometer_disable(tags.accelerometer)
    			webots.wb_gyro_disable(tags.gyro)
          ENABLE_IMU = false
        else
          print(util.color('IMU enabled!','green'))
          webots.wb_accelerometer_enable(tags.accelerometer, timeStep)
    			webots.wb_gyro_enable(tags.gyro, timeStep)
          ENABLE_IMU = true
        end
      end
    end,
  }

function WebotsBody.entry(Body)
  -- Request @ t=0 to always be earlier than position reads
	-- Grab the tags from the joint names
	tags.joints, tags.jointsByName = {}, {}
  tags.jointsensors={} --for webots 8

	for i,v in ipairs(jointNames) do
    local tag=0
    if v~="null" then
      tag = webots.wb_robot_get_device(v)
      tag_s = webots.wb_robot_get_device(v..'Sensor')
    end
		tags.joints[i] = tag
    tags.jointsensors[i]=tag_s
    tags.jointsByName[v] = tag
		if tag > 0 then
      --Do nothing for motor(default position control mode)
      webots.wb_position_sensor_enable(tag_s,timeStep)
		end
	end

	-- Add Sensor Tags
	tags.accelerometer = webots.wb_robot_get_device("Accelerometer")
	tags.gyro = webots.wb_robot_get_device("Gyro")
	tags.gps = webots.wb_robot_get_device("GPS")
	tags.compass = webots.wb_robot_get_device("Compass")
	tags.inertialunit = webots.wb_robot_get_device("InertialUnit")

  if Config.sensors.front_camera then tags.front_camera = webots.wb_robot_get_device("FrontCamera") end
	-- if Config.sensors.back_camera then tags.back_camera = webots.wb_robot_get_device("BackCamera") end
  if Config.sensors.chest_lidar then tags.chest_lidar = webots.wb_robot_get_device("ChestLidar") end
  if Config.sensors.head_lidar then tags.head_lidar = webots.wb_robot_get_device("HeadLidar") end
  if Config.sensors.velodyne1 then tags.velodyne1 = webots.wb_robot_get_device("Velodyne1") end
  if Config.sensors.kinect then
    tags.kinectRGB = webots.wb_robot_get_device("kinect2RGB")
    tags.kinectD = webots.wb_robot_get_device("kinect2D")
    print("kinect:",tags.kinectRGB,tags.kinectD)
  end
	-- Enable or disable the sensors
	key_action.i(ENABLE_IMU)
	key_action.p(ENABLE_POSE)
	if ENABLE_CAMERA then key_action.c(ENABLE_CAMERA) end
	if ENABLE_HEAD_LIDAR then key_action.h(ENABLE_HEAD_LIDAR) end
	if ENABLE_KINECT then key_action.k(ENABLE_KINECT) end


	Body.set_torque_enable(1)-- Ensure torqued on
	webots.wb_robot_step(timeStep)-- Take a step to get some values
  Body.set_position_p(PID_P)  -- PID setting

	local rad, val
	local positions = vector.zeros(nJoint)

  for idx, jtag in ipairs(tags.joints) do
    if jtag>0 then
      if webots.wb_motor_set_control_pid then -- Update the PID if necessary
        webots.wb_motor_set_control_pid(jtag, PID_P[idx], 0, 0)
      end
    end
  end

  local read_devices = tags.jointsensors
    for idx, jtag in ipairs(read_devices) do
    if jtag>0 then
   		val = get_pos(jtag)
      rad = servo.direction[idx] * val - servo.rad_offset[idx]
			rad = rad==rad and rad or 0
			positions[idx] = rad
    end
  end

	dcm.set_sensor_position(positions)
	dcm.set_actuator_command_position(positions)
	Body.tags = tags

	cw = Config.sensors.head_camera and require(Config.sensors.head_camera)

	vw = Config.sensors.vision and require(Config.sensors.vision)
  -- kw = Config.sensors.kinect and require(Config.sensors.kinect)
	--
	fw = Config.sensors.feedback and require(Config.sensors.feedback)
  ww = Config.sensors.world and require(Config.sensors.world)
	kb = Config.testfile and require(Config.testfile)
	--
	obsw = Config.sensors.obstacle and require(Config.sensors.obstacle)
	s3w = Config.sensors.slam3d and require(Config.sensors.slam3d)



	WebotsBody.USING_KB = type(kb)=='table' and type(kb.update)=='function'

	if ww then ww.entry() end
  if fw then fw.entry() end
  if rw then rw.entry() end

	if obsw then obsw.entry() end
	if s3w then s3w.entry() end
	if vw and vw.entry then vw.entry() end
  if kw and kw.entry then kw.entry() end
end


--local depth_array = carray.float(depth.data, n_pixels)
local depth_fl = ffi.new('float[?]', 1)
local n_depth_fl = ffi.sizeof(depth_fl)
local fl_sz = ffi.sizeof('float')

function WebotsBody.update(Body)
		local get_time = webots.wb_robot_get_time
    local t = get_time()
		local cmds = Body.get_command_position() -- Set actuator commands from shared memory
		local poss = Body.get_position()
    local cmdt = Body.get_command_torque()
		local cmdv = Body.get_command_velocity()
		for idx, jtag in ipairs(tags.joints) do
			local cmd, pos,vel = cmds[idx], poss[idx], cmdv[idx]
			local en = Body.get_torque_enable()[idx]
			if en>0 and jtag>0 then -- Only update the joint if the motor is torqued on
        -- Update the PID
			--[[
          local new_P, old_P = Body.get_position_p()[idx], PID_P[idx]
          if new_P ~= old_P then
            PID_P[idx] = new_P
            webots.wb_motor_set_control_pid(jtag, new_P, 0, 0)
          end
			--]]
        local rad = servo.direction[idx] * (cmd + servo.rad_offset[idx])
        if en==1 then --position control
					set_pos(jtag, rad)
        elseif en==2 then --torque control
					--for whatever reason, torque directions are inverted
					--webots.wb_motor_set_torque(jtag,servo.direction[idx]*cmdt[idx])
					webots.wb_motor_set_velocity(jtag,math.abs(vel))
          webots.wb_motor_set_torque(jtag,-servo.direction[idx]*cmdt[idx])
				elseif en==3 then --velocity control
					if vel>0 then	set_pos(jtag,1E6)
					else set_pos(jtag,-1E6) end
					webots.wb_motor_set_velocity(jtag,math.abs(vel))
        end
      end
		end --for

		-- Step the simulation, and shutdown if the update fails
		if webots.wb_robot_step(Body.timeStep) < 0 then os.exit() end
		t = get_time()

    if ENABLE_IMU then
      -- Accelerometer data (verified)
      local accel = webots.wb_accelerometer_get_values(tags.accelerometer)
      dcm.sensorPtr.accelerometer[0] = (accel[1]-512)/128 * 9.801
      dcm.sensorPtr.accelerometer[1] = (accel[3]-512)/128 * 9.801
      dcm.sensorPtr.accelerometer[2] = (accel[2]-512)/128 * 9.801 --positive z axis

      -- Gyro data (verified)
      local gyro = webots.wb_gyro_get_values(tags.gyro)

      dcm.sensorPtr.gyro[0] = (gyro[3]-512)/512*39.24
      dcm.sensorPtr.gyro[1] = (gyro[2]-512)/512*39.24
      dcm.sensorPtr.gyro[2] = -(gyro[1]-512)/512*39.24

    end
    -- GPS and compass data
    -- Webots x is our y, Webots y is our z, Webots z is our x,
    -- Our x is Webots z, Our y is Webots x, Our z is Webots y
    if ENABLE_POSE then
      local gps     = webots.wb_gps_get_values(tags.gps)
      local compass = webots.wb_compass_get_values(tags.compass)
      local angle   = math.atan2( compass[2], -compass[1] ) -- Fixed for n1bot wbt
      local pose    = vector.pose{gps[3], gps[1], angle}

			if gps_pose0 then --relative pose from the starting position
				local rel_pose = util.pose_relative(pose,gps_pose0)
        local zeropos=hcm.get_base_zeropos()
        local ppose=util.pose_global(rel_pose,zeropos)
        wcm.set_robot_pose_gps(ppose )
        -- wcm.set_robot_pose( ppose ) --HACK FOR TESTING!
			else
				gps_pose0 = pose
				wcm.set_robot_pose_gps({0,0,0})
			end

      local rpy = webots.wb_inertial_unit_get_roll_pitch_yaw(tags.inertialunit)
			local gps_pose=wcm.get_robot_pose_gps()
      dcm.sensorPtr.rpy[0], dcm.sensorPtr.rpy[1], dcm.sensorPtr.rpy[2] =rpy[1], rpy[2], gps_pose[3]

      local pose= wcm.get_robot_pose_gps()
      local pose_ffi=ffi.new("float[3]")
      pose_ffi[0],pose_ffi[1],pose_ffi[2]=pose[1],pose[2],pose[3]
			pose_ch:send(ffi.string(pose_ffi,3*ffi.sizeof("float")))
    end

		-- Update the sensor readings of the joint positions
		local rad, val
		local positions = dcm.get_sensor_position()
    local read_devices = tags.jointsensors  --Webots 8 handling (separate joint encoder)
    for idx, jtag in ipairs(read_devices) do
    if jtag>0 then
			val = get_pos(jtag)
      rad = servo.direction[idx] * val - servo.rad_offset[idx]
			rad = rad==rad and rad or 0
			positions[idx] = rad
    end
    end
		dcm.set_sensor_position(positions)

		-- Joint state publish to ros



		local js_str=sr.serialize(Config.jointNames)
		local jangle_str=sr.serialize(positions)

		local datasizes_ffi=ffi.new("int[2]")
		datasizes_ffi[0]=#js_str
		datasizes_ffi[1]=#jangle_str

		jointstate_ch:send(
			ffi.string(datasizes_ffi, 2*ffi.sizeof("int"))..
			js_str..jangle_str
		)

    -- Grab a camera frame
    if ENABLE_CAMERA and t >= NEXT_CAMERA then
      local w = webots.wb_camera_get_width(tags.front_camera)
      local h = webots.wb_camera_get_height(tags.front_camera)
      local fov = webots.wb_camera_get_fov(tags.front_camera)
      local rgb = {data = webots.to_rgb(tags.front_camera),width = w,height = h,t = t,}
			local buf_rgb=ffi.new("uint8_t[?]",w*h*3)
      ffi.copy(buf_rgb,rgb.data,w*h*3)
			local whfov_ffi=ffi.new("float[3]")
			whfov_ffi[0],whfov_ffi[1],whfov_ffi[2]=w,h,fov
			local whfov_buf=ffi.string(whfov_ffi,3*ffi.sizeof("float"))
			local rgb_buf=ffi.string(buf_rgb,w*h*3)
			local msg_rgb={whfov_buf..rgb_buf}
			rgb_ch:send(msg_rgb)
      seq=seq+1
			NEXT_CAMERA = t + camera_timeStep / 1000
    end
    -- Grab a kinect frame
    if ENABLE_KINECT and t >= NEXT_KINECT then
			local w = webots.wb_camera_get_width(tags.kinectRGB)
      local h = webots.wb_camera_get_height(tags.kinectRGB)
      local fov = webots.wb_camera_get_fov(tags.kinectRGB)
      local rgb = {data = webots.to_rgb(tags.kinectRGB),width = w,height = h,t = t,}
			local buf_rgb=ffi.new("uint8_t[?]",w*h*3)
      ffi.copy(buf_rgb,rgb.data,w*h*3)
			local whfov_ffi=ffi.new("float[3]")
			whfov_ffi[0],whfov_ffi[1],whfov_ffi[2]=w,h,fov
			local whfov_buf=ffi.string(whfov_ffi,3*ffi.sizeof("float"))
			local rgb_buf=ffi.string(buf_rgb,w*h*3)
			local msg_rgb={whfov_buf..rgb_buf}
			rgb_ch:send(msg_rgb)
      seq=seq+1

      local d_w = webots.wb_range_finder_get_width(tags.kinectD)
      local d_h = webots.wb_range_finder_get_height(tags.kinectD)
			local d_fov = webots.wb_range_finder_get_fov(tags.kinectD)
			local d_data = webots.get_rangefinder_ranges(tags.kinectD)

			local fl_sz = ffi.sizeof('float')
      local d_ffi=ffi.new("uint8_t[?]",d_w*d_h*fl_sz) --lets try 2 byte per pixels
			ffi.copy(d_ffi,d_data,d_w*d_h*fl_sz)

			local d_whfov_ffi=ffi.new("float[3]")
			d_whfov_ffi[0],d_whfov_ffi[1],d_whfov_ffi[2]=d_w,d_h,d_fov
			local d_whfov_buf=ffi.string(d_whfov_ffi,3*ffi.sizeof("float"))

			local d_buf=ffi.string(d_ffi,d_w*d_h*fl_sz)
			local msg_depth={d_whfov_buf..d_buf}
			depth_ch:send(msg_depth)
			-- local buf1=ffi.new("uint8_t[?]",w*h*3)
      -- ffi.copy(buf1,rgb.data,w*h*3)
      -- --print(buf1[0], buf1[1], buf1[2]) --this works fine
      --


      --
			NEXT_KINECT = t + kinect_timeStep / 1000
    end


    -- Grab a lidar scan
    if ENABLE_HEAD_LIDAR and t >= NEXT_HEAD_LIDAR then
      local n = webots.wb_lidar_get_horizontal_resolution(tags.head_lidar)
      local fov = webots.wb_lidar_get_fov(tags.head_lidar)
      local ranges = webots.get_lidar_ranges(tags.head_lidar)
      local fl_sz = ffi.sizeof('float')
			local datastr=ffi.string(ranges,n*fl_sz)
			lidar_ch:send(datastr)
      NEXT_HEAD_LIDAR = t + lidar_timeStep / 1000
    end

		-- Receive webot messaging
		while webots.wb_receiver_get_queue_length(tags.receiver) > 0 do

	  end

    local key_code = webots.wb_keyboard_get_key() 		-- Grab keyboard input, for modifying items
		local key_count=0
		while (key_code>0 and key_count<5) do
			kb.update(key_code)
			key_count=key_count+1
			key_code = webots.wb_keyboard_get_key() 		-- Grab keyboard input, for modifying items
		end

		if ww then ww.update() end
  	if fw then fw.update() end
  	if rw then rw.update() end
end

function WebotsBody.exit() if ww then ww.exit() end end

return WebotsBody
