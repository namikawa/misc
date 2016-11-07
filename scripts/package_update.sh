#!/bin/bash

sudo cat /dev/null

echo "========== START =========="

echo "------------------------------ brew update ------------------------------"
brew update

echo "------------------------------ brew upgrade ------------------------------"
brew upgrade

echo "------------------------------ pip install --upgrade pip ------------------------------"
pip install --upgrade pip

echo "------------------------------ pip-review --auto  ------------------------------"
pip-review --auto
#echo "------------------------------ pip install -U *** ------------------------------"
#pip freeze --local | grep -v '^\-e' | cut -d = -f 1 | xargs pip install -U

echo "------------------------------ gem update  ------------------------------"
sudo gem update

echo "========== END =========="

