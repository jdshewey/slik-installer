#/bin/bash
katello-remove
if [ $? != 0 ]; then
	yum -y remove salt
	if [ $? != 0 ]; then
		rm -rf /etc/slik
	fi
	cp -rp /etc/slik/rpm-sources-backup/* /etc/yum.repos.d/
	rm -rf /etc/salt
	rm -rf /etc/slik
	rm -rf /srv/pillar
	rm -rf /srv/salt
fi
