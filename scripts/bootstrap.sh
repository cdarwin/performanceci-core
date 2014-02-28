#!/bin/sh

set -e

apt-get update
apt-get upgrade -y
apt-get install -y git-core build-essential ruby2.0 ruby2.0-dev libsqlite3-dev bundler redis-server
# Docker host
# http://askubuntu.com/questions/350657/lxc-start-failed-to-spawn
# apt-get install -y cgroup-lite
# sudo cgroups-mount
