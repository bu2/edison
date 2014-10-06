#!/bin/sh

rvm use 2.1
rvm install 2.1
gem install bundler
bundle install
# ./mongo.sh
