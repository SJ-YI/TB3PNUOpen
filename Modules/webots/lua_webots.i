/*
  Swig interface which maps Webots C API into a Lua module
*/

%module webots

%{
#include <webots/types.h>
#include <webots/device.h>
%}
%include <webots/types.h>
%include <webots/device.h>

%{
#include <webots/accelerometer.h>
#include <webots/camera.h>
#include <webots/compass.h>
#include <webots/connector.h>
#include <webots/differential_wheels.h>
#include <webots/display.h>
#include <webots/distance_sensor.h>
#include <webots/emitter.h>
#include <webots/gps.h>
#include <webots/gyro.h>
#include <webots/led.h>
#include <webots/light_sensor.h>
#include <webots/nodes.h>
#include <webots/microphone.h>
#include <webots/pen.h>
#include <webots/radio.h>
#include <webots/receiver.h>
#include <webots/robot.h>
#include <webots/speaker.h>
#include <webots/supervisor.h>
#include <webots/touch_sensor.h>
#include <webots/position_sensor.h>
#include <webots/lidar_point.h>
#include <webots/lidar.h>
#include <webots/range_finder.h>
#include <webots/keyboard.h>
%}




%{
#include <string.h>
%}

%{
int match_suffix(char *str1, char* str2) {
  int i, match = 1;
  size_t len1 = strlen(str1);
  size_t len2 = strlen(str2);
  if (len1 >= len2) {
    for (i = 1; i <= len2; i++)
      match = match & (str1[len1-i] == str2[len2-i]);
    return match;
  }
  return 0;
}
%}

/*
%{
#include <vector>
%}
*/
// Camera: unsigned char array
%typemap(out) unsigned char * {
  lua_pushlightuserdata(L, $1);
  SWIG_arg++;
}
/* camera tag */
unsigned char * to_rgb( int tag );
%{
unsigned char * to_rgb( int tag ) {
  // Images no greater than 640*480*3 !
  //#define TO_RGB_MAX_BUF 921600
  // 512*424*4 = 868,352
//  static unsigned char rgb[868352];
//3000  by 2000 by 3 = 18000000

  static unsigned char rgb[18000000];

  const int width  = wb_camera_get_width(tag);
  const int height = wb_camera_get_height(tag);
  const unsigned char * raw = wb_camera_get_image( tag );

    int x, y, rgb_index = 0;
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            rgb[rgb_index++] = wb_camera_image_get_red   (raw, width, x, y);
            rgb[rgb_index++] = wb_camera_image_get_green (raw, width, x, y);
            rgb[rgb_index++] = wb_camera_image_get_blue  (raw, width, x, y);
        }
    }
    return (unsigned char *)(&rgb[0]);
}
%}


// manage double arrays
%typemap(out) const double * {
  int i, len;
  if (match_suffix("$name", "_vec2f"))
    len = 2;
  else if (match_suffix("$name", "_sf_vec3f"))
    len = 3;
  else if (match_suffix("$name", "_sf_rotation"))
    len = 4;
  else if (match_suffix("$name", "_orientation"))
    len = 9;
  else
    len = 3;
  lua_createtable(L, len, 0);
  for (i = 0; i < len; i++) {
    lua_pushnumber(L, $1[i]);
    lua_rawseti(L, -2, i+1);
  }
  SWIG_arg++;
}

%include <webots/accelerometer.h>


// Camera: unsigned char array
%typemap(out) unsigned char * {
  lua_pushlightuserdata(L, $1);
  SWIG_arg++;
}
%typemap(out) float * {
  lua_pushlightuserdata(L, $1);
  SWIG_arg++;
}

//now works with this function... :[
/* lidar tag */
float * get_lidar_ranges( int tag );
%{
float * get_lidar_ranges( int tag ) {
  //Max size of buffer
  //Velodyne HDL 32: 1800 angles * 32 rays = 57600
  static float range[1024*768];

  const int width  = wb_lidar_get_horizontal_resolution(tag);
  const int height = wb_lidar_get_number_of_layers(tag);
  const float * raw = wb_lidar_get_range_image( tag );

  memcpy(range,raw,width*height*sizeof(float));
  /*
  int i;
  for (i = 0; i < width; i++) {
    range[i]=raw[i];
  }
  */
  return (float *)(&range[0]);
}
%}


//To make range_finder_get_range_image work
/* lidar tag */
float * get_rangefinder_ranges( int tag );
%{
float * get_rangefinder_ranges( int tag ) {
  //Max size of buffer, 640*480: 307200
  static float range[307200];
  const int width  = wb_range_finder_get_width(tag);
  const int height = wb_range_finder_get_height(tag);;
  const float * raw = wb_range_finder_get_range_image(tag);
  memcpy(range,raw,width*height*sizeof(float));
  return (float *)(&range[0]);
}
%}



%include <webots/camera.h>
%typemap(out) unsigned char *;
%typemap(out) float *;

%include <webots/compass.h>
%include <webots/connector.h>
%include <webots/differential_wheels.h>
%include <webots/display.h>
%include <webots/distance_sensor.h>

// Emitter:
%typemap(in) (const void *data, int size) {
  size_t len;
  $1 = (void *) lua_tolstring(L, $input, &len);
  $2 = len;
}
%include <webots/emitter.h>
%typemap(in) (const void *data, int size);

%include <webots/gps.h>
%include <webots/gyro.h>
%include <webots/led.h>
%include <webots/light_sensor.h>
%include <webots/microphone.h>
%include <webots/nodes.h>
%include <webots/pen.h>
%include <webots/radio.h>


%typemap(out) const void * {
  lua_pushlstring(L, (const char*) $1, wb_receiver_get_data_size(arg1));
  SWIG_arg++;
}
%include <webots/receiver.h>
%typemap(out) const void *;

%include <webots/robot.h>
%include <webots/speaker.h>

%{
  typedef struct {
    void *ptr;
    char type;
    int size;
    int own; // 1 if array was created by Lua and needs to be deleted
  } structCArray;
%}

%typemap(in) (const double values[3]) {
  structCArray* p = (structCArray*)lua_touserdata(L, $input);
  $1 = (double *)p->ptr;
}
%typemap(in) (const double values[4]) {
  structCArray* p = (structCArray*)lua_touserdata(L, $input);
  $1 = (double *)p->ptr;
}

%include <webots/supervisor.h>
// Reset now...
%typemap(in) (const double values[3]);
%typemap(in) (const double values[4]);

%include <webots/touch_sensor.h>


/* This is Webots7 only!! */
%{
#include <webots/inertial_unit.h>
#include <webots/motor.h>
%}

/* For Webots 8!!! */
%include <webots/inertial_unit.h>
%include <webots/motor.h>
%include <webots/position_sensor.h>
%include <webots/lidar_point.h>

%typemap(out) float *;
%include <webots/lidar.h>

%typemap(out) float *;
%include <webots/range_finder.h>

//for webots 8.5 beta
%include <webots/keyboard.h>
