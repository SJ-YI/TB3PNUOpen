#include "rospub.h"
#include "ros/ros.h"
#include "tf/transform_broadcaster.h"
#include <sensor_msgs/LaserScan.h>
#include <sensor_msgs/CameraInfo.h>
#include <sensor_msgs/Image.h>
#include "nav_msgs/Odometry.h"
#include "nav_msgs/OccupancyGrid.h"
#include "nav_msgs/Path.h"
#include "trajectory_msgs/JointTrajectory.h"
#include "sensor_msgs/JointState.h"
#include "std_msgs/Float32MultiArray.h"
#include "std_msgs/Bool.h"
#include "std_msgs/Int32.h"
#include "visualization_msgs/MarkerArray.h"

#include "geometry_msgs/PoseWithCovarianceStamped.h"

std::unique_ptr<ros::NodeHandle> rosNode;
ros::Publisher lidar_publisher;
ros::Publisher rgb_publisher;
ros::Publisher depth_publisher;
ros::Publisher rgbinfo_publisher;
ros::Publisher baseteleop_publisher;
ros::Publisher cmdvel_publisher;

ros::Publisher odom_publisher;
ros::Publisher joint_publisher;
ros::Publisher jointstate_publisher;
ros::Publisher motorvel_publisher;
ros::Publisher path_publisher;
ros::Publisher lomap_publisher;
ros::Publisher markerarray_publisher;
ros::Publisher motorpower_publisher;
ros::Publisher job_publisher;
ros::Publisher mapcmd_publisher;
ros::Publisher posereset_publisher;

void ros_init(const char* node_name){
  if(!ros::isInitialized())
  {
    int argc = 0;
    char **argv = NULL;
    ros::init(argc, argv, node_name, ros::init_options::NoSigintHandler);
  }
  rosNode.reset(new ros::NodeHandle(node_name));
  init_publishers();
  ros::Time::init();
  ros::Time::useSystemTime();
}

void init_publishers(){

  baseteleop_publisher = rosNode->advertise<geometry_msgs::Twist>("/teleop_vel", 1, true);
  cmdvel_publisher = rosNode->advertise<geometry_msgs::Twist>("/cmd_vel", 1, true);
  rgb_publisher= rosNode->advertise<sensor_msgs::Image>("/image_raw", 1, true);
  depth_publisher= rosNode->advertise<sensor_msgs::Image>("/depth_image_raw", 1, true);
  rgbinfo_publisher= rosNode->advertise<sensor_msgs::CameraInfo>("/camera_info", 1, true);
  lidar_publisher= rosNode->advertise<sensor_msgs::LaserScan>("/scan", 1, true);
  odom_publisher= rosNode->advertise<nav_msgs::Odometry>("/odom", 1, true);
  joint_publisher= rosNode->advertise<trajectory_msgs::JointTrajectory>("/joint_cmd", 1, true);
  jointstate_publisher= rosNode->advertise<sensor_msgs::JointState>("/joint_states", 1, true);
  motorvel_publisher= rosNode->advertise<std_msgs::Float32MultiArray>("/motor_cmd_vel", 1, true);
  path_publisher= rosNode->advertise<nav_msgs::Path>("/path", 1, true);
  lomap_publisher= rosNode->advertise<nav_msgs::OccupancyGrid>("/lowres_map", 1, true);
  markerarray_publisher= rosNode->advertise<visualization_msgs::MarkerArray>("/pnu_markerarray", 1, true);
  motorpower_publisher= rosNode->advertise<std_msgs::Bool>("/motor_power", 1, true);
  job_publisher= rosNode->advertise<std_msgs::Int32>("/job", 1, true);
  mapcmd_publisher= rosNode->advertise<std_msgs::Int32>("/mapcmd", 1, true);
//  posereset_publisher= rosNode->advertise<geometry_msgs::PoseWithCovarianceStamped>("/laser_2d_correct_pose", 1, true);
  posereset_publisher= rosNode->advertise<geometry_msgs::PoseWithCovarianceStamped>("/initialpose", 1, true);
}

