#include <webots/robot.h>

// Added a new include file
#include <stdio.h>
#include <string.h>
#include <time.h>

int main(int argc, char **argv)
{
  wb_robot_init();
  int time_step = wb_robot_get_basic_time_step();
  WbDeviceTag motor1 = wb_robot_get_device("jointleft");
  WbDeviceTag motor2 = wb_robot_get_device("jointright");
  WbDeviceTag receiver = wb_robot_get_device("receiver");
  wb_receiver_enable(receiver,time_step);
  int status=0;
  wb_motor_set_position(motor1,-1.57);
  wb_motor_set_position(motor2,-1.57);
  srand(time(NULL));

  while (wb_robot_step(time_step) != -1){
    while (wb_receiver_get_queue_length(receiver) > 0) {
      const char *message = wb_receiver_get_data(receiver);
      int recvnum=atoi(message);
      wb_receiver_next_packet(receiver);
      if ((recvnum==1)&&(status>0)){
        status=0;
        printf("Sign reset!\n");
        wb_motor_set_position(motor1,-1.57);
        wb_motor_set_position(motor2,-1.57);
      }else{
        if ((status==0)&&(recvnum==2)){
          if (rand()%2==0){
            status=1;
            printf("Left turn set!\n");
            wb_motor_set_position(motor1,0);
          }else{
            status=2;
            printf("Right turn set!\n");
            wb_motor_set_position(motor2,0);
          }
        }
      }
    }
  }
  wb_robot_cleanup();
  return 0;
}
