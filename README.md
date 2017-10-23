# SLIK Installer
This is a bash script for bootstrapping a SLIK stack. This is the fastest way to deploy a fully working stack in your environment and is intended to fully install and configure your environment for use with minimal user input.

# Installation Results
Currently, this script will take your Red Hat 7 / CentOS 7 server and deploy a FreeIPA installation using the Katello salt forumla https://github.com/jdshewey/salt-formula-katello.

# Usage instructions

yum -y install wget
wget https://raw.githubusercontent.com/jdshewey/slik-installer/master/slik.sh
chmod +x slik.sh

#System Requirements

 - At least 8 GB of RAM is required for the installer to work properly which is an upstream dependancy on The Foreman installer which requires this amount of RAM to install/operate properly. 
 - Katello recommends at least 250 GB disk space - 50 for mongodb storage and 200 for RPM storage.

# What is a SLIK stack?
SLIK stands for [Saltstack](https://saltstack.com/), [Linux](https://www.centos.org), [IPA](https://www.freeipa.org/page/Main_Page) and [Katello](https://puppet.com/). This is essentially a [Red Hat Satellite 6](https://access.redhat.com/products/red-hat-satellite) + [FreeIPA](https://www.freeipa.org/page/Main_Page) user (LDAP and Kerberos) and DNS management system deployment. FreeIPA and Satellite 6 really fit together like a hand in a glove, but oddly, FreeIPA is not included as part of the Satellite 6 stack. Furthermore, Satellite 6 is really based on Katello. The Katello project brings together the [Candlepin](http://www.candlepinproject.org/) license management system and [Pulp](http://pulpproject.org/) backends with heavy [Kickstart](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Installation_Guide/sect-kickstart-howto.html) server deployment script integration as well as loose [Docker](https://www.docker.com/) container and Puppet integration/management. Katello is then skinned with [The Foreman](https://www.theforeman.org/) front end. More recently, it appears that Katello is merging into The Foremen having moved all of the Katello docs to their site. This means that the Katello stack (minus Candlepin license management) is available for all CentOS servers and that your CentOS server can manage all of your RedHat servers (including licensing) or vice-versa. Katello also integrates with numerous virtualization systems and cloud providers including VMWare, OpenStack, Amazon Web Services, [Google's cloud](https://cloud.google.com) platform, [Rackspace](https://www.rackspace.com) and [others](https://theforeman.org/manuals/latest/index.html#5.2ComputeResources). This helps to prevent you from being tied to a specific cloud by using, for example, Amazon's automated deployment and continuous deployment tools. You can freely move between clouds or your own environment.  This script seeks to: 

- Streamline, unify and abstract the setup for all of these softwares by cutting down on repetitive information needed by the two installers (Katello and IPA)
- Unify two significant pieces of the full stack under a single umbrella
- Make installation easier by accounting for known bugs and installation challenges and avoiding these pitfalls altogether
