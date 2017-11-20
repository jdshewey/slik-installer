#/bin/bash
systemctl stop salt-minion
echo "
  * The salt master and minion services and packages will be removed." 
katello-remove
if [ $? == 0 ]; then
        yum remove subscription-manager salt-repo-latest-2.el7.noarch
	cp -rp /etc/slik/rpm-sources-backup/* /etc/yum.repos.d/
	rm -rf /etc/salt
	rm -rf /etc/slik
	rm -rf /srv/pillar
	rm -rf /srv/salt
fi
