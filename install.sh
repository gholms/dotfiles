#!/bin/sh

install -d -m 0700 ~/.ssh/sockets
install -d -m 0700 ~/tmp

# Have to pattern match because * won't find dotfiles
rsync -lpqrt dotfiles/ ~/

crontab crontab
