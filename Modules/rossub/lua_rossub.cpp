#include "rossub.h"
#include <tf/transform_listener.h>
#include <cstdio>
template <typename Type>
class _Subscriber
{
public:
  _Subscriber(std::shared_ptr<ros::NodeHandle> rosNode, const char *topic_name)
  {
    _rosNode = rosNode;
    so = ros::SubscribeOptions::create<Type>(
        topic_name,
        100,
        boost::bind(&_Subscriber<Type>::OnRosMsg, this, _1),
        ros::VoidPtr(), &this->_rosQueue);
    _rosSub = _rosNode->subscribe(so);
  }
  void start(){
      this->_rosQueueThread = std::thread(std::bind(&_Subscriber<Type>::QueueThread, this));
  }
  bool checkMsg(){return _new;}
  Type getMsg()  {
    mtx_lock.lock();
    Type returnMsg = _newMsg;
    _new = false;
    mtx_lock.unlock();
    return returnMsg;
  }
  void OnRosMsg(const typename Type::ConstPtr &msg)
  {
    mtx_lock.lock();
    _new = true;
    _newMsg = *msg;
    mtx_lock.unlock();
  }
  void QueueThread()
  {
    static const double timeout = 0.01;
    while(_rosNode->ok()){
      this->_rosQueue.callAvailable(ros::WallDuration(timeout));
    }
  }
private:
  std::shared_ptr<ros::NodeHandle> _rosNode;
  ros::SubscribeOptions so;
  ros::Subscriber _rosSub;
  ros::CallbackQueue _rosQueue;
  std::thread _rosQueueThread;
  Type _newMsg;
  bool _new = false;
  std::mutex mtx_lock;
};
std::vector<std::shared_ptr<void>> subList;
std::shared_ptr<ros::NodeHandle> rosNode;
std::shared_ptr<tf::TransformListener> listener;

static void lua_pushvector(lua_State *L, std::vector<double> v, int n) {
	lua_createtable(L, n, 0);
	for (int i = 0; i < n; i++) {
		lua_pushnumber(L, v[i]);
		lua_rawseti(L, -2, i+1);
	}
}
static void lua_pusharray(lua_State *L, float* v, int n) {
	lua_createtable(L, n, 0);
	for (int i = 0; i < n; i++) {
		lua_pushnumber(L, v[i]);
		lua_rawseti(L, -2, i+1);
	}
}

static void lua_pushstringarray(lua_State *L, std::vector<std::string>  str, int n) {
	lua_createtable(L, n, 0);
	for (int i = 0; i < n; i++) {
		lua_pushstring(L, str[i].c_str());
		lua_rawseti(L, -2, i+1);
	}
}


static int lua_init(lua_State *L){
  const char *ros_node_name = lua_tostring(L, 1);
  if(!ros::isInitialized())  {
    int argc = 0;
    char **argv = NULL;
    ros::init(argc, argv, ros_node_name, ros::init_options::NoSigintHandler);

  }
  listener.reset(new tf::TransformListener() );
  rosNode.reset(new ros::NodeHandle(ros_node_name));
  return 0;
}

static int lua_subscribeTwist(lua_State *L){
  const char *topic_name = lua_tostring(L, 1);
  std::shared_ptr<_Subscriber<geometry_msgs::Twist>> sub = std::shared_ptr<_Subscriber<geometry_msgs::Twist>>(new _Subscriber<geometry_msgs::Twist>(rosNode, topic_name));
  sub->start();subList.push_back(sub);
  lua_pushnumber(L, subList.size() - 1);
  return 1;
}

static int lua_checkTwist(lua_State *L){
  int idx = lua_tonumber(L, 1);
  std::shared_ptr<_Subscriber<geometry_msgs::Twist>> sub = std::static_pointer_cast<_Subscriber<geometry_msgs::Twist>>(subList[idx]);
  if (sub->checkMsg()){
    geometry_msgs::Twist ps = sub->getMsg();
    lua_createtable(L,6,0);
    lua_pushnumber(L,(float)ps.linear.x );
    lua_rawseti(L,-2,1);
    lua_pushnumber(L,(float)ps.linear.y );
    lua_rawseti(L,-2,2);
    lua_pushnumber(L,(float)ps.linear.z );
    lua_rawseti(L,-2,3);
    lua_pushnumber(L,(float)ps.angular.x );
    lua_rawseti(L,-2,4);
    lua_pushnumber(L,(float)ps.angular.y );
    lua_rawseti(L,-2,5);
    lua_pushnumber(L,(float)ps.angular.z );
    lua_rawseti(L,-2,6);
    return 1;
  }else return 0;
}

static int lua_subscribeJointTrajectory(lua_State *L){
  const char *topic_name = lua_tostring(L, 1);
  std::shared_ptr<_Subscriber<trajectory_msgs::JointTrajectory>> sub = std::shared_ptr<_Subscriber<trajectory_msgs::JointTrajectory>>(new _Subscriber<trajectory_msgs::JointTrajectory>(rosNode, topic_name));
  sub->start();subList.push_back(sub);
  lua_pushnumber(L, subList.size() - 1);
  return 1;
}

static int lua_checkJointTrajectory(lua_State *L){
  int idx = lua_tonumber(L, 1);
  std::shared_ptr<_Subscriber<trajectory_msgs::JointTrajectory>> sub = std::static_pointer_cast<_Subscriber<trajectory_msgs::JointTrajectory>>(subList[idx]);
  if (sub->checkMsg()){
    trajectory_msgs::JointTrajectory ps = sub->getMsg();
    int n=ps.joint_names.size();
    std::vector<std::string> jointnames;
    std::vector<float> jangles;
    std::vector<float> jvels;
    for(int i=0;i<n;i++){
      jointnames.push_back(ps.joint_names[i]);
      jangles.push_back(ps.points[0].positions[i]);
      jvels.push_back(ps.points[0].velocities[i]);
    }
    lua_pushstringarray(L, jointnames,n);
    lua_pusharray(L, &jangles[0],n);
    lua_pusharray(L, &jvels[0],n);
    return 3;
  }else return 0;
}


static int lua_subscribeFloat32MultiArray(lua_State *L){
  const char *topic_name = lua_tostring(L, 1);
  std::shared_ptr<_Subscriber<std_msgs::Float32MultiArray>> sub = std::shared_ptr<_Subscriber<std_msgs::Float32MultiArray>>(new _Subscriber<std_msgs::Float32MultiArray>(rosNode, topic_name));
  sub->start();subList.push_back(sub);
  lua_pushnumber(L, subList.size() - 1);
  return 1;
}

static int lua_checkFloat32MultiArray(lua_State *L){
  int idx = lua_tonumber(L, 1);
  float buf[32];
  std::shared_ptr<_Subscriber<std_msgs::Float32MultiArray>> sub = std::static_pointer_cast<_Subscriber<std_msgs::Float32MultiArray>>(subList[idx]);
  if (sub->checkMsg()){
    std_msgs::Float32MultiArray ps = sub->getMsg();
    int size=ps.layout.dim[0].size;
    std::vector<double> data;
    for(int i=0;i<size;i++) data.push_back(ps.data[i]);
    lua_pushvector(L,data,size);
    return 1;
  }else return 0;
}

static int lua_checkTF(lua_State *L){
  const char *mother_frame = lua_tostring(L, 1);
  const char *child_frame = lua_tostring(L, 2);
  tf::StampedTransform transform;
  try{
    listener->lookupTransform(mother_frame,child_frame, ros::Time(0), transform);
  } catch (tf::TransformException ex){
    // printf("%s",ex.what());
    return 0;
  }
  float x=transform.getOrigin().x();
  float y=transform.getOrigin().y();
  float z=transform.getOrigin().z();
  tf::Quaternion q=transform.getRotation();
  tf::Matrix3x3 m(q);
  double roll,pitch,yaw;
  m.getRPY(roll,pitch,yaw);

  lua_createtable(L, 6, 0);
	lua_pushnumber(L, x);
	lua_rawseti(L, -2, 1);
  lua_pushnumber(L, y);
  lua_rawseti(L, -2, 2);
  lua_pushnumber(L, z);
  lua_rawseti(L, -2, 3);
  lua_pushnumber(L, roll);
  lua_rawseti(L, -2, 4);
  lua_pushnumber(L, pitch);
  lua_rawseti(L, -2, 5);
  lua_pushnumber(L, yaw);
  lua_rawseti(L, -2, 6);
  return 1;
}

static int lua_subscribePoseStamped(lua_State *L){
  const char *topic_name = lua_tostring(L, 1);
  std::shared_ptr<_Subscriber<geometry_msgs::PoseStamped>> sub = std::shared_ptr<_Subscriber<geometry_msgs::PoseStamped>>(new _Subscriber<geometry_msgs::PoseStamped>(rosNode, topic_name));
  sub->start();subList.push_back(sub);
  lua_pushnumber(L, subList.size() - 1);
  return 1;
}

static int lua_checkPoseStamped(lua_State *L){
  int idx = lua_tonumber(L, 1);
  int update_tr=luaL_optnumber(L,2,0);
	float pose[3];
  std::shared_ptr<_Subscriber<geometry_msgs::PoseStamped>> sub = std::static_pointer_cast<_Subscriber<geometry_msgs::PoseStamped>>(subList[idx]);
  if (sub->checkMsg()){
    float orientation[4];
    geometry_msgs::PoseStamped ps=sub->getMsg();
    pose[0] = (float)ps.pose.position.x;
    pose[1] = (float)ps.pose.position.y;
    orientation[0] = (float)ps.pose.orientation.x;
    orientation[1] = (float)ps.pose.orientation.y;
    orientation[2] = (float)ps.pose.orientation.z;
    orientation[3] = (float)ps.pose.orientation.w;
    float angle = atan2(orientation[2],orientation[3])*2.0;
    pose[2]=angle;//change to 2D pose (x,y,theta)
		lua_pusharray(L, pose,3);
		return 1;
  }else return 0;
}


static int lua_subscribeOccupancyGrid(lua_State *L){
  const char *topic_name = lua_tostring(L, 1);
  std::shared_ptr<_Subscriber<nav_msgs::OccupancyGrid>> sub = std::shared_ptr<_Subscriber<nav_msgs::OccupancyGrid>>(new _Subscriber<nav_msgs::OccupancyGrid>(rosNode, topic_name));
  sub->start();subList.push_back(sub);
  lua_pushnumber(L, subList.size() - 1);
  return 1;
}
static int lua_checkOccupancyGrid(lua_State *L){
  int idx = lua_tonumber(L, 1);
  std::shared_ptr<_Subscriber<nav_msgs::OccupancyGrid>> sub = std::static_pointer_cast<_Subscriber<nav_msgs::OccupancyGrid>>(subList[idx]);
  if (sub->checkMsg()){
    nav_msgs::OccupancyGrid ps = sub->getMsg();
    lua_pushnumber(L,ps.info.resolution);
    lua_pushnumber(L,ps.info.width);
    lua_pushnumber(L,ps.info.height);
    lua_pushnumber(L,ps.info.origin.position.x);
    lua_pushnumber(L,ps.info.origin.position.y);
    lua_pushnumber(L,ps.info.origin.position.z);
    lua_pushlstring(L, (char*) &ps.data[0], ps.data.size());
    return 7;
  }
  return 0;
}

static int lua_subscribeOdometry(lua_State *L){
  const char *topic_name = lua_tostring(L, 1);
  std::shared_ptr<_Subscriber<nav_msgs::Odometry>> sub =
    std::shared_ptr<_Subscriber<nav_msgs::Odometry>>(new _Subscriber<nav_msgs::Odometry>(rosNode, topic_name));
  sub->start();subList.push_back(sub);
  lua_pushnumber(L, subList.size() - 1);
  return 1;
}
static int lua_checkOdometry(lua_State *L){
  int idx = lua_tonumber(L, 1);
  std::shared_ptr<_Subscriber<nav_msgs::Odometry>> sub = std::static_pointer_cast<_Subscriber<nav_msgs::Odometry>>(subList[idx]);
  if (sub->checkMsg()){
    nav_msgs::Odometry ps = sub->getMsg();
    float yaw=2.0*atan2(ps.pose.pose.orientation.z,ps.pose.pose.orientation.w);
    lua_createtable(L,3,0);
    lua_pushnumber(L,ps.pose.pose.position.x);
    lua_rawseti(L,-2,1);
    lua_pushnumber(L,ps.pose.pose.position.y);
    lua_rawseti(L,-2,2);
    lua_pushnumber(L,yaw);
    lua_rawseti(L,-2,3);
    return 1;
  }
  return 0;
}

