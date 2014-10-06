#!/bin/sh

# Ruby 2.1, Rubygems & Bundler
sudo apt-get update
sudo apt-get install rvm
rvm use 2.1
rvm install 2.1
gem install bundler

# MongoDB
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update
sudo apt-get install -y mongodb-org
# sudo service mongod stop
# sudo mv -fv /etc/init/mongod.conf /etc/init/mongod.conf.override
