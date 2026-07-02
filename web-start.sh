#!/bin/bash
rm -rf /tmp/.X*
rm -rf /tmp/.X11-unix/*
service dbus start
service pulseaudio start

Xvfb :99 -screen 0 1280x720x24 -ac +extension GLX &
export DISPLAY=:99
sleep 2

su - vncuser -c "export DISPLAY=:99; cinnamon-session" &
sleep 4

# 前台常驻x11vnc，永远不会退出
su - vncuser -c "x11vnc -display :99 -passwd ~/.vnc/passwd -forever -shared -noxdamage -rfbport 5900 -rfbwait 30000" &
sleep 2

# 核心修复：调用noVNC自带的websockify，抛弃系统坏的websockify
python3 /usr/share/novnc/websockify.py --web=/usr/share/novnc 6080 127.0.0.1:5900

sleep infinity
