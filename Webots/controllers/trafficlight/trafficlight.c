#include <webots/robot.h>

// Added a new include file
#include <stdio.h>
#include <string.h>
#include <webots/led.h>
#include <webots/emitter.h>
#include <time.h>


int main(int argc, char **argv)
{
  wb_robot_init();
  int time_step = wb_robot_get_basic_time_step();
  WbDeviceTag led1 = wb_robot_get_device("redled");
  WbDeviceTag led2 = wb_robot_get_device("orangeled");
  WbDeviceTag led3 = wb_robot_get_device("greenled");
  WbDeviceTag receiver = wb_robot_get_device("receiver");
  srand(time(NULL));
  setbuf(stdout, NULL);

  wb_receiver_enable(receiver,time_step);
  wb_led_set(led1,1);
  wb_led_set(led2,0);
  wb_led_set(led3,0);

  int status=0;
  double led_next_time=0.0;
  double game_start_time=0.0;

  int blink=1;

  while (wb_robot_step(time_step) != -1){
    double cur_time=wb_robot_get_time();

    switch(status){
      case 0:
        led_next_time=cur_time+3.0+(rand()%3);
        status=1;
        break;
      case 1:
        if(cur_time>led_next_time){
          status=2;
          led_next_time=cur_time+3.0+(rand()%3);
          wb_led_set(led1,0);
          wb_led_set(led2,1);
          wb_led_set(led3,0);
        }
        break;
      case 2:
        if(cur_time>led_next_time){
          status=3;
          led_next_time=cur_time+3.0;
          wb_led_set(led1,0);
          wb_led_set(led2,0);
          wb_led_set(led3,1);
          game_start_time=cur_time;
          printf("GAME START!!!!\n");

        }
        break;
      case 3:
        break;
      case 5:
        if(cur_time>led_next_time){
          blink=1-blink;
          wb_led_set(led1,blink);
          wb_led_set(led2,0);
          wb_led_set(led3,0);
          led_next_time=cur_time+0.3;
        }
        break;
      case 6:
        if(cur_time>led_next_time){
          blink=1-blink;
          wb_led_set(led1,0);
          wb_led_set(led2,0);
          wb_led_set(led3,blink);
          led_next_time=cur_time+0.3;
        }
        break;
    }

    while (wb_receiver_get_queue_length(receiver) > 0) {
      const char *message = wb_receiver_get_data(receiver);
      int recvnum=atoi(message);
      wb_receiver_next_packet(receiver);

      // printf("%d %d\n",recvnum,status);

      if(recvnum==1){
        if (status<3){
          printf("====================\n");
          printf("ILLEGAL START!!!!\n");
          printf("====================\n");

          status=5;
          led_next_time=cur_time;
        }else{
          if (status==3){
            status=4;
            printf("====================\n");
            printf("START GATE PASSED!!!!\n");
            printf("====================\n");

          }else{
            if  ( (status==4)&&(cur_time-game_start_time>15.0) ){
              int total_time=(int) ( cur_time-game_start_time);
              printf("====================\n");
              printf("FINISH!!!!!\n");
              printf("Time record: %d sec\n", total_time);
              printf("====================\n");
          
              status=6;
              led_next_time=cur_time;
            }
          }
        }
      }


    }

  }
  wb_robot_cleanup();
  return 0;
}
