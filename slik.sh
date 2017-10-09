#!/bin/bash

if [ "$( cat /etc/*release | grep VERSION_ID | awk -F\" '{print $2}' | awk -F. '{print $1}' )" -eq "7" ]; then
    if [ "$( cat /etc/*release | grep ^NAME= | awk -F\" '{print $2}' )" != "CentOS Linux" ]; then
	echo "This does not appear to be a CentOS installation - it must be Red Hat. That's OK, but be forwarned that Red Hat installations may get converted to CentOS - proceed at your own risk."
    fi
	#set hostname
	bash -c "exit 1"
	while [ "$?" -gt "0" ]; do
		echo "Enter a desired name for this host [slik01.example.com]:"
		read HOST
		if [ -z "$HOST" ]; then
			HOST="slik01.example.com"
		fi
		echo $HOST | egrep "^[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+$" >> /dev/null
		if [ "$?" -gt "0" ]; then
			echo "Invalid input\n"
		fi
	done
	#If this is an aws instance, turn off hostname preservation so host can be renamed
	if [ -f "/etc/cloud/cloud.cfg" ]; then
		sed -i -e "/^preserve_hostname:.*$/d" /etc/cloud/cloud.cfg
		echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg
	fi
	hostnamectl set-hostname $HOST
	yum -y install https://repo.saltstack.com/yum/redhat/salt-repo-latest-2.el7.noarch.rpm
	yum -y install salt-master salt-minion git
	mkdir -p /srv/pillar /srv/salt
	echo "auto_accept: True" > /etc/salt/master
	echo "master: $(hostname)
schedule:
  highstate:
    function: state.highstate
    minutes: 60" > /etc/salt/minion
	systemctl enable salt-master
	systemctl enable salt-minion
	cd /srv/salt/
	git clone https://github.com/jdshewey/salt-formula-katello.git katello
	cp /srv/salt/katello/examples/katello.sls /srv/pillar
	echo "base:
  $(hostname):
    - katello" > /srv/salt/top.sls
	echo "base:
  $(hostname):
    - katello" > /srv/pillar/top.sls
	echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<service>
  <short>SaltStack</short>
  <description>SaltStack is a configuration management system for automated management of many minion endpoints.</description>
  <port protocol=\"tcp\" port=\"4505-4506\"/>
</service>" > /usr/lib/firewalld/services/saltstack.xml
	firewall-cmd --reload
	firewall-cmd --zone=public --permanent --add-service=saltstack
	setenforce 0
	sed -i -e 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/sysconfig/selinux 
	sed -i -e 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config 
	systemctl start salt-master
	systemctl start salt-minion
	bash -c "exit 1"
	while [ "$?" -gt "0" ]; do
		echo "Enter a password to be used for this deployment [random]:"
		read PASSWORD
		if [ -z "$PASSWORD" ]; then
			PASSWORD="$( (< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12) )"
			echo "Your password is: $PASSWORD
Write it down, then press any key to continue."
			read -n 1 -s -p ""
		fi
		echo $PASSWORD | grep -P "^(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,32}$" >> /dev/null
		if [ "$?" -gt "0" ]; then
			echo "Weak password (or too long). Try a stronger one.\n"
			bash -c "exit 1"
		fi
	done
	echo "Continuing..."
	sed -i -e "s/^    admin_pass: .*/    admin_pass: $PASSWORD/" /srv/pillar/katello.sls
	sleep 5
	salt $(hostname) state.apply
else
	echo "This installer is only supported on CentOS/RedHat 7."
fi
