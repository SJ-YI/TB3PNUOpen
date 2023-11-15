LIBNAME = tb3_rospub
EXTRA_OBJ = rospub.o
EXTRA_CFLAGS += -DNDEBUG
include ../../Makefile.inc
CXXFLAGS += -std=c++11 -O2
INCLUDES += -I${ROS_DIR}/include
LDFLAGS += -ltf -ltf2_ros -lactionlib -L${ROS_DIR}/lib -lroscpp -lpthread -lboost_regex -lboost_system -lboost_thread -lboost_chrono -lboost_date_time -lboost_atomic -lrosconsole -lrosconsole_log4cxx -lrosconsole_backend_interface -llog4cxx -lroscpp_serialization -lrostime -lxmlrpcpp -lcpp_common  -lconsole_bridge
