## Overload Server in Docker

### Install on a clean Ubuntu VM

We want docker (ripped from the official docs), and we also stick a sneaky `docker-compose` download in there.
Then we reboot for kernel updates, though you can skip that and the `dist-upgrade` if you want.

```bash
apt-get update
apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
apt-get upgrade
apt-get dist-upgrade

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

apt-get install docker-ce docker-ce-cli containerd.io
apt-get autoremove
apt-get clean

# Reboot for likely kernel upgrade
reboot
```

Then, `rsync` over your Overload install dir with olmod installed.

### Pre-populate maps

Maybe you want to have all the maps from [Overload Maps](https://overloadmaps.com).
Note that this is just shy of 5GB of data as of 2020-12-18.

From your Overload game directory, create a folder called `DLC`, then from that, run this one-liner:

```bash
curl -s https://overloadmaps.com/data/all.json | jq -r '.[].url' | xargs -n1 --replace -P2 sh -c 'wget -nc https://overloadmaps.com{}'
```

### Prepare the containers

Update the `env` file to include what you want, it's pretty self explanitory.
This is pretty optional, depending on if you care about updating the tracker.
If you don't want the `supervisor` container, you don't need this.

```bash
OVERLOAD_VERSION=v1.1
OVERLOAD_BUILD=1886
OLMOD_VERSION=v0.3.4
SERVER_LOCATION=Toronto, Ontario, Canada
```

Copy the files from here (minus this `README.md` I guess) into your Overload directory.

### Run the server

Start up `docker-compose` and we're done!

```bash
docker-compose up -d
```

This will start two containers:

- `overload` - the main game, this is probably what you're here for.  Uses the stock `olmodserverinet.sh` script with `-port 8000` to force a consistent port.
- `supervisor` - a dumb control loop that kills the game when the server is idle for `[10,15)` minutes.  This is okay because `overload` is set to always restart. Can be omitted.

It only uses two ports, `8000` and `8001`.
