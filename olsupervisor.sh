#!/bin/bash

# Set these through the env
# Once the game has run once, we could scrape this from the log
# but that's more work than I'm willing to do for something so dirty
OVERLOAD_VERSION=${OVERLOAD_VERSION:-unknown}
OVERLOAD_BUILD=${OVERLOAD_BUILD:-unknown}
OLMOD_VERSION=${OLMOD_VERSION:-unknown}
SERVER_LOCATION=${SERVER_LOCATION:-Somewhere}

# What the game uses
JSONDIR=$HOME/.config/unity3d/Revival/Overload
LOGFILE=$JSONDIR/Player.log
SETTINGSFILE=/overload/olmodsettings.json

# Use $JSONDIR in docker to persist container restarts
# otherwise, we'd just use /tmp
LASTKICK=$JSONDIR/lastkick

##
## Docker specific
## I don't want to do this in a Dockerfile
## because I'm a lazy jerk
##
apt-get update && apt-get install -qy curl jq

# Has overload ever run?
if [ ! -f $LOGFILE ]; then
  echo $LOGFILE does not exist, OL has probably never run
  echo run it and have an enjoy
  exit 1
fi

# Last kick is now
touch $LASTKICK

# We're going to keep scanning for the last *.json file in the JSONDIR
# and compare it to the last time we kicked overload
while true; do

  # Is overload running?
  OLPID=`egrep '^Our process:' $LOGFILE | awk '{print $3}'`
  if [ -z "$OLPID" ]; then
    echo "$(date -Iseconds) OL not running, sleeping..."
    sleep 5
    continue
  fi

  # Get the newest JSON, sorted by filename
  NEWESTJSON=`find $JSONDIR -type f -name "*json" | sort -r | head -n 1`

  # If it's empty, we haven't run any games yet
  if [ -z "$NEWESTJSON" ]; then
    echo "$(date -Iseconds) No JSON files found"
    sleep 60
    continue
  fi

  # If our last kick is newer than the newest JSON, that means
  # we have kicked since the last game was played
  if [ "$LASTKICK" -nt "$NEWESTJSON" ]; then
    echo "$(date -Iseconds) Last kick is newer than latest game"
    sleep 60
    continue
  fi

  # So we get a tracker ping every 5 minutes, and it logs it.
  # It still does it mid game, so we can't do that if we see it.
  # However, if we see our last two log items are pings...
  GROSSCHECK=`tail -n 2 $LOGFILE | grep 'TrackerPost /api/ping' | wc -l`
  if [ "$GROSSCHECK" != "2" ]; then
    echo "$(date -Iseconds) Have newer game than kick, but not idle long enough"
    sleep 60
    continue
  fi

  # Now we kick it, lol
  echo "$(date -Iseconds) Kicking..!"

  # Get server name first, update the tracker
  SERVERNAME=`cat $SETTINGSFILE | jq -r .serverName`
  curl -v https://tracker.otl.gg/api/ping \
    -H 'Content-Type: application/json' \
    -d "{\"keepListed\":true,\"name\":\"$SERVERNAME (restarting)\",\"notes\":\"Overload $OVERLOAD_VERSION (build $OVERLOAD_BUILD), OLMod $OLMOD_VERSION - $SERVER_LOCATION\"}"

  kill $OLPID
  touch $LASTKICK
  sleep 60
done

