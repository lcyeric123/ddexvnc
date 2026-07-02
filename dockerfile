FROM debian:bullseye
ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386

# 深度桌面密钥与源
RUN mkdir -p /tmp && cd /tmp && \
wget https://packages.deepin.com/deepin/pool/main/d/deepin-keyring/deepin-keyring_2021.07.27_all.deb && \
dpkg -i deepin-keyring_2021.07.27_all.deb && rm -rf /tmp/*
RUN echo "deb https://packages.deepin.com/deepin stable main contrib non-free" >> /etc/apt/sources.list

# 安装：DDE桌面 + TigerVNC(Xvnc) + Wine + XDP编译组件 + dbus音频
RUN apt update && apt install -y \
tigervnc-standalone-server \
dde dde-control-center dde-file-manager dde-terminal \
dbus-x11 sudo curl wget nano net-tools policykit-1 \
pulseaudio pulseaudio-utils firefox-esr iproute2 libbpf-dev \
gcc make git bpftool locales xorg xrdp winehq-stable && \
apt clean && rm -rf /var/lib/apt/lists/*

# 系统中文环境
RUN locale-gen zh_CN.UTF-8 && update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8

# 创建用户
RUN useradd -m -s /bin/bash vncuser && echo "vncuser:123456" | chpasswd && usermod -aG sudo vncuser
RUN echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config
RUN echo "needs_root_rights=yes" >> /etc/X11/Xwrapper.config
RUN dbus-uuidgen --ensure-fixed

# 写入VNC启动配置文件
USER vncuser
RUN mkdir -p ~/.vnc && echo 123456 | vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd
RUN echo "#!/bin/bash" > ~/.vnc/xstartup && \
echo "export DBUS_SESSION_BUS_ADDRESS=\`dbus-daemon --session --fork --print-address\`" >> ~/.vnc/xstartup && \
echo "startdde" >> ~/.vnc/xstartup && chmod +x ~/.vnc/xstartup
USER root

# RDP反向代理VNC（3389进来自动接入5901 VNC桌面）
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini
RUN sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini
RUN echo "vnc://127.0.0.1:5901" > /etc/xrdp/startwm.sh && chmod +x /etc/xrdp/startwm.sh

EXPOSE 5901 3389
COPY start.sh /start.sh
RUN chmod +x /start.sh
CMD ["/start.sh"]
