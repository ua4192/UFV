#!/bin/bash
#############################################################################################
# AD Ubuntu integration:
#############################################################################################

sudo apt-get update
sudo apt-get install net-tools -y
sudo apt-get install sssd-ad sssd-tools realmd adcli nfs-common -y

#############################################################################################
# DNS config:
#############################################################################################
sudo cat << EOF > /etc/resolv.conf
nameserver 192.168.140.253
nameserver 127.0.0.53
options edns0 trust-ad
search .
EOF

#############################################################################################
# NTP config:
#############################################################################################
echo "Configurando NTP..."
sudo cat << EOF >  /etc/systemd/timesyncd.conf
[Time]
NTP=ufvdc1.ufv.org
FallbackNTP=0.pool.ntp.org 1.pool.ntp.org
EOF

sudo timedatectl set-timezone Europe/Madrid
sudo systemctl restart systemd-timesyncd
sudo systemctl enable systemd-timesyncd --now
timedatectl show-timesync --all
timedatectl status

#############################################################################################
# AD config:
#############################################################################################
sudo realm -v discover ufv.org
sudo realm join --user=Integrator UFV.org
sudo pam-auth-update --enable mkhomedir
sudo systemctl restart sssd
sudo systemctl restart realmd

id "Integrator@UFV.org"
getent passwd "Integrator@UFV.org"
