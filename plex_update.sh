#!/bin/bash
# Run after /opt/etc/init.d/S99debian enter

set -e

backup_date=$(date +%Y-%m-%d)
backup_dir="/home/plex/backup/$backup_date"

current_version=$(/home/plex/usr/lib/plexmediaserver/Plex\ Media\ Server --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'| cut -d'-' -f1 )
latest_version=$(curl -s "https://plex.tv/api/downloads/5.json" | jq -r '.computer.Linux.releases[] | select(.build == "linux-armv7neon") | .version' | cut -d'-' -f1 2>/dev/null)


if [[ -z "$current_version" ]] || [[ -z "$latest_version" ]]; then
    echo "Error: failed to retrieve one of the versions." >&2
    exit 1
fi

echo "Current version: $current_version"
echo "Latest version: $latest_version"

if [[ "$current_version" == "$latest_version" ]]; then
    echo "Plex is up to date. Exiting the script."
    exit 0
fi

echo "Update available ($latest_version). Continuing script execution..."

/etc/init.d/plexmediaserver stop

mkdir -p "$backup_dir"
cp -r /home/plex/usr/ "$backup_dir/"

latest_url=$(curl -s "https://plex.tv/api/downloads/5.json" | jq -r '.computer.Linux.releases[] | select(.build == "linux-armv7neon") | .url')

wget "$latest_url" -O /tmp/plexmediaserver.deb

dpkg-deb --extract /tmp/plexmediaserver.deb /home/plex

rm /tmp/plexmediaserver.deb

/etc/init.d/plexmediaserver start

echo "Plex updated successfully to version $latest_version. Backup saved to $backup_dir."
