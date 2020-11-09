/*
 * generic_hid.c
 *
 *  Created on: Apr 22, 2011
 *      Author: Jan Axelson
 *
 * Demonstrates communicating with a device designed for use with a generic HID-class USB device.
 * Sends and receives 2-byte reports.
 * Requires: an attached HID-class device that supports 2-byte
 * Input, Output, and Feature reports.
 * The device firmware should respond to a received report by sending a report.
 * Change VENDOR_ID and PRODUCT_ID to match your device's Vendor ID and Product ID.
 * See Lvr.com/winusb.htm for example device firmware.
 * This firmware is adapted from code provided by Xiaofan.
 * Note: libusb error codes are negative numbers.

 The application uses the libusb 1.0 API from libusb.org.
 Compile the application with the -lusb-1.0 option.
 Use the -I option if needed to specify the path to the libusb.h header file. For example:
 -I/usr/local/angstrom/arm/arm-angstrom-linux-gnueabi/usr/include/libusb-1.0

*/


/**
 * Lua module for xbox 360 wireless controller
 * cleaned up by SJ, 2016
 */

#include <lua.hpp>

#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdlib.h>
#include <libusb.h>
#include <vector>

#include <sys/time.h>
#include <sys/types.h>

// initialized flag
int init = 0;
int running = 0;
int stopRequest = 0;
int jsFD;


int dpad[2]; //D-pad controls
int trigger[2]; //L/R triggers (0-255)
int lstick[2]; //left analog stick (-32768-32768, -32768-32768)
int rstick[2]; //left analog stick (-32768-32768, -32768-32768)
int buttons[9]; //BACK START LB RB XBOX X Y A B

/* Global Variables */
static pthread_t xbThread;
struct libusb_device_handle *devh = NULL;

/* Constants for the USB device */
static const int VENDOR_ID = 0x045e;

static const int INTERRUPT_IN_ENDPOINT = 0x81;
static const int INTERRUPT_OUT_ENDPOINT = 0x02;
static const int MAX_INTERRUPT_IN_TRANSFER_SIZE = 40;
static const int MAX_INTERRUPT_OUT_TRANSFER_SIZE = 32;
static const int CONTROL_REQUEST_TYPE_IN = LIBUSB_ENDPOINT_IN |
	LIBUSB_REQUEST_TYPE_CLASS | LIBUSB_RECIPIENT_INTERFACE;
static const int CONTROL_REQUEST_TYPE_OUT = LIBUSB_ENDPOINT_OUT |
	LIBUSB_REQUEST_TYPE_CLASS | LIBUSB_RECIPIENT_INTERFACE;
static const int HID_GET_REPORT = 0x01;
static const int HID_SET_REPORT = 0x09;
static const int HID_REPORT_TYPE_INPUT = 0x01;
static const int HID_REPORT_TYPE_OUTPUT = 0x02;
static const int HID_REPORT_TYPE_FEATURE = 0x03;
static const int MAX_CONTROL_IN_TRANSFER_SIZE = 2;
static const int MAX_CONTROL_OUT_TRANSFER_SIZE = 2;
static const int INTERFACE_NUMBER = 0;
static const int TIMEOUT_MS = 5000;

static std::vector<int> lua_checkvector(lua_State *L, int narg) {
	if ( !lua_istable(L, narg) )	luaL_argerror(L, narg, "vector");
	int n = lua_objlen(L, narg);
	std::vector<int> v(n);
	for (int i = 0; i < n; i++) {
		lua_rawgeti(L, narg, i+1);
		v[i] = lua_tonumber(L, -1);
		lua_pop(L, 1);
	}
	return v;
}


