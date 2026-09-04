#!/bin/sh

install -d -m 0700 ~/.ssh/sockets
install -d -m 0700 ~/tmp

test -e ~/.gitconfig || cp -p dotfiles/.gitconfig ~/.gitconfig
rm -f ~/.pythonrc
# Have to pattern match because * won't find dotfiles
rsync -lpqrt --exclude .gitconfig dotfiles/ ~/

crontab crontab
