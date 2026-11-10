#!/bin/sh
# Step 2: install the RTSP server (runs once from the SD card, then reboots).
#
# Adapted from test-rtspfix-07 (fritz-smh/yi-hack issue #166, 2017).
# Changes from the original:
#   - The HTTP "server" binary swap is removed. Windows Defender flags that
#     binary (Trojan:Linux/SAgnt!MTB), and RTSP doesn't need it.
#   - Comments added.
#
# Copy to the SD card as  test/equip_test.sh, next to rtspsvrI, rtspsvrK
# and rtspsvrM from test-rtspfix-07.zip. Requires stock firmware 1.8.5.1x.
#
# WARNING: this turns on telnet (factory root password) and writable FTP of
# the whole filesystem with no login. Run step 3 straight afterwards.

# Timezone: set to your UTC offset (UTC-8 = US Pacific, UTC+1 = Berlin).
mytz=UTC+0 # <- Edit here

digitalTZ=`echo $mytz | sed 's/UTC//'`

# The YI firmware counts time from China (UTC+8), hence the odd formula.
TZtoSet=$((8-digitalTZ))

if [ $TZtoSet -gt 0 ]; then
    TZValue="GMT+$TZtoSet"
    echo "TZValue=$TZValue"
else
    TZValue="GMT$TZtoSet"
    echo "TZValue=$TZValue"
fi

echo $TZValue > /etc/TZ

# Telnet (turned off again by step 3)

if [ ! -f "/etc/init.d/S88telnet" ]; then
    echo "#!/bin/sh" > /etc/init.d/S88telnet
    echo "telnetd &" >> /etc/init.d/S88telnet
    chmod 755 /etc/init.d/S88telnet
fi

# FTP (restricted to read-only recordings by step 3)

echo "#!/bin/sh" > /etc/init.d/S89ftp
echo "tcpsvd -vE 0.0.0.0 21 ftpd -w / &" >> /etc/init.d/S89ftp
chmod 755 /etc/init.d/S89ftp

dr=`dirname $0`

# RTSP: pick the rtspsvr build that matches the 1.8.5.1 firmware letter

versionLetter=`sed -n 's/version=1.8.5.1\(.\)_.*/\1/p' /home/version`

case $versionLetter in
    M|N) file='M'
        ;;
    J|K|L) file='K'
        ;;
    B|E|F|H|I) file='I'
        ;;
    *) file='None'
        ;;
esac

if [ $file != 'None' ]; then
    filename="${dr}/rtspsvr${file}"
    echo Using $filename
    if test -f $filename; then
        if ! cmp $filename /home/rtspsvr; then
            test -f /home/rtspsvr && mv /home/rtspsvr /home/rtspsvr.backup
            cp $filename /home/rtspsvr
        fi
    fi
else
    echo 'Firmware not supported'
fi

# Run only once, then reboot into normal startup

mv $dr/equip_test.sh $dr/equip_test-moved.sh
reboot
