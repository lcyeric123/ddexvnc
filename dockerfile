FROM debian:bookworm
ENV DEBIAN_FRONTEND=noninteractive

RUN echo "deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list
RUN echo "deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list
RUN echo "deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list

RUN apt update && apt install -y locales apt-utils
RUN echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
ENV LANG=zh_CN.UTF-8
ENV LC_ALL=zh_CN.UTF-8

RUN dpkg --add-architecture i386
RUN apt update && apt install -y wget gnupg2 apt-transport-https ca-certificates software-properties-common

RUN wget -nc https://dl.winehq.org/wine-builds/winehq.key
RUN gpg --output /usr/share/keyrings/winehq.gpg --dearmor winehq.key
RUN echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/winehq.gpg] https://dl.winehq.org/wine-builds/debian/ bookworm main" > /etc/apt/sources.list.d/winehq.list

RUN apt update && apt install -y \
xvfb x11vnc novnc websockify \
cinnamon cinnamon-core cinnamon-settings-daemon fonts-wqy-microhei \
dbus-x11 sudo curl wget nano net-tools policykit-1 \
pulseaudio pulseaudio-utils firefox-esr iproute2 libbpf-dev \
gcc make git bpftool xorg winehq-stable && \
apt clean && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash vncuser && echo "vncuser:123456" | chpasswd && usermod -aG sudo vncuser
RUN echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config
RUN echo "needs_root_rights=yes" >> /etc/X11/Xwrapper.config
RUN dbus-uuidgen --ensure

# 直接写入加密密码，绕过x11vnc交互式报错
RUN mkdir -p /home/vncuser/.vnc
RUN echo Ulglj+Fj7dRcA > /home/vncuser/.vnc/passwd
RUN chown -R vncuser:vncuser /home/vncuser
RUN chmod 600 /home/vncuser/.vnc/passwd

EXPOSE 5900 6080
COPY web-start.sh /web-start.sh
RUN chmod +x /web-start.sh
CMD ["/web-start.sh"]
