#ifndef ROSPUB_H_
#define ROSPUB_H_

#include <lua.hpp>
#include <cstdio>
#include <vector>
#include <algorithm>
#include <sys/time.h>




void ros_init(const char* node_name);
void init_publishers();

void cmdvel(double x, double y, double a);
void baseteleop(double x, double y, double a);

void laserscan(int seq,  float angle_min, float angle_max,int n,float angle_increment,float* ranges, const char* linkname);
void webotslaserscan(int seq,  float angle_min, float angle_max,int n,float angle_increment,float* ranges, const char* linkname);
void webotslaserscancrop(int seq,  float angle_min, float angle_max,int n,float angle_increment,float* ranges, const char* linkname,int ray_num);
void camerainfo(int seq,int width, int height, double fov);
void rgbimage(int seq,int width, int height, const char* data);
void depthimage(int seq,int width, int height, const char* data);
void send_tf(std::vector<double>xyz,std::vector<double>rpy,const char* mother_link, const char* child_link);
void send_odom(std::vector<double>pose);
void send_joint(std::vector<double>armangle, float gripforce);
void send_jointstate(std::vector<std::string> jointnames,std::vector<double>jangles);
void send_jointtraj(std::vector<std::string> jointnames,std::vector<double>jangles,std::vector<double>jointvel);

void send_motorvel(std::vector<double>motorvel);
void send_path(std::vector<double> posx,std::vector<double> posy,std::vector<double> posa);
void send_occgrid(float res, int width, int height, float x0, float y0, float z0, const char* data);

void marker(int num,
  std::vector<double> types,std::vector<double> posx,
  std::vector<double> posy,std::vector<double> posz,
  std::vector<double> yaw,std::vector<std::string> names,
  std::vector<double> scales,std::vector<double> colors
);



void motor_power(int power);
void job(int power);
void mapcmd(int power);

void posereset(std::vector<double> pose);

#endif
