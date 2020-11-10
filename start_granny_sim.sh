tmux kill-session
sleep 1
tmux new-session -d
tmux set -g mouse on
tmux split-window -h
tmux select-pane -R
tmux split-window -h
tmux select-pane -R
tmux split-window -h
tmux select-pane -R
tmux select-pane -t 0
tmux send "source ~/.bashrc" C-m
tmux send "cd ~/Desktop/TurtleBotPNU/" C-m
tmux send "roslaunch pnu_tb3_launch tb3_service_groundtruth.launch" C-m
tmux select-pane -t 1
tmux send "source ~/.bashrc" C-m
tmux send "cd ~/Desktop/TurtleBotPNU" C-m
tmux send "luajit Run/rosio_wizard.lua 2" C-m
tmux select-pane -t 3
tmux send "source ~/.bashrc" C-m
tmux send "cd ~/Desktop/TurtleBotPNU/" C-m
tmux send "webots Webots/worlds/2020_Home_Service_Challenge.wbt" C-m
tmux select-layout even-horizontal
tmux attach-session -d
