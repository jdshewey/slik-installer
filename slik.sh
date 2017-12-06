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
	yum -y update
	mkdir -p /etc/slik/rpm-sources-backup
	cp -rp /etc/yum.repos.d/* /etc/slik/rpm-sources-backup
	yum -y install https://repo.saltstack.com/yum/redhat/salt-repo-latest-2.el7.noarch.rpm
	yum -y install salt-master salt-minion git
	rm -rf /etc/yum.repos.d/*
	mkdir -p /srv/pillar/katello/client /srv/salt
	echo "auto_accept: True" > /etc/salt/master
	echo "master: $(hostname)
schedule:
  highstate:
    function: state.highstate
    minutes: 60
use_superseded:
  - module.run" > /etc/salt/minion
	cd /srv/salt/
	git clone https://github.com/jdshewey/salt-formula-katello.git katello/
	cp /srv/salt/katello/examples/server/katello.sls /srv/pillar/katello/server.sls
#	ln -s /srv/salt/katello/examples/server/katello.sls /srv/pillar/katello/server.sls # should only be used by developers
	mkdir -p /srv/salt/_modules
	ln -s /srv/salt/katello/_modules/katello.py /srv/salt/_modules/katello.py
	echo "base:
  '* and not $(hostname)':
    - katello.client
  $(hostname):
    - katello.server
    - katello.client.katello" > /srv/salt/top.sls
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
	echo "current_tty: $( tty )" > /etc/salt/grains
	bash -c "exit 1"
	while [ "$?" -gt "0" ]; do
		echo "Enter a password to be used for this deployment [random]:"
		read PASSWORD
		if [ -z "$PASSWORD" ]; then
			bash -c "exit 1"
			while [ "$?" -gt "0" ]; do
				echo $PASSWORD | grep -P "^(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,32}$" >> /dev/null
				if [ "$?" -gt "0" ]; then
					PASSWORD="$( (< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12) )"
					bash -c "exit 1"
				fi
			done
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
	bash -c "exit 1"
	while [ "$?" -gt "0" ]; do
		echo "Enter the name of your organization [foobar]:"
		read ORGNAME
		if [ -z "$ORGNAME" ]; then
			ORGNAME="foobar"
		fi
	done
	sed -i -e "s/foobar/$ORGNAME/g" /srv/pillar/katello.sls 
	bash -c "exit 1"
	while [ "$?" -gt "0" ]; do
		echo "Enter the location of your headquarters [podunk]:"
		read LOCATION
		if [ -z "$LOCATION" ]; then
			LOCATION="podunk"
		fi
	done
	sed -i -e "s/podunk/$LOCATION/g" /srv/pillar/katello.sls 
	bash -c "exit 1"
	while [ "$?" -gt "0" ]; do
		echo "Do you wish to perform an advanced install? [n]:"
		read ADVANCED
		case $ADVANCED in
			y|Y) vi vim /srv/salt/katello/files/katello-answers.yaml
			   break 2
			   ;;
			n|N) break 2
			   ;;
			*)
			   if [ -z "$ADVANCED" ]; then
				break 3
			   fi 
			   ;;
		esac
		bash -c "exit 1"
	done

	systemctl start salt-master
	systemctl start salt-minion
	echo "Continuing... this installation may take a very long time - an hour or more."
	sed -i -e "s/^    admin_pass: .*/    admin_pass: $PASSWORD/" /srv/pillar/katello.sls
	if [ -d /etc/pki/katello ]; then
		rm -rf /etc/pki/katello
	fi
	if [ -d /root/ssl-build ]; then
		rm -rf /root/ssl-build
	fi
	if [ "$(grep $( hostname ) /etc/hosts | wc -l)" -lt "1" ]; then
#		echo "$( ip addr show | grep "inet " | awk '{print $2}' | awk -F '/' '{print $1}' | grep -v "127.0.0.1" | head -n 1 )    $( hostname )" >> /etc/hosts
		sed -i -e "s/127\.0\.0\.1\s\+/127\.0\.0\.1   $( hostname ) /g" /etc/hosts
	fi
	sleep 5
	salt-call state.apply
else
	echo "This installer is only supported on CentOS/RedHat 7."
fi
