#!/bin/sh
# Step 3: lock down after step 2 (runs once from the SD card, then reboots).
#  - Turns telnet off (step 2 enabled it with the factory root password).
#  - Replaces the writable whole-filesystem FTP with read-only FTP of the
#    SD-card recordings folder only.
#  - Leaves the RTSP server (/home/rtspsvr) alone.
# Writes test/lockdown-result.txt to the card.
# To turn telnet back on later, run the step 2 script again.

dr=`dirname $0`

# Telnet off
rm -f /etc/init.d/S88telnet
killall telnetd 2>/dev/null

# FTP: read-only, recordings only
echo "#!/bin/sh" > /etc/init.d/S89ftp
echo "tcpsvd -vE 0.0.0.0 21 ftpd /home/hd1/record &" >> /etc/init.d/S89ftp
chmod 755 /etc/init.d/S89ftp

ls -l /etc/init.d > $dr/lockdown-result.txt
cat /etc/init.d/S89ftp >> $dr/lockdown-result.txt
sync

# Run only once, then reboot into normal startup
mv $dr/equip_test.sh $dr/equip_test-moved.sh
sync
reboot
