#!/bin/bash

# apt update
echo "apt update..."
sudo apt update > /dev/null
echo "Installing Fail2Ban"
sudo apt install fail2ban -y > /dev/null 2>&1
sudo touch /etc/fail2ban/jail.local
echo "Using default? (y/n) "
read default_opt

if [ "$default_opt" = "y" ]; then
	max_retry="3"
	ban_time="3600"
else
	echo "Max Retry?"
	read max_retry
	echo "Ban time?"
	read ban_time
fi

echo "Generating jail.local config..."
sudo bash -c "cat > /etc/fail2ban/jail.local <<EOF
[sshd]

enabled  = true
filter   = sshd
action   = iptables[name=SSH, port=ssh, protocol=tcp]
logpath  = /var/log/auth.log
maxretry = ${max_retry}
bantime  = ${ban_time}
EOF"

sudo service fail2ban start
echo "Done!"
sudo service fail2ban status


# Report Script
echo "Specifying script path? (def = $HOME/bin)"
read opt
if [ $opt = "def" ]; then
	$shpath = $HOME/bin
else
	read shpath
fi

if [ ! -d $shpath ]; then
	mkdir $shpath
fi

cd $shpath

echo '#!/bin/bash
sudo bash -c "cat > $HOME/report.txt <<EOF
Fail2Ban log:
$(fail2ban-client status sshd | grep -E "Currently banned|Total banned|Banned IP list")

Summary:
Total Failed: $(journalctl -u ssh.service | egrep -c "Connection closed|Connection reset|drop connection|Timeout before authentication")
Total failed root login: $(journalctl -u ssh.service | grep -c "authenticating user root")

Updated: $(date)

hehe

EOF"' > $shpath/ssh-report.sh

(crontab -l 2>/dev/null; echo "0 * * * * $HOME/ssh-report.sh") | crontab -

