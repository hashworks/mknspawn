#!/usr/bin/env bash
#
# mknspawn.sh - a systemd-nspawn wrapper written in shell
#
# Copyright (c) 2017 by Christian Rebischke <chris.rebischke@archlinux.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http: #www.gnu.org/licenses/
#
#======================================================================
# Author: Christian Rebischke
# Email : chris.rebischke@archlinux.org
# Github: www.github.com/Shibumi
#
#
#
# vim:set et sw=4 ts=4 tw=72:
#

set -e

if [ "$(id -u)" != "0" ]; then
    echo "[+] You need sudo.."
    exit 1
fi

if [ "$#" -eq 0 ]; then
    echo "[!] mknspawn <containername> <distribution> <release>"
    exit 2
fi

CONTAINER_NAME="$1"
DISTRIBUTION="$2"
RELEASE="$3"
MACHINED_DIR="/var/lib/machines/"
SSH_KEY="/home/chris/.ssh/tuclausthal.pub"


case $DISTRIBUTION in
    "ubuntu")
        echo "[+] Bootstrapping ubuntu/$RELEASE"
         debootstrap --include dbus,vim,less,tmux,openssl,openssh-server,python "$RELEASE" "$MACHINED_DIR$CONTAINER_NAME" http://archive.ubuntu.com/ubuntu/ > /dev/null
         echo "[+] Finished Bootstrapping"
         ;;

    "debian")
        echo "[+] Bootstrapping debian/$RELEASE"
         debootstrap --include dbus,vim,less,tmux,openssl,openssh-server,python "$RELEASE" "$MACHINED_DIR$CONTAINER_NAME" > /dev/null
         echo "[+] Finished Bootstrapping"
         ;;

    "archlinux")
        echo "[+] Bootstrapping archlinux/archlinux"
        mkdir "$MACHINED_DIR$CONTAINER_NAME"
        pacstrap -c -d "$MACHINED_DIR$CONTAINER_NAME" base openssh > /dev/null
        ;;
    *)
        echo "[-] Sorry ubuntu and debian only"
        exit 3
esac

if [ -d "$MACHINED_DIR$CONTAINER_NAME" ]; then
    echo "pts/0" >> "$MACHINED_DIR$CONTAINER_NAME/etc/securetty"
    echo "[+] added 'pts/0' to $MACHINED_DIR$CONTAINER_NAME/etc/securetty"
    mkdir -m700 "$MACHINED_DIR$CONTAINER_NAME/root/.ssh"
    echo "[+] created $MACHINED_DIR$CONTAINER_NAME/root/.ssh"
    install -m600 "$SSH_KEY" "$MACHINED_DIR$CONTAINER_NAME/root/.ssh/authorized_keys"
    echo "[+] copied $SSH_KEY to $MACHINED_DIR$CONTAINER_NAME/root/.ssh/authorized_keys"
    machinectl start "$CONTAINER_NAME"
    echo "[+] started container"
    sleep 3
    systemctl -q -M "$CONTAINER_NAME" enable systemd-networkd --now
    systemctl -q -M "$CONTAINER_NAME" enable systemd-resolved --now
    if [ "$DISTRIBUTION" == "archlinux" ]; then
        systemctl -q -M "$CONTAINER_NAME" enable sshd --now
    else
        systemctl -q -M "$CONTAINER_NAME" enable ssh --now
    fi
    echo "[+] enabled important services"
    machinectl shell "$CONTAINER_NAME" /usr/bin/passwd -d root
    echo "[+] removed root password"

else
    echo "[-] Target directory $MACHINED_DIR$CONTAINER_NAME does not exist!"
    exit 4
fi
