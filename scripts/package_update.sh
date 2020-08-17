#!/bin/bash

sudo cat /dev/null

echo "============================="
echo "==========  START  =========="
echo "============================="

echo "------------------------------ brew update ------------------------------"
brew update

echo "------------------------------ brew upgrade ------------------------------"
brew upgrade

echo "------------------------------ pip install --upgrade pip ------------------------------"
pip install --upgrade pip

echo "------------------------------ pip-review --auto ------------------------------"
pip-review --auto --use-feature=2020-resolver
#echo "------------------------------ pip install -U *** ------------------------------"
#pip freeze --local | grep -v '^\-e' | cut -d = -f 1 | xargs pip install -U --use-feature=2020-resolver

echo "------------------------------ sudo gem update ------------------------------"
sudo gem update

echo "============================"
echo "==========  INFO  =========="
echo "============================"

echo "------------------------------ brew cask upgrade --dry-run `brew cask list` ------------------------------"
brew cask upgrade --dry-run `brew cask list`

echo "------------------------------ brew cleanup --dry-run ------------------------------"
brew cleanup --dry-run

echo "==========================="
echo "==========  END  =========="
echo "==========================="

