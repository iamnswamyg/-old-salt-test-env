#!/bin/bash


cat /lxd/saltconfig/master.local.conf
cp /lxd/saltconfig/master.local.conf /etc/salt/master.d/local.conf
systemctl restart salt-master

cat /lxd/saltconfig/minion.local.conf
cp /lxd/saltconfig/minion.local.conf /etc/salt/minion.d/local.conf
systemctl restart salt-minion
