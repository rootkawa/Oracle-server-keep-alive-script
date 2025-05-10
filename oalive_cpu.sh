#!/bin/bash
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }

# Download and set up CPU limiter script
curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/cpu-limit.sh -o cpu-limit.sh && chmod +x cpu-limit.sh
mv cpu-limit.sh /usr/local/bin/cpu-limit.sh
chmod +x /usr/local/bin/cpu-limit.sh

# Download and set up CPU limiter service
curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/cpu-limit.service -o cpu-limit.service && chmod +x cpu-limit.service
mv cpu-limit.service /etc/systemd/system/cpu-limit.service

# Calculate CPU limit based on core count
line_number=7
total_cores=0
if [ -f "/proc/cpuinfo" ]; then
  total_cores=$(grep -c ^processor /proc/cpuinfo)
else
  total_cores=$(nproc)
fi

if [ "$total_cores" == "2" ] || [ "$total_cores" == "3" ] || [ "$total_cores" == "4" ]; then
  cpu_limit=$(echo "$total_cores * 20" | bc)
else
  cpu_limit=25
fi

# Configure CPU limit in service file
sed -i "${line_number}a CPUQuota=${cpu_limit}%" /etc/systemd/system/cpu-limit.service

# Enable and start the service
systemctl daemon-reload
systemctl enable cpu-limit.service
if systemctl start cpu-limit.service; then
  _green "CPU限制安装成功 脚本路径: /usr/local/bin/cpu-limit.sh"
else
  restorecon /etc/systemd/system/cpu-limit.service
  systemctl enable cpu-limit.service
  systemctl start cpu-limit.service
  _green "CPU限制安装成功 脚本路径: /usr/local/bin/cpu-limit.sh"
fi
_green "The CPU limit script has been installed at /usr/local/bin/cpu-limit.sh"