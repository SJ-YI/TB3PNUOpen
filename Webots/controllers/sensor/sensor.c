#include <webots/robot.h>

// Added a new include file
#include <stdio.h>
#include <string.h>
#include <webots/gps.h>
#include <webots/emitter.h>
#include <webots/distance_sensor.h>

int main(int argc, char **argv)
{
  wb_robot_init();
  int time_step = wb_robot_get_basic_time_step();
  WbDeviceTag ir = wb_robot_get_device("IR");
  wb_distance_sensor_enable(ir, time_step);
  WbDeviceTag emitter = wb_robot_get_device("emitter");
  double max_dist=wb_distance_sensor_get_max_value(ir);

  char message[32];
  while (wb_robot_step(time_step) != -1){
   double distance = wb_distance_sensor_get_value(ir);
   // printf("Sensor %s: Distance:%.1f\n",argv[1],distance);
   if(distance<max_dist){
     wb_emitter_send(emitter,argv[1],strlen(argv[1])+1);
   }
  }
  wb_robot_cleanup();
  return 0;
}
