#!/bin/bash
rm -rf /tmp/.X*
service dbus start
service pulseaudio start
su - vncuser -c "vncserver :1 -geometry 1280x720 -depth 24 -localhost no"
service xrdp start
sleep infinity