void send_tf(std::vector<double>xyz,std::vector<double>rpy,const char* mother_link, const char* child_link){
  static tf::TransformBroadcaster br;
  tf::Transform transform;
  transform.setOrigin(tf::Vector3(xyz[0],xyz[1],xyz[2]));
  tf::Quaternion q; q.setRPY(rpy[0],rpy[1],rpy[2]);
  transform.setRotation(q);
  br.sendTransform(tf::StampedTransform(transform, ros::Time::now(),mother_link, child_link));
}

void baseteleop(double x, double y, double a){
  geometry_msgs::Twist msg;
  msg.linear.x=x;
  msg.linear.y=y;
  msg.linear.z=0.0;
  msg.angular.x=0.0;
  msg.angular.y=0.0;
  msg.angular.z=a;
  baseteleop_publisher.publish(msg);
}

void cmdvel(double x, double y, double a){
  geometry_msgs::Twist msg;
  msg.linear.x=x;
  msg.linear.y=y;
  msg.linear.z=0.0;
  msg.angular.x=0.0;
  msg.angular.y=0.0;
  msg.angular.z=a;
  cmdvel_publisher.publish(msg);
}

void webotslaserscan(int seq,float angle_min, float angle_max, int n,
  float angle_increment,float* ranges, const char* linkname){
  //webots scan data is from left (+yaw) to right (-yaw)
  sensor_msgs::LaserScan msg;
  msg.header.seq=seq;
  msg.header.stamp=ros::Time::now();
  msg.header.frame_id=linkname;
  msg.angle_min=angle_min;
  msg.angle_max=angle_max;
  msg.angle_increment=angle_increment;
  msg.range_min = 0.1;
  msg.range_max = 6.0;

  msg.time_increment=0;
  msg.scan_time=0.2;

  msg.ranges.resize(n);
  // for(int i=0;i<n;i++) msg.ranges[i]=ranges[i];
  for(int i=0;i<n;i++) msg.ranges[i]=ranges[n-1-i];
  lidar_publisher.publish(msg);
}

void webotslaserscancrop(int seq,  float angle_min, float angle_max,int n,
  float angle_increment,float* ranges, const char* linkname,int ray_num){
  //webots scan data is from left (+yaw) to right (-yaw)
  //for -pi to pi,
  //angle[0]=179.5 deg
  //angle[1]= 178.5 deg
  //angle[179]=0.5 deg
  //angle[180]=-0.5 deg
  //angle[359]=179.5 deg

  sensor_msgs::LaserScan msg;
  msg.header.seq=seq;
  msg.header.stamp=ros::Time::now();
  msg.header.frame_id=linkname;
  msg.angle_min=angle_min+angle_increment*ray_num;
  msg.angle_max=angle_max-angle_increment*ray_num;
  msg.angle_increment=angle_increment;
  msg.range_min = 0.1;
  msg.range_max = 6.0;
  msg.time_increment=0;
  msg.scan_time=0.2;

  msg.ranges.resize(n-2*ray_num);
  for(int i=ray_num;i<n-ray_num;i++) {
    msg.ranges[i-ray_num]=ranges[n-1-i];
  }
  lidar_publisher.publish(msg);
}



void laserscan(int seq,float angle_min, float angle_max, int n,
  float angle_increment,float* ranges, const char* linkname){
  sensor_msgs::LaserScan msg;
  msg.header.seq=seq;
  msg.header.stamp=ros::Time::now();
  msg.header.frame_id=linkname;
  msg.angle_min=angle_min;
  msg.angle_max=angle_max;
  msg.angle_increment=angle_increment;
  msg.range_min = 0.1;
  msg.range_max = 6.0;
  msg.time_increment=0.0;
  msg.ranges.resize(n);
  for(int i=0;i<n;i++) msg.ranges[i]=ranges[i];
  lidar_publisher.publish(msg);
}


