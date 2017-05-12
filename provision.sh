#!/bin/bash
##
## NOTE THAT ALL RELEVANT DATA IS STORED ON INSTANCE-STORE AND THUS LOST AFTER ON SHUTDOWN. MAKE
## SURE TO BACKUP YOUR DATA BEFORE YOU SHUTDOWN THE INSTANCE (YOUR DATA SHOULD SURVIVE A REBOOT).
##
## http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ApiReference-cmd-RunInstances.html
## https://aws.amazon.com/amazon-linux-ami/
## http://docs.aws.amazon.com/cli/latest/userguide/cli-ec2-launch.html
##
## http://cloud-images.ubuntu.com/locator/ec2/ (eu-west-1, amd64, hvm:instance-store)
##
## https://aws.amazon.com/ec2/instance-types/
## x1.32xlarge (xvdb & xvdc)
## x1.16xlarge (xvdb only!!!)
## r3.8xlarge (xvdb & xvdc)
## c3.8xlarge (xvdb & xvdc, 32 cores, 60gb ram)
## m3.2xlarge (xvdb & xvdc)
##
## eu-west:
##
## ec2-run-instances -m --key foo@bar.nxdomain --instance-type m3.2xlarge --user-data-file provision.sh ami-12dcd974
## ec2-run-instances -m --key for@bar.nxdomain --instance-type c3.8xlarge --user-data-file provision.sh ami-12dcd974
## ec2-run-instances -m --key foo@bar.nxdomain --instance-type r3.8xlarge --user-data-file provision.sh ami-12dcd974
##
## TODO --tenancy dedicated (defined at VPC level in Webfrontend, VPC created manually)
## ec2-run-instances -m --key foo@bar.nxdomain --instance-type x1.16xlarge --user-data-file provision.sh -s subnet-287c8b4c ami-12dcd974
## ec2-run-instances -m --key foo@bar.nxdomain --instance-type x1.32xlarge --user-data-file provision.sh -s subnet-287c8b4c ami-12dcd974
##

## Exit if this script has run before (e.g. booting up a custom EC2 AMI)
## The decision is simply based on the existence of the markus user account
id markus && exit 0

## This is an unattended install. Nobody is there to press any buttons
export DEBIAN_FRONTEND=noninteractive

## create user markus and setup public key
useradd --home /home/markus -m markus -s /bin/bash -G admin,sudo

## combine ephemeral disks into level 0 raid and format
apt-get --no-install-recommends install mdadm e2fsprogs -y

mountpoint -q /mnt && umount /mnt
if [ -e "/dev/xvdc" ]; then
  /usr/bin/yes|/sbin/mdadm --create --force --auto=yes /dev/md0 --level=0 --raid-devices=2 --assume-clean --name=foo /dev/xvdb /dev/xvdc
  /sbin/mdadm --detail --scan >> /etc/mdadm/mdadm.conf
  sed -i '\?^/dev/xvdb?d' /etc/fstab
  echo "/dev/md127 /mnt ext4 defaults 0 0" >> /etc/fstab
  /sbin/mkfs.ext4 -O ^has_journal /dev/md0
  mount /dev/md0 /mnt
else
  /sbin/mkfs.ext4 -O ^has_journal /dev/xvdb
  mount /dev/xvdb /mnt
fi
chmod 777 /mnt

## Tune the system in favor of TLC
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo 0 > /proc/sys/kernel/numa_balancing

## Create user-writeable work directory on ephemeral/instance storage
mkdir /mnt/markus
chown markus:markus /mnt/markus

# ssh
mkdir /home/markus/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDaFesWicuMjw2s9+4rl36IP781nZ07Vasir5nybvVmmN2wDV1sTcv0iS8VgH54qxmCtV2zQiub0gMq4kHnnTVMKdlMGOyhbvC4X3UVmhJFrD+8UG5bmsbEVXjmgh7Y1oEoldrIf4DlnnHcetdSwuMvV5xqI3iZ+8xg0j9pnN8a9xWj5dUv/rkq2Z5So7AYd+aVCU6uETh8N9fsMZSo/Eu9A+vYvwWhsysY0S8m7wr9zkd71fjc1mTPlAsZGtzACRswrk3S2NLdCd7NNOU1jT5QVffc7poTeCngMFrXjmtUPZZQxOfA6oDq0rSCep+TgjVa2KQAypMDQTjKfkwjaklL foo@bar.nxdomain" > /home/markus/.ssh/authorized_keys

## Fix permission because steps are executed by root
chown -R markus:markus /home/markus
echo "markus ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

## x2go repository
add-apt-repository ppa:x2go/stable -y

## TLA+Toolbox
echo "deb https://tla.msr-inria.inria.fr/tlatoolbox/ci/toolboxUpdate/ ./" > /etc/apt/sources.list.d/tlaplus.list
wget -qO - https://tla.msr-inria.inria.fr/jenkins.pub | sudo apt-key add -

## Oracle Java 8
add-apt-repository ppa:webupd8team/java -y
## Accept license before apt (dpkg) tries to present it to us (which fails due to 'noninteractive' mode below)
## see http://stackoverflow.com/a/19391042
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections

## Update package index and install basic packages needed
apt-get update
apt-get upgrade -y

apt-get install --no-install-recommends mate-desktop-environment-extras x2gomatebindings x2goserver x2goserver-xsession x2goserver-extensions -y
apt-get install --no-install-recommends oracle-java8-installer oracle-java8-set-default -y
apt-get install --no-install-recommends mc zip unzip git firefox htop numactl ant maven -y
apt-get install --no-install-recommends linux-tools-common linux-tools-generic -y
apt-get install --no-install-recommends build-essential bison gcc-4.8 -y
apt-get install --no-install-recommends postfix heirloom-mailx -y
apt-get install --no-install-recommends tla+toolbox -y
echo "markus: markus.kuppe@gmail.com" >> /etc/aliases
newaliases

## Generate common locales. Newer SSH pass the client's locale to the server causing a warning on each command invocation if the locale is missing
locale-gen de en fr

## Clone git repo for eclipse to pick it up easily
sudo -u markus /usr/bin/git config --global user.email "tlaplus.net aT lemmster tod de"
sudo -u markus /usr/bin/git config --global user.name "Markus Alexander Kuppe"

## Clone git repository (let Oomph handle it)
#sudo -u markus /usr/bin/git remote add lemmy-github https://github.com/lemmy/tlaplus.git

## Download Eclipse IDE tools
sudo -u markus wget -P /mnt/markus http://ftp.heanet.ie/pub/eclipse/oomph/epp/neon/R1/eclipse-inst-linux64.tar.gz
sudo -u markus tar xvfz /mnt/markus/eclipse-inst-linux64.tar.gz -C /mnt/markus

## Scroll in screen sessions
## http://unix.stackexchange.com/a/40246
sudo -u markus echo "termcapinfo xterm* ti@:te@" > /home/markus/.screenrc

## Download SPIN model checker used in comparison
sudo -u markus wget -P /mnt/markus http://spinroot.com/spin/Src/spin646.tar.gz
sudo -u markus tar xvfz /mnt/markus/spin646.tar.gz -C /mnt/markus

## Remove default user
userdel ubuntu

## Lastly, mark the completion of this script
mkdir /tmp/data-file-init-complete/