/* Clean up the Thread when done */
int xbox360_thread_cleanup() {
  if (init) {
    // set initialized to false
    init = 0;
    libusb_release_interface(devh, 0);
    libusb_close(devh);
    libusb_exit(NULL);
  }
  return 0;
}
/* Thread function for listening to the controller */
void *xbox360_thread_func(void *) {
	int bytes_transferred;
	int result = 0;
	int i = 0;
 	unsigned char data_in[40]; // Reports are 20 bytes for 360
  /*
     sigset_t sigs;
     sigfillset(&sigs);
     pthread_sigmask(SIG_BLOCK, &sigs, NULL);
     */
  while (!stopRequest) {
    // Read data from the device.
    result = libusb_interrupt_transfer(
        devh,
        INTERRUPT_IN_ENDPOINT,
        data_in,
        MAX_INTERRUPT_OUT_TRANSFER_SIZE,
        &bytes_transferred,
        0); // Timeout of 0 waits forever...

    if (result >= 0 && bytes_transferred > 0) {

			//0 1 0 240 0 19 DBTN LRXYAB LT RT   LY LY LX LX RY RY RX RX
			//DBTN: U(1) D(2) L(4) R(8) START(16) BACK(32)
			//LRXYAB: LB(1) RB(2) XBOX(4) A(16) B(32) X(64) Y(128)
			//LT: left trigger (0-255)
			//RT: right trigger (0-255)
			//LX LY RX RY: 2-byte int

			if (data_in[1]==1){
				//1 for genuine controller Control Input
				//				for(i=0;i<bytes_transferred;i++)printf("%d ",data_in[i]);	printf("\n");

				//D-pad
				dpad[0] = (data_in[6]&1) - ((data_in[6]&2)>>1);
				dpad[1] = ((data_in[6]&4)>>2)  - ((data_in[6]&8)>>3);

				//Other buttons
				buttons[0] = data_in[6]>>5; //BACK
				buttons[1] = (data_in[6]&16)>>4;//START
				buttons[2] = data_in[7]&1; //LB
				buttons[3] = (data_in[7]&2)>>1;//RB
				buttons[4] = (data_in[7]&4)>>2;//XBOX
				buttons[5] = (data_in[7]&64)>>6;//X
				buttons[6] = (data_in[7]&128)>>7;//Y
				buttons[7] = (data_in[7]&16)>>4;//A
				buttons[8] = (data_in[7]&32)>>5;//B

				//Trigger
				trigger[0] = data_in[8];
				trigger[1] = data_in[9];
				//Left and Right analog controls
				lstick[1] = -*((int16_t*)(data_in+10));
				lstick[0] = *((int16_t*)(data_in+12));
				rstick[1] = -*((int16_t*)(data_in+14));
				rstick[0] = *((int16_t*)(data_in+16));
//				printf("LT %d RT %d LSTICK %d %d RSTICK %d %d\n",lt,rt,lx,ly,rx,ry);
			}
		if (data_in[1]==20){
			//Chinese controller!!
			//20 for chinese white version (short 2.4ghz receiver)

			// printf("2: %d 3:%d 4:%d 5:%d 6:%d 7:%d 8:%d 9:%d 10:%d 11:%d 12:%d 13:%d 14:%d 15:%d\n",
			// 	data_in[2],
			// 	data_in[3],
			// 	data_in[4],
			// 	data_in[5],
			// 	data_in[6],
			// 	data_in[7],
			// 	data_in[8],
			// 	data_in[9],
			// 	data_in[10],
			// 	data_in[11],
			// 	data_in[12],
			// 	data_in[13],
			// 	data_in[14],
			// 	data_in[15]
			// );

			//Other buttons
			buttons[0] = (data_in[2]&32)>>5; //BACK
			buttons[1] = (data_in[2]&16)>>4;//START
			buttons[2] = data_in[3]&1; //LB
			buttons[3] = (data_in[3]&2)>>1;//RB
			buttons[4] = (data_in[3]&4)>>2;//XBOX
			buttons[5] = (data_in[3]&64)>>6;//X
			buttons[6] = (data_in[3]&128)>>7;//Y
			buttons[7] = (data_in[3]&16)>>4;//A
			buttons[8] = (data_in[3]&32)>>5;//B

			//d pad
			dpad[0] = (data_in[2]&1) - ((data_in[2]&2)>>1);
			dpad[1] = ((data_in[2]&4)>>2)  - ((data_in[2]&8)>>3);


			//Trigger
			trigger[0] = data_in[4];
			trigger[1] = data_in[5];

			lstick[0]=(int8_t) data_in[9];
			lstick[1]=-(int8_t) data_in[7];

			rstick[0]=(int8_t) data_in[13];
			rstick[1]=-(int8_t) data_in[11];
			// printf("Lstick: X%d Y%d  Rstick: %d %d\n",lstick[0],lstick[1],rstick[0],rstick[1]);

		}
    }
  }
  xbox360_thread_cleanup();
  running = 0;
	return NULL;
}

