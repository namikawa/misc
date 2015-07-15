#!/bin/bash

sudo cat /dev/null

echo "========== START =========="

echo "------------------------------ port -d selfupdate ------------------------------"
sudo port -d selfupdate

echo "------------------------------ port upgrade outdated ------------------------------"
sudo port upgrade outdated

echo "------------------------------ port -u uninstall ------------------------------"
sudo port -u uninstall

echo "------------------------------ port clean --all installed ------------------------------"
sudo port clean --all installed

echo "------------------------------ pip-review --auto  ------------------------------"
sudo pip-review --auto

echo "------------------------------ gem update  ------------------------------"
sudo gem update

echo "========== END =========="

