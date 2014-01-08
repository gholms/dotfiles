#!/bin/sh

install -d -m 0700 ~/.ssh/sockets
install -d -m 0700 ~/tmp

# Combine a bunch of ssh config files
# Upstream RFE:  https://bugzilla.mindrot.org/show_bug.cgi?id=1585
chmod 0700 dotfiles/.ssh
dotfiles/.ssh/generate-config

# Have to pattern match because * won't find dotfiles
rsync -lpqrt dotfiles/ ~/

crontab crontab
