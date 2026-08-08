#!/usr/bin/env bash

INSTALL_FOLDER=".install"

curl -L https://bit.ly/n-install | bash -s -- -y 
sed -i 's|\$HOME/n|\$HOME/.install/n|g' "~/.bashrc"

mv "~/n" "~/$FOLDER_INSTALL/"
