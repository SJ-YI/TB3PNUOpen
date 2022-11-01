
assert(Config, 'Need a pre-existing Config table!')

local vector = require'vector'

if ROBOT_TYPE=="1" then --Turtlebot with mecanum wheel
  Config.nJoint = 4
  Config.jointNames={"wheel1","wheel2","wheel3","wheel4"}
  local indexWheel,nJointWheel=1,4
  Config.parts = {Wheel = vector.count(indexWheel,nJointWheel),}
  Config.servo={
    ids={1,2,3,4},
    direction=vector.new({1,-1,1,-1}),
    rad_offset=vector.new({0,0,0,0})*DEG_TO_RAD
  }
  Config.wheels={
    r=0.05,
    wid=0.33,
    rps_limit = 6.2825
  }
elseif ROBOT_TYPE=="2" then --Turtlebot with mecanum wheel and arm
  Config.nJoint = 10
  Config.jointNames={
    "wheel1","wheel2","wheel3","wheel4",  "Arm1","Arm2","Arm3","Arm4",  "GripperL","GripperR"
  }
  local indexWheel,nJointWheel=1,4
  local indexArm,nJointArm=5,4
  local indexGripper,nJointGripper=9,2
  Config.parts = {
    Wheel = vector.count(indexWheel,nJointWheel),
    Arm = vector.count(indexArm,nJointArm),
    Gripper = vector.count(indexGripper,nJointGripper)
  }
  Config.servo={
    ids={1,2,3,4,5,6,7,8,9,10},
    direction=vector.new({1,1,1,1,   1,1,1,1,  1,1}),
    rad_offset=vector.new({0,0,0,0, 0,0,0,0,  0,0})*DEG_TO_RAD
  }
  Config.wheels={
    r=0.05,
    wid=0.33,
    rps_limit = 8.06318 --77RPM for XM430-210-R
  }
  Config.armconfig={
    baseX=-0.07,
    baseZ=0.15,
    shoulderZ=0.095,
    lowerArmX=0.03,
    lowerArmZ=0.17,
    upperArmX=0.17,
    wristX=0.10
  }

elseif not ROBOT_TYPE or ROBOT_TYPE=="3" then --PADUK
  Config.nJoint = 12
  local jointNames={
    "FLRoll","FLPitch","FLElbow",    "FRRoll","FRPitch","FRElbow",   "RLRoll","RLPitch","RLElbow",  "RRRoll","RRPitch","RRElbow",
  }
  Config.jointNames = jointNames
  local indexLeg=1
  local nJointLeg=12
  Config.parts = {Leg = vector.count(indexLeg,nJointLeg),}
  Config.servo={
    direction=vector.new({-1,1,-1, -1,-1,-1, 1,1,1, 1,-1,-1}),
    rad_offset=vector.new({0,0,0, 0,0,0, 0,0,0, 0,0,0 })*DEG_TO_RAD
  }
  if IS_WEBOTS then Config.servo.direction=vector.new({1,1,1, 1,1,1,   1,1,1,   1,1,1}) end
else --Turtlebot autorace bot
  Config.nJoint = 2
  Config.jointNames={"wheel1","wheel2"}
  local indexWheel,nJointWheel=1,2
  Config.parts = {Wheel = vector.count(indexWheel,nJointWheel),}
  Config.nJoint = 2
  Config.servo={
    ids={1,2},
    direction=vector.new({-1,1}),
    rad_offset=vector.new({0,0})*DEG_TO_RAD
  }
  Config.wheels={
    r=0.033,
    wid=0.18,
    rps_limit = 6.2825
  }
end
return Config
