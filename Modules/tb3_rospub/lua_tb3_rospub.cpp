
#include "rospub.h"

static void lua_pushvector(lua_State *L, float* v, int n) {
	lua_createtable(L, n, 0);
	for (int i = 0; i < n; i++) {
		lua_pushnumber(L, v[i]);
		lua_rawseti(L, -2, i+1);
	}
}

static std::vector<double> lua_checkvector(lua_State *L, int narg) {
	if ( !lua_istable(L, narg) )	{
    printf("ERROR!!!!\n");
    luaL_argerror(L, narg, "vector");
  }
	int n = lua_objlen(L, narg);
	std::vector<double> v(n);
	for (int i = 0; i < n; i++) {
		lua_rawgeti(L, narg, i+1);
		v[i] = lua_tonumber(L, -1);
		lua_pop(L, 1);
	}
	return v;
}

static std::vector<std::string> lua_checkstringvector(lua_State *L, int narg) {
	if ( !lua_istable(L, narg) )	{
    printf("ERROR!!!!\n");
    luaL_argerror(L, narg, "vector");
  }
	int n = lua_objlen(L, narg);
	std::vector<std::string> v(n);
	for (int i = 0; i < n; i++) {
		lua_rawgeti(L, narg, i+1);
		v[i] = lua_tostring(L, -1);
		lua_pop(L, 1);
	}
	return v;
}

static int lua_init(lua_State *L)
{
  const char *ros_node_name = lua_tostring(L, 1);
  ros_init(ros_node_name);
  return 0;
}

static int lua_baseteleop(lua_State *L){ // frame_id, child_frame_id, pose x, y, z, quaternion x, y, z, w, twist linear x, y, z, angular x, y, z
  baseteleop(lua_tonumber(L, 1),lua_tonumber(L, 2),lua_tonumber(L, 3));
  return 0;
}

static int lua_cmdvel(lua_State *L){ // frame_id, child_frame_id, pose x, y, z, quaternion x, y, z, w, twist linear x, y, z, angular x, y, z
  cmdvel(lua_tonumber(L, 1),lua_tonumber(L, 2),lua_tonumber(L, 3));
  return 0;
}

static int lua_laserscan(lua_State *L) // frame_id, child_frame_id, pose x, y, z, quaternion x, y, z, w, twist linear x, y, z, angular x, y, z
{
  int seq=lua_tonumber(L, 1);
  float angle_min=lua_tonumber(L, 2);
  float angle_max=lua_tonumber(L, 3);
  int n=lua_tonumber(L, 4);
  float angle_increment=(angle_max-angle_min)/((float) n-1);
  float* ranges=(float*) luaL_checkstring(L, 5);
  const char *linkname = lua_tostring(L, 6);
  laserscan(seq,angle_min,angle_max,n,angle_increment,ranges,linkname);
  return 0;
}

static int lua_webotslaserscan(lua_State *L) // frame_id, child_frame_id, pose x, y, z, quaternion x, y, z, w, twist linear x, y, z, angular x, y, z
{
  int seq=lua_tonumber(L, 1);
  float angle_min=lua_tonumber(L, 2);
  float angle_max=lua_tonumber(L, 3);
  int n=lua_tonumber(L, 4);
  float angle_increment=(angle_max-angle_min)/((float) n-1);
  float* ranges=(float*) luaL_checkstring(L, 5);
  const char *linkname = lua_tostring(L, 6);
  webotslaserscan(seq,angle_min,angle_max,n,angle_increment,ranges,linkname);
  return 0;
}

static int lua_webotslaserscancrop(lua_State *L) // frame_id, child_frame_id, pose x, y, z, quaternion x, y, z, w, twist linear x, y, z, angular x, y, z
{
  int seq=lua_tonumber(L, 1);
  float angle_min=lua_tonumber(L, 2);
  float angle_max=lua_tonumber(L, 3);
	int n=lua_tonumber(L, 4);
	float angle_increment=(angle_max-angle_min)/((float) n-1);
  float* ranges=(float*) luaL_checkstring(L, 5);
  const char *linkname = lua_tostring(L, 6);
	int crop_ray_num=lua_tonumber(L, 7);
  webotslaserscancrop(seq,angle_min,angle_max,n,angle_increment,ranges,linkname,crop_ray_num);
  return 0;
}




static int lua_tf(lua_State *L){
  std::vector<double>xyz=lua_checkvector(L,1);
  std::vector<double>rpy=lua_checkvector(L,2);
  const char *mother_link = lua_tostring(L, 3);
  const char *child_link = lua_tostring(L, 4);
	send_tf(xyz,rpy,mother_link, child_link);
  return 0;
}

static int lua_odom(lua_State *L){
  std::vector<double>pose=lua_checkvector(L,1);
	send_odom(pose);
  return 0;
}


