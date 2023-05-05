#!/bin/bash


if ! dpkg-query -W curl >/dev/null 2>&1; then
  sudo apt install curl -y
fi

if ! dpkg-query -W salt-master >/dev/null 2>&1; then
  mkdir -p /var/lxd-provision
  cd /var/lxd-provision
  curl -L https://bootstrap.saltstack.com -o install_salt.sh

  # Install Master
  sudo sh install_salt.sh -P -M -N stable 3005.1
fi

if ! dpkg-query -W salt-minion >/dev/null 2>&1; then
  mkdir -p /var/lxd-provision
  cd /var/lxd-provision
  curl -L https://bootstrap.saltstack.com -o install_salt.sh
  sudo sh install_salt.sh -P stable 3005.1
fi

cat /lxd/saltconfig/master.local.conf
cp /lxd/saltconfig/master.local.conf /etc/salt/master.d/local.conf
systemctl restart salt-master

cat /lxd/saltconfig/minion.local.conf
cp /lxd/saltconfig/minion.local.conf /etc/salt/minion.d/local.conf
systemctl restart salt-minion
