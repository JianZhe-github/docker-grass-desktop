#!/bin/bash

# Enable job control
set -m
umask 077

# These files could be left-over if the container is not shut down cleanly. We just remove them since we should
# only be here during container startup.
rm -f /tmp/.X1-lock
rm -rf /tmp/.X11-unix

export HOME=/home/grass
VNC_DIR="$(mktemp -d /tmp/grass-vnc.XXXXXX)"
trap 'rm -rf "$VNC_DIR"' EXIT

echo "Using VNC temp dir: $VNC_DIR"

# Set up the VNC password
if [ -z "$VNC_PASSWORD" ]; then
    echo "VNC_PASSWORD environment variable is not set. Using a random password. You"
    echo "will not be able to access the VNC server."
    VNC_PASSWORD="$(tr -dc '[:alpha:]' < /dev/urandom | fold -w "${1:-8}" | head -n1)"
fi
echo -n "$VNC_PASSWORD" | /opt/TurboVNC/bin/vncpasswd -f > "$VNC_DIR/passwd"
chmod 400 "$VNC_DIR/passwd"
unset VNC_PASSWORD

# TurboVNC by default will fork itself, so no need to do anything here
/opt/TurboVNC/bin/vncserver -rfbauth "$VNC_DIR/passwd" -geometry 1200x800 -rfbport 5900 -wm openbox :1

export DISPLAY=:1

if [ -z "$GRASS_USERNAME" ] || [ -z "$GRASS_PASSWORD" ]; then
    >&2 echo "The GRASS_USERNAME and GRASS_PASSWORD environment variables need to be set"
    >&2 echo "before docker-grass-desktop can start. If you do not already have a username"
    >&2 echo "and password, sign up in a browser at:"
    >&2 echo "https://app.getgrass.io/register/?referralCode=sqKqTw8JHScyGFY"
    >&2 echo "The container will now exit."
    exit 243
fi

exec grass-desktop
