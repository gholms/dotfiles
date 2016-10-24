#!/bin/sh

install -d -m 0700 ~/.ssh/sockets
install -d -m 0700 ~/tmp

# Combine a bunch of ssh config files
# OpenSSH 7.3 adds an "Include" directive for this, so I can start
# using that when I'm done with RHEL 7.
chmod 0700 dotfiles/.ssh
dotfiles/.ssh/generate-config

# Have to pattern match because * won't find dotfiles
rsync -lpqrt dotfiles/ ~/

crontab crontab
