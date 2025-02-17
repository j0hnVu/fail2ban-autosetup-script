#!/bin/bash

# apt update
echo "apt update..."
sudo apt update > /dev/null 2>&1
echo "Installing Fail2Ban"
sudo apt install fail2ban -y > /dev/null 2>&1
sudo touch /etc/fail2ban/jail.local

# get Max Retry, Ban time, SSH Port
read -p "Using default? (y/n) " default_opt
if [ "$default_opt" = "y" ]; then
	max_retry="3"
	ban_time="3600"
	port="ssh"
else
	read -p "Max Retry? " max_retry
	read -p "Ban time? " ban_time
	read -p "SSH Port? " port
fi

# config 
echo "Generating jail.local config..."
sudo bash -c "cat > /etc/fail2ban/jail.local <<EOF
[sshd]

enabled  = true
port     = ${port}
filter   = sshd
logpath  = /var/log/auth.log
maxretry = ${max_retry}
bantime  = ${ban_time}
EOF"

# Bring the service up
sudo service fail2ban enable
sudo service fail2ban start
echo "Done!"
sudo service fail2ban status


# Report Script
read -p "Specifying script path? (def = $HOME/script)" opt
if [ $opt = "def" ]; then
	$shpath = $HOME/script
else
	read shpath
fi

mkdir -p $shpath
cd $shpath

echo '#!/bin/bash
sudo bash -c "cat > $shpath/report.txt <<EOF
Fail2Ban log:
$(fail2ban-client status sshd | grep -E "Currently banned|Total banned|Banned IP list")

# Summary:
# Total Failed: $(journalctl -u ssh.service | egrep -c "Connection closed|Connection reset|drop connection|Timeout before authentication")
# Total failed root login: $(journalctl -u ssh.service | grep -c "authenticating user root")

Updated: $(date)

EOF"' > $shpath/f2b_report.sh

chmod +x "$shpath"/f2b_report.sh

(crontab -l 2>/dev/null; echo "0 * * * * $shpath/f2b_report.sh") | crontab -