static int lua_subscribeInt32(lua_State *L){
  const char *topic_name = lua_tostring(L, 1);
  std::shared_ptr<_Subscriber<std_msgs::Int32>> sub = std::shared_ptr<_Subscriber<std_msgs::Int32>>(new _Subscriber<std_msgs::Int32>(rosNode, topic_name));
  sub->start();subList.push_back(sub);
  lua_pushnumber(L, subList.size() - 1);
  return 1;
}

static int lua_checkInt32(lua_State *L){
  int idx = lua_tonumber(L, 1);
  std::shared_ptr<_Subscriber<std_msgs::Int32>> sub = std::static_pointer_cast<_Subscriber<std_msgs::Int32>>(subList[idx]);
  if (sub->checkMsg()){
    std_msgs::Int32 ps = sub->getMsg();
    lua_pushnumber(L,ps.data);
    return 1;
  }else return 0;
}

static int lua_subscribeBattery(lua_State *L){
  const char *topic_name = lua_tostring(L, 1);
  std::shared_ptr<_Subscriber<sensor_msgs::BatteryState>> sub = std::shared_ptr<_Subscriber<sensor_msgs::BatteryState>>(new _Subscriber<sensor_msgs::BatteryState>(rosNode, topic_name));
  sub->start();subList.push_back(sub);
  lua_pushnumber(L, subList.size() - 1);
  return 1;
}

static int lua_checkBattery(lua_State *L){
  int idx = lua_tonumber(L, 1);
  std::shared_ptr<_Subscriber<sensor_msgs::BatteryState>> sub = std::static_pointer_cast<_Subscriber<sensor_msgs::BatteryState>>(subList[idx]);
  if (sub->checkMsg()){
    sensor_msgs::BatteryState ps = sub->getMsg();
    lua_pushnumber(L, ps.voltage);
    return 1;
  }else return 0;
}

static int lua_subscribeString(lua_State *L){
  const char *topic_name = lua_tostring(L, 1);
  std::shared_ptr<_Subscriber<std_msgs::String>> sub =
    std::shared_ptr<_Subscriber<std_msgs::String>>(new _Subscriber<std_msgs::String>(rosNode, topic_name));
  sub->start();subList.push_back(sub);
  lua_pushnumber(L, subList.size() - 1);
  return 1;
}

static int lua_checkString(lua_State *L){
  int idx = lua_tonumber(L, 1);
  std::shared_ptr<_Subscriber<std_msgs::String>> sub =
    std::static_pointer_cast<_Subscriber<std_msgs::String>>(subList[idx]);
  if (sub->checkMsg()){
    std_msgs::String ps = sub->getMsg();
    lua_pushstring(L,ps.data.c_str());
    return 1;
  }else return 0;
}

static const struct luaL_Reg rossub_lib[] = {
  {"init", lua_init},

  {"checkTF", lua_checkTF},

  {"subscribeTwist", lua_subscribeTwist},
  {"checkTwist", lua_checkTwist},

  {"subscribeJointTrajectory", lua_subscribeJointTrajectory},
  {"checkJointTrajectory", lua_checkJointTrajectory},

  {"subscribeFloat32MultiArray", lua_subscribeFloat32MultiArray},
  {"checkFloat32MultiArray", lua_checkFloat32MultiArray},

  {"subscribeOccupancyGrid", lua_subscribeOccupancyGrid},
  {"checkOccupancyGrid", lua_checkOccupancyGrid},

  {"subscribePoseStamped", lua_subscribePoseStamped},
  {"checkPoseStamped", lua_checkPoseStamped},

  {"subscribeOdometry", lua_subscribeOdometry},
  {"checkOdometry", lua_checkOdometry},

  {"subscribeInt32", lua_subscribeInt32},
  {"checkInt32", lua_checkInt32},

  {"subscribeBattery", lua_subscribeBattery},
  {"checkBattery", lua_checkBattery},

  {"subscribeString", lua_subscribeString},
  {"checkString", lua_checkString},

  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_rossub(lua_State *L)
{
  #if LUA_VERSION_NUM == 502
  	luaL_newlib(L, rossub_lib);
  #else
  	luaL_register(L, "rossub", rossub_lib);
  #endif

  return 1;
}
