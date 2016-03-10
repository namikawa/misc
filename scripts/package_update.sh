#!/bin/bash

sudo cat /dev/null

echo "========== START =========="

echo "------------------------------ brew update ------------------------------"
brew update

echo "------------------------------ brew upgrade ------------------------------"
brew upgrade

#echo "------------------------------ easy_install -U pip ------------------------------"
#sudo easy_install -U pip
echo "------------------------------ pip install --upgrade pip ------------------------------"
sudo -H pip install --upgrade pip

echo "------------------------------ pip-review --auto  ------------------------------"
sudo -H pip-review --auto
#echo "------------------------------ pip install -U *** ------------------------------"
#sudo -H pip freeze --local | grep -v '^\-e' | cut -d = -f 1 | egrep -v "pyobjc-framework-" | sudo -H xargs pip install -U

echo "------------------------------ gem update  ------------------------------"
sudo gem update

echo "========== END =========="