void camerainfo(int seq,int width, int height, double fov){
  sensor_msgs::CameraInfo msg;
  msg.header.seq=seq;
  msg.header.stamp=ros::Time::now();
  msg.header.frame_id="head_rgbd_sensor_rgb_frame";
  msg.width=width;
  msg.height=height;
  msg.distortion_model="plumb_bob";

  // double fx=554.3827128226441; //focal length in pixels, width=640
  double fx = ( (double) width )/2.0 / tan(fov/2.0);
//fov = atan(640/2/554)*2.0 : 60 degree

  double cx=(msg.width+1.0)/2.0;
  double cy=(msg.height+1.0)/2.0;
  double P[12]={fx,0.0,cx,0.0,   0.0,fx,cy,0.0,    0.0,0.0,1.0,0.0};
  double K[9]={fx,0.0,cx,   0.0,fx,cy,    0.0,0.0,1.0};
  double R[9]={1.0,0.0,0.0,   0.0,1.0,0.0,   0.0,0.0,1.0};
  int i;
  msg.D.resize(5);
  for(i=0;i<5;i++) msg.D[i]=0.0;
  for(i=0;i<12;i++) msg.P[i]=P[i];
  for(i=0;i<9;i++) {msg.K[i]=K[i];msg.R[i]=R[i];}

  msg.binning_x=0;
  msg.binning_y=0;
  msg.roi.x_offset=0;
  msg.roi.y_offset=0;
  msg.roi.height=0;
  msg.roi.width=0;
  msg.roi.do_rectify=false;
  rgbinfo_publisher.publish(msg);
}

void rgbimage(int seq,int width, int height, const char* data){
  sensor_msgs::Image msg;
  msg.header.seq=seq;
  msg.header.stamp=ros::Time::now();
  msg.header.frame_id="head_rgbd_sensor_rgb_frame_sync";
  msg.width=width;
  msg.height=height;
  msg.encoding="rgb8";
  msg.is_bigendian=0;
  msg.step = width*3; //640*3
  msg.data.insert(msg.data.end(), &data[0],&data[width*height*3]);
  rgb_publisher.publish(msg);
}

void depthimage(int seq,int width, int height, const char* data){
  sensor_msgs::Image msg;
  msg.header.seq=seq;
  msg.header.stamp=ros::Time::now();
  msg.header.frame_id="head_rgbd_sensor_rgb_frame_sync";
  msg.width=width;
  msg.height=height;

  msg.encoding="32FC1"; //32 bit float encoding for webots
  msg.is_bigendian=0;
  msg.step = width*4;
  msg.data.insert(msg.data.end(), &data[0],&data[width*height*4]);
  depth_publisher.publish(msg);
}


void send_odom(std::vector<double>pose){
  nav_msgs::Odometry msg;
  msg.header.stamp=ros::Time::now();
  msg.header.frame_id="odom";
  msg.child_frame_id="base_link";
  msg.pose.pose.position.x=pose[0];
  msg.pose.pose.position.y=pose[1];
  msg.pose.pose.position.z=0.0;
  msg.pose.pose.orientation.x=0.0;
	msg.pose.pose.orientation.y=0.0;
	msg.pose.pose.orientation.z=1.0*sin(pose[2]/2.0);
  msg.pose.pose.orientation.w=cos(pose[2]/2.0);
  odom_publisher.publish(msg);
}

void send_joint(std::vector<double>armangle, float gripforce){
  trajectory_msgs::JointTrajectory msg;
  msg.header.stamp=ros::Time::now();
  msg.joint_names.push_back("arm1");
  msg.joint_names.push_back("arm2");
  msg.joint_names.push_back("arm3");
  msg.joint_names.push_back("arm4");
	msg.joint_names.push_back("gripper");
  msg.points.resize(1);
  msg.points[0].positions.resize(5);
  msg.points[0].positions[0]=armangle[0];
  msg.points[0].positions[1]=armangle[1];
  msg.points[0].positions[2]=armangle[2];
  msg.points[0].positions[3]=armangle[3];
  msg.points[0].positions[4]=gripforce;
  msg.points[0].time_from_start=ros::Duration(1.0);
  joint_publisher.publish(msg);

}

void send_jointtraj(std::vector<std::string> jointnames,std::vector<double>jangles,std::vector<double>jointvel){
  trajectory_msgs::JointTrajectory msg;
  msg.header.stamp=ros::Time::now();
  msg.joint_names.resize(jointnames.size());
  msg.points.resize(1);
  msg.points[0].positions.resize(jointnames.size());
  msg.points[0].velocities.resize(jointnames.size());
  for(int i=0;i<jointnames.size();i++){
    msg.joint_names[i]=jointnames[i];
    msg.points[0].positions[i]=jangles[i];
    msg.points[0].velocities[i]=jointvel[i];
  }
  msg.points[0].time_from_start=ros::Duration(1.0);
  joint_publisher.publish(msg);
}


