#/bin/bash
rpm -qa |  sed -e "s/-[-.0-9]\+[.sc1]*\.el7[_0-9]*\..*//g" > /tmp/current_rpmlist
yum remove $( diff /tmp/current_rpmlist /etc/slik/preinstall_rpmlist | grep "<" | awk '{print $2}' | sed -e "s/-[-.0-9]\+[.sc1]*\.el7[_0-9]*\..*//g"  | egrep -v "\.x86_64$|\.noarch$" | tr '\n' ' ' ) python-isodate ipxe-bootimgs libstemmer
rm -f /tmp/current_rpmlist
if [ $? != 0 ]; then
	rm -rf /etc/slik
fi

# TODO:
# Prompt user to see if they want to delete:
#/etc/foreman-installer/
#/etc/httpd/conf.d/pulp.conf
#/etc/salt
