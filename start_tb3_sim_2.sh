tmux kill-session
sleep 1
tmux new-session -d
tmux set -g mouse on
tmux split-window -h
tmux select-pane -R
tmux split-window -h
tmux select-pane -R
# tmux split-window -h
# tmux select-pane -R
tmux select-pane -t 0
tmux send "source ~/.bashrc" C-m
tmux send "cd ~/Desktop/TB3PNUOpen/" C-m
tmux send "roslaunch pnu_tb3open_launch turtlebot3_sim.launch" C-m
tmux select-pane -t 1
tmux send "source ~/.bashrc" C-m
tmux send "cd ~/Desktop/TB3PNUOpen/" C-m
tmux send "luajit Run/rosio_wizard.lua 0" C-m
tmux select-pane -t 2

tmux send "source ~/.bashrc" C-m
tmux send "cd ~/Desktop/TB3PNUOpen/" C-m
tmux send "webots Webots/worlds/TB3map2.wbt" C-m
tmux select-layout even-horizontal
tmux attach-session -d