int xbox360_thread_init(int prod_id) {
  if (init) {xbox360_thread_cleanup();}    // a joystick is already open, close it first
  // INIT
  int result, i;
  result = libusb_init(NULL);
  if (result < 0) {
    fprintf(stderr, "Unable to initialize libusb.\n");
    return -1;
  }
  devh = libusb_open_device_with_vid_pid(NULL, VENDOR_ID, prod_id);
  if (devh != NULL) {
    // The HID has been detected.
    // Detach the hidusb driver from the HID to enable using libusb.
    libusb_detach_kernel_driver(devh, INTERFACE_NUMBER);
    result = libusb_claim_interface(devh, INTERFACE_NUMBER);
    if (result < 0) {
      fprintf(stderr, "libusb_claim_interface error %d\n", result);
      return -1;
    }
  }
  else  {
		fprintf(stderr, "Unable to find the device.\n");
  }

  // start receiver thread
  running = 1;
	int ret;
  ret = pthread_create(&xbThread, NULL, xbox360_thread_func, NULL);
  if (ret != 0) {
    fprintf(stderr, "error creating joystick thread: %d\n", ret);
    return -1;
  }
  init = 1;
	// lua_pushnumber(L, v[i]);
  return 0;
}


static void lua_pushdarray(lua_State *L, int* v, int size) {
	lua_createtable(L, size, 0);
	for (int i = 0; i < size; i++) {
		lua_pushnumber(L, v[i]);
		lua_rawseti(L, -2, i+1);
	}
}


/* Lua accessor functions */
static int lua_joystick_check(lua_State *L) {
	std::vector<int>pid_list=lua_checkvector(L,1);
	libusb_context *ctx = NULL ;
	libusb_init(&ctx);
	printf("Checking libusb devices!!!!\n");
	libusb_device **list;
	ssize_t cnt = libusb_get_device_list(ctx,&list);
	printf("Total %d devices found\n",cnt);

	int device_id=0;
	for (size_t i = 0; i < cnt; i++) {
	    libusb_device *device = list[i];
			libusb_device_descriptor desc;
    	int rc=libusb_get_device_descriptor(device, &desc);
			// printf("Device #%d Vender:%04x Product:%04x\n", i, desc.idVendor,desc.idProduct);
			for(int j=0;j<pid_list.size();j++){
				if (desc.idProduct==pid_list[j]){
					device_id=desc.idProduct;
				}
			}
	}
	libusb_free_device_list(list,cnt);
	libusb_exit(ctx);
	if(device_id>0){
		printf("Dongle found with id %04x!!!!\n",device_id);
		xbox360_thread_init(device_id);
		lua_pushnumber(L, 1);
		return 1;
	}
	return 0;
}


static int lua_joystick_open(lua_State *L) {
  int prod_id = luaL_checkint(L, 1);
  return xbox360_thread_init(prod_id);
}

static int lua_joystick_close(lua_State *L) {
  // stop thread
  stopRequest = 1;
  while (running) {usleep(1000);}
  stopRequest = 0;
  return 0;
}

static int lua_joystick_read(lua_State *L) {

	lua_createtable(L, 0, 5);

	lua_pushstring(L, "dpad");
	lua_pushdarray(L,dpad,2);
	lua_rawset(L,-3);

	lua_pushstring(L, "buttons");
	lua_pushdarray(L,buttons,9);
	lua_rawset(L,-3);

	lua_pushstring(L, "trigger");
	lua_pushdarray(L,trigger,2);
	lua_rawset(L,-3);

	lua_pushstring(L, "lstick");
	lua_pushdarray(L,lstick,2);
	lua_rawset(L,-3);

	lua_pushstring(L, "rstick");
	lua_pushdarray(L,rstick,2);
	lua_rawset(L,-3);

  return 1;
}


static const struct luaL_Reg xbox360_lib [] = {
	{"check", lua_joystick_check},
  {"open", lua_joystick_open},
  {"close", lua_joystick_close},
  {"read", lua_joystick_read},
  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_xbox360 (lua_State *L) {
  luaL_register(L, "xbox360", xbox360_lib);

  return 0;
}
