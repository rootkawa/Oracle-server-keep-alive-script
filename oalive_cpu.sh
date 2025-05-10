#!/bin/bash
_green() { echo -e "\033[32m\033[01m$@\033[0m"; }

# Download and set up CPU limiter script
curl -L https://raw.githubusercontent.com/rootkawa/Oracle-server-keep-alive-script/refs/heads/main/cpu-limit.sh -o cpu-limit.sh && chmod +x cpu-limit.sh
mv cpu-limit.sh /usr/local/bin/cpu-limit.sh
chmod +x /usr/local/bin/cpu-limit.sh

# Download and set up CPU limiter service
curl -L https://raw.githubusercontent.com/rootkawa/Oracle-server-keep-alive-script/refs/heads/main/cpu-limit.service -o cpu-limit.service && chmod +x cpu-limit.service
mv cpu-limit.service /etc/systemd/system/cpu-limit.service

# Download and set up CPU limiter timer
curl -L https://raw.githubusercontent.com/rootkawa/Oracle-server-keep-alive-script/refs/heads/main/cpu-limit.timer -o cpu-limit.timer && chmod +x cpu-limit.timer
mv cpu-limit.timer /etc/systemd/system/cpu-limit.timer

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

# Enable and start the timer
systemctl daemon-reload
systemctl enable cpu-limit.timer
if systemctl start cpu-limit.timer; then
  _green "CPU限制安装成功 脚本路径: /usr/local/bin/cpu-limit.sh"
else
  restorecon /etc/systemd/system/cpu-limit.timer
  systemctl enable cpu-limit.timer
  systemctl start cpu-limit.timer
  _green "CPU限制安装成功 脚本路径: /usr/local/bin/cpu-limit.sh"
fi
_green "The CPU limit script has been installed at /usr/local/bin/cpu-limit.sh"

# Show status of timer and service
echo -e "\nTimer Status:"
systemctl status cpu-limit.timer
echo -e "\nService Status:"
systemctl status cpu-limit.service