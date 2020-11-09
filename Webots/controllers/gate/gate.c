#include <webots/robot.h>

// Added a new include file
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv)
{
  wb_robot_init();
  int time_step = wb_robot_get_basic_time_step();
  WbDeviceTag motor = wb_robot_get_device("joint");
  WbDeviceTag receiver = wb_robot_get_device("receiver");
  wb_receiver_enable(receiver,time_step);
  wb_motor_set_position(motor,1.57);

  double gate_close_time=0.0;
  double gate_close_duration = 5.0;
  int status=0;

  while (wb_robot_step(time_step) != -1){
    double cur_time=wb_robot_get_time();
    while (wb_receiver_get_queue_length(receiver) > 0) {
      const char *message = wb_receiver_get_data(receiver);
      int recvnum=atoi(message);
      wb_receiver_next_packet(receiver);
      if ((recvnum==3)&&(status==0)){
        printf("Gate close!!!");
        gate_close_time=cur_time;
        status=1;
        wb_motor_set_position(motor,0.0);
      }
    }

    if(status==1){
      if(cur_time>gate_close_time+gate_close_duration){
        printf("Gate open!!!\n");
        status=0;
        wb_motor_set_position(motor,1.57);
      }
    }
  }
  wb_robot_cleanup();
  return 0;
}
