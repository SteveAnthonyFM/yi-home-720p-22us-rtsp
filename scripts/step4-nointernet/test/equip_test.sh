#!/bin/sh
# Step 4: cut the camera off from the internet but keep the home network
# (runs once from the SD card, then reboots).
#
# Installs /etc/init.d/S95nointernet, which runs at every boot and:
#   - deletes the default route every 30 s (DHCP can add it back), so only
#     addresses on the camera's own subnet stay reachable;
#   - about every 5 min writes a status report to the recordings folder,
#     readable over the read-only FTP from step 3:
#         ftp://<camera-ip>/nointernet-status.txt
#
# Optional: set ROUTER and HOMESERVER to addresses on your network, so the
# report also shows them answering (an empty value skips that test).
#
# To undo: run a hook script containing
#     rm /etc/init.d/S95nointernet
#     mv $0 `dirname $0`/equip_test-moved.sh; reboot
#
# NOTE: while test/equip_test.sh exists on the card the camera skips its
# normal startup, so this script renames itself first and ends with reboot.

ROUTER=""        # e.g. 192.168.1.1
HOMESERVER=""    # e.g. your Home Assistant IP

dr=`dirname $0`
mv $dr/equip_test.sh $dr/equip_test-moved.sh
sync

cat > /etc/init.d/S95nointernet <<EOF
#!/bin/sh
(
  n=0
  while true; do
    route del default 2>/dev/null
    if [ \$((n % 10)) -eq 2 ]; then
      f=/home/hd1/record/nointernet-status.txt
      if [ -d /home/hd1/record ]; then
        {
          echo "updated: \`date\`   uptime: \`uptime\`"
          echo "--- routes (there should be no 'default' / 0.0.0.0 destination)"
          route -n
          if [ -n "$ROUTER" ]; then
            echo "--- ping router $ROUTER (should work)"
            ping -c 1 -W 2 $ROUTER
          fi
          if [ -n "$HOMESERVER" ]; then
            echo "--- ping home server $HOMESERVER (should work)"
            ping -c 1 -W 2 $HOMESERVER
          fi
          echo "--- ping internet 8.8.8.8 (should fail: Network is unreachable)"
          ping -c 1 -W 2 8.8.8.8
        } > \$f.tmp 2>&1
        mv \$f.tmp \$f
      fi
    fi
    n=\$((n + 1))
    sleep 30
  done
) &
EOF
chmod 755 /etc/init.d/S95nointernet

cat /etc/init.d/S95nointernet > $dr/nointernet-installed.txt
sync
reboot
