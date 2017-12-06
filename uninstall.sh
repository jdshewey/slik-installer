#/bin/bash
systemctl stop salt-minion
echo "
  * The salt master and minion services and packages will be removed." 
katello-remove
if [ $? == 0 ]; then
        yum -y remove subscription-manager salt-repo-latest-2.el7.noarch
	rm -rf /etc/yum.reps.d/*
	cp -rp /etc/slik/rpm-sources-backup/* /etc/yum.repos.d/
	rm -rf /var/lib/pulp
	rm -rf /var/lib/mongodb
	rm -rf /etc/salt
	rm -rf /etc/slik
        rm -rf /var/www/html/pub/*
	rm -rf /srv/pillar
	rm -rf /srv/salt
fi