void send_jointstate(std::vector<std::string> jointnames,std::vector<double>jangles){
  sensor_msgs::JointState msg;
  msg.header.stamp=ros::Time::now();
  msg.name.resize(jointnames.size());
  msg.position.resize(jointnames.size());
  for(int i=0;i<jointnames.size();i++){
    msg.name[i]=jointnames[i];
    msg.position[i]=jangles[i];
  }
  jointstate_publisher.publish(msg);
}

void send_motorvel(std::vector<double>motorvel){
  std_msgs::Float32MultiArray msg;
  msg.layout.dim.resize(1);
  msg.layout.dim[0].size=motorvel.size();
  msg.data.resize(motorvel.size());
  for(int i=0;i<motorvel.size();i++) msg.data[i]=motorvel[i];
  motorvel_publisher.publish(msg);
}

void send_path(std::vector<double> posx,std::vector<double> posy,std::vector<double> posa){
  nav_msgs::Path msg;
  msg.header.stamp=ros::Time::now();
  msg.header.frame_id="map";
  msg.poses.resize(posx.size());
  for(int i=0;i<posx.size();i++){
    msg.poses[i].header.stamp=ros::Time::now();
    msg.poses[i].header.frame_id="map";
    msg.poses[i].pose.position.x=posx[i];
    msg.poses[i].pose.position.y=posy[i];
    msg.poses[i].pose.position.z=0.0;
    msg.poses[i].pose.orientation.x=0.0;
    msg.poses[i].pose.orientation.y=0.0;
    msg.poses[i].pose.orientation.z=sin(posa[i]/2);
    msg.poses[i].pose.orientation.w=cos(posa[i]/2);
  }
  path_publisher.publish(msg);
}

void send_occgrid(float res, int width, int height, float x0, float y0, float z0, const char* data){
  nav_msgs::OccupancyGrid msg;
  msg.header.stamp=ros::Time::now();
  msg.header.frame_id="map";
  msg.info.resolution=res;
  msg.info.width=width;
  msg.info.height=height;
  msg.info.origin.position.x=x0;
  msg.info.origin.position.y=y0;
  msg.info.origin.position.z=z0;
  msg.data.insert(msg.data.end(), &data[0],&data[width*height]);
  lomap_publisher.publish(msg);
}


void setup_marker(visualization_msgs::Marker *marker,
  int type, int id,
  float xpos, float ypos, float zpos, float yaw,
  float xscale, float yscale, float zscale, float scale,
  float r,float g,float b,float a, int seq){
  marker->header.frame_id="map";
  marker->header.seq=seq;
  marker->header.stamp=ros::Time::now();
  marker->ns="/pnu";
  marker->type=type;
  marker->id=id;
  marker->action=0;
  marker->scale.x=xscale*scale;
  marker->scale.y=yscale*scale;
  marker->scale.z=zscale*scale;
  marker->lifetime=ros::Duration(2.0);
  marker->color.r=r;marker->color.g=g;marker->color.b=b;marker->color.a=a;
  marker->pose.position.x=xpos;
  marker->pose.position.y=ypos;
  marker->pose.position.z=zpos;
  marker->pose.orientation.x=0.0;
  marker->pose.orientation.y=0.0;
  marker->pose.orientation.z=sin(yaw/2);
  marker->pose.orientation.w=cos(yaw/2);
}


