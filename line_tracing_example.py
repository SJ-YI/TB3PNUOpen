#!/usr/bin/env python
import rospy,cv2,math
import numpy as np
from sensor_msgs.msg import Image, LaserScan
from std_msgs.msg import Int32
from cv_bridge import CvBridge, CvBridgeError
from geometry_msgs.msg import Twist

CENTER_X = 200
DETECT_VERTICAL_Y = 235
DETECT_Y = 230  #center = 150
DETECT_LINE_LENGTH = 330
DETECT_LINE_LENGTH_Y = 70
SENSITIVITY = 60
yellow_lower = [22,60-SENSITIVITY,200-SENSITIVITY]
yellow_upper = [60,255,255]
white_lower = [0,0,255-SENSITIVITY]
white_upper = [255,SENSITIVITY,255]

bridge = CvBridge()
velocity_publisher = rospy.Publisher('/cmd_vel', Twist, queue_size=10)

def detectLine(img):
  for x_axis in range(CENTER_X - DETECT_LINE_LENGTH/2,CENTER_X + DETECT_LINE_LENGTH/2):
    color = np.uint8([[img[DETECT_Y,x_axis]]])
    color = cv2.cvtColor(color,cv2.COLOR_BGR2HSV)[0][0]
    if((color[0] >= yellow_lower[0] and color[0] <= yellow_upper[0]) and (color[1] >= yellow_lower[1] and color[1] <= yellow_upper[1]) and (color[2] >= yellow_lower[2] and color[2] <= yellow_upper[2])):
      if(x_axis>CENTER_X):return "Left"
      else:return "Right"
    elif((color[0] >= white_lower[0] and color[0] <= white_upper[0]) and (color[1] >= white_lower[1] and color[1] <= white_upper[1]) and (color[2] >= white_lower[2] and color[2] <= white_upper[2])):
      if(x_axis>CENTER_X):return "Left"
      else:return "Right"
  return "Straight"

def detectLIDAR(scan):
  for i in range(0,len(scan.ranges)-1):
    angle = scan.angle_min + i*scan.angle_increment
    dx=scan.ranges[i]*math.cos(angle)
    dy=scan.ranges[i]*math.sin(angle)
    if (scan.ranges[i]>0.05 and dx<0.30 and dx>0):
      if(dy>-0.15 and dy<0): return "Left"
      if(dy<0.15 and dy>0):  return "Right"
  return "Straight"

def moveTurtlebot(move):
  print(move)
  vel_msg = Twist()
  if (move=="Left"):    vel_msg.angular.z = 0.1
  elif (move=="Right"): vel_msg.angular.z = -0.1
  else:                 vel_msg.linear.x = 0.1
  velocity_publisher.publish(vel_msg)

def imageCallback(data):
  img = bridge.imgmsg_to_cv2(data, "bgr8")
  move_command = detectLine(img)
  moveTurtlebot(move_command)
  test_line = cv2.line(img,(CENTER_X - DETECT_LINE_LENGTH/2,DETECT_Y),(CENTER_X + DETECT_LINE_LENGTH/2,DETECT_Y),(255,0,0),3)
  cv2.imshow("DetectLine",test_line)
  cv2.waitKey(1)


def lidarCallback(data):
  move_command = detectLIDAR(data)
  moveTurtlebot(move_command)

def listener():
  rospy.init_node('line_detector', anonymous=True)
  rospy.Subscriber("/image_raw", Image, imageCallback)
  # rospy.Subscriber("/scan", LaserScan, lidarCallback)
  rospy.spin()

if __name__ == '__main__':
    listener()