static int lua_camerainfo(lua_State *L){
  camerainfo(lua_tonumber(L, 1),lua_tonumber(L, 2),lua_tonumber(L, 3),lua_tonumber(L, 4));
  return 0;
}

static int lua_rgbimage(lua_State *L){
  rgbimage(lua_tonumber(L, 1),lua_tonumber(L, 2),lua_tonumber(L, 3), lua_tostring(L, 4));
  return 0;
}

static int lua_depthimage(lua_State *L){
  depthimage(lua_tonumber(L, 1),lua_tonumber(L, 2),lua_tonumber(L, 3), lua_tostring(L, 4));
  return 0;
}

static int lua_joint(lua_State *L){
	std::vector<double>armangle=lua_checkvector(L,1);
	float gripforce=lua_tonumber(L, 2);
  send_joint(armangle,gripforce);
  return 0;
}

static int lua_jointstate(lua_State *L){
	int seq=lua_tonumber(L, 1);
	std::vector<std::string> jointnames=lua_checkstringvector(L,2);
  std::vector<double>jangles=lua_checkvector(L,3);
	send_jointstate(jointnames,jangles);
  return 0;
}

static int lua_jointtraj(lua_State *L){
	int seq=lua_tonumber(L, 1);
	std::vector<std::string> jointnames=lua_checkstringvector(L,2);
  std::vector<double>jangles=lua_checkvector(L,3);
	std::vector<double>jvel=lua_checkvector(L,4);
	send_jointtraj(jointnames,jangles,jvel);
  return 0;
}

static int lua_motorvel(lua_State *L){
  std::vector<double>motorvel=lua_checkvector(L,1);
	send_motorvel(motorvel);
  return 0;
}

static int lua_path(lua_State *L){
  std::vector<double>posx=lua_checkvector(L,1);
  std::vector<double>posy=lua_checkvector(L,2);
  std::vector<double>posa=lua_checkvector(L,3);
  send_path(posx,posy,posa);
  return 0;
}

static int lua_occgrid(lua_State *L){
  send_occgrid(lua_tonumber(L, 1),lua_tonumber(L, 2),lua_tonumber(L, 3),
    lua_tonumber(L, 4),lua_tonumber(L, 5),lua_tonumber(L, 6),lua_tostring(L, 7));
  return 0;
}

static int lua_marker(lua_State *L)
{
  int marker_num=lua_tonumber(L, 1);
  std::vector<double> types=lua_checkvector(L,2);
	std::vector<double> posx=lua_checkvector(L,3);
	std::vector<double> posy=lua_checkvector(L,4);
	std::vector<double> posz=lua_checkvector(L,5);
  std::vector<double> yaw=lua_checkvector(L,6);
	std::vector<std::string> names=lua_checkstringvector(L,7);
  std::vector<double> scales=lua_checkvector(L,8);
  std::vector<double> colors=lua_checkvector(L,9);
  marker(marker_num, types, posx, posy, posz, yaw,names, scales, colors);
  return 0;
}

static int lua_motorpower(lua_State *L)
{
  int power=lua_tonumber(L, 1);
  motor_power(power);
  return 0;
}

static int lua_job(lua_State *L)
{
  int power=lua_tonumber(L, 1);
  job(power);
  return 0;
}
static int lua_mapcmd(lua_State *L)
{
  int power=lua_tonumber(L, 1);
  mapcmd(power);
  return 0;
}

static int lua_posereset(lua_State *L) // frame_id, child_frame_id, pose x, y, z, quaternion x, y, z, w, twist linear x, y, z, angular x, y, z
{
	std::vector<double> pose=lua_checkvector(L,1);
  posereset(pose);
  return 0;
}








static const struct luaL_Reg rospub_lib[] = {
  {"init", lua_init},
  {"tf", lua_tf},
  {"baseteleop", lua_baseteleop},
	// {"basegoal", lua_basegoal},
	{"cmdvel", lua_cmdvel},
	{"posereset", lua_posereset},
  {"laserscan", lua_laserscan},
	{"webotslaserscan", lua_webotslaserscan},
	{"webotslaserscancrop", lua_webotslaserscancrop},
	{"rgbimage",lua_rgbimage},
	{"depthimage",lua_depthimage},
	{"camerainfo",lua_camerainfo},

	{"motorpower",lua_motorpower},
	{"motorvel",lua_motorvel},
	{"joint", lua_joint},
	{"joint_cmd", lua_jointtraj},
	{"jointstate",lua_jointstate},


  {"odom",lua_odom},
	{"path",lua_path},
	{"occgrid",lua_occgrid},
  {"marker",lua_marker},

	{"job",lua_job},
	{"mapcmd",lua_mapcmd},
  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_tb3_rospub(lua_State *L)
{
  #if LUA_VERSION_NUM == 502
  	luaL_newlib(L, rospub_lib);
  #else
  	luaL_register(L, "tb3_rospub", rospub_lib);
  #endif

  return 1;
}