void marker(int num,
  std::vector<double> types,std::vector<double> posx,
  std::vector<double> posy,std::vector<double> posz,
  std::vector<double> yaw,std::vector<std::string> names,
  std::vector<double> scales,std::vector<double> colors
){
  visualization_msgs::MarkerArray msg;
  msg.markers.resize(num);
  int marker_count=0;
  int seq=0; //will this be fine?
  for(int j=0;j<num;j++){
    float r=1.0,g=1.0,b=1.0,a=1.0;
    float scale = scales[j];
    if (colors[j]==1.0) {r=1.0;g=1.0;b=0.0;a=1.0; } //yellow
    if (colors[j]==2.0) {r=1.0;g=0.0;b=0.0;a=1.0; } //red
    if (colors[j]==3.0) {r=0.0;g=0.0;b=1.0;a=1.0; } //blue
    if (colors[j]==4.0) {r=0.0;g=1.0;b=0.0;a=1.0; } //green
    if (colors[j]==5.0) {r=1.0;g=1.0;b=0.0;a=1.0; } //solid yellow
    if (types[j]==1.0){ //Cylinder
      setup_marker(&msg.markers[marker_count], 3, marker_count,
      // posx[marker_count], posy[marker_count], posz[marker_count], 0.0,
      // 0.07,0.07,0.10,  scale, r,g,b,a, seq);
			//align to the top
  			posx[marker_count], posy[marker_count], posz[marker_count], 0.0,
        0.01,0.01,0.10,  scale, r,g,b,a, seq);
      marker_count++;
    }
	  if (types[j]==2.0){ //Text
      setup_marker(&msg.markers[marker_count], 9, marker_count,  //type 9: text string
      posx[marker_count], posy[marker_count], posz[marker_count]+0.10, 0.0,
      0.08,0.08,0.08,   scale, r,g,b,a, seq);
      msg.markers[marker_count].text = names[marker_count];
      marker_count++;
    }
    if (types[j]==3.0){ //horizontal handle
      setup_marker(&msg.markers[marker_count], 1, marker_count,
      posx[marker_count], posy[marker_count], posz[marker_count], yaw[marker_count],
      // 0.03,0.10,0.03,   1.0, r,g,b,a, seq);
      0.03,scale,0.03,   1.0, r,g,b,a, seq);
      marker_count++;
    }

		if (types[j]==4.0){ //vertical handle
			setup_marker(&msg.markers[marker_count], 1, marker_count,
			posx[marker_count], posy[marker_count], posz[marker_count], yaw[marker_count],
			// 0.03,0.030,0.10,   1.0 ,r,g,b,a, seq);
      0.03,0.030,scale,   1.0 ,r,g,b,a, seq);
			marker_count++;
		}
		if (types[j]==5.0){ //ARROW
			setup_marker(&msg.markers[marker_count], 0, marker_count, //type 0: arrow
			posx[marker_count], posy[marker_count], posz[marker_count], yaw[marker_count],
			scale,0.05,0.05,   1.0, r,g,b,a, seq);
			marker_count++;
		}
		if (types[j]==6.0){ //sphere
			setup_marker(&msg.markers[marker_count], 2, marker_count, //type 0: arrow
			posx[marker_count], posy[marker_count], posz[marker_count], yaw[marker_count],
			0.15,0.15,0.15,   scale, r,g,b,a, seq);
			marker_count++;
		}
    if (types[j]==7.0){ //Flat cylinder
      setup_marker(&msg.markers[marker_count], 3, marker_count,
      posx[marker_count], posy[marker_count], posz[marker_count], 0.0,
      0.25,0.25,0.05,  scale, r,g,b,a, seq);
      marker_count++;
    }
  }
  markerarray_publisher.publish(msg);
}

void motor_power(int power){
  std_msgs::Bool msg;
  msg.data=power;
  motorpower_publisher.publish(msg);
}

void job(int power){
  std_msgs::Int32 msg;
  msg.data=power;
  job_publisher.publish(msg);
}
void mapcmd(int power){
  std_msgs::Int32 msg;
  msg.data=power;
  mapcmd_publisher.publish(msg);
}
void posereset(std::vector<double> pose){
  geometry_msgs::PoseWithCovarianceStamped msg;
	msg.header.frame_id="map";
	msg.pose.pose.position.x=pose[0];
	msg.pose.pose.position.y=pose[1];
	msg.pose.pose.position.z=0.0;
	float yaw=pose[2];
	float pitch=0.0;
	double t0=cos(yaw*0.5);
	double t1=sin(yaw*0.5);
	double t2=1.0; //roll 0 deg
	double t3=0.0;
	double t4=cos(pitch  * 0.5); //pitch 90 deg
	double t5=sin(pitch  * 0.5); //pitch 90 deg
	msg.pose.pose.orientation.x=t0*t3*t4-t1*t2*t5;
	msg.pose.pose.orientation.y=t0*t2*t5+t1*t3*t4;
	msg.pose.pose.orientation.z=t1*t2*t4-t0*t3*t5;
	msg.pose.pose.orientation.w=t0*t2*t4+t1*t3*t5;
	for (int i=0;i<36;i++) msg.pose.covariance[i]=0.0;
	msg.pose.covariance[0]=0.01;
	posereset_publisher.publish(msg);
}
