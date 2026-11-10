# How We Got Here — What Worked, What Didn't

A record of one evening's attempt to rescue an old YI Home 720p (YHS-113-IR, serial **22US**) from the YI app. The point is to save the next person the dead ends.

## The Goal

Use the camera in Home Assistant with a local stream, keep SD-card recording, and drop the ad-heavy mobile app, flashing new firmware if needed.

## 1. Identifying The Camera

- The model sticker says **YHS-113-IR**: the original 2015/2016 YI Home 720p.
- The QR code on the back gave the serial, starting with **22US**. That prefix is what matters. The yi-hack-v4 wiki lists 720p variants 17CN / 27US / 47CN as supported, and **22US as not supported**. 22US units use the older **Hi3518eV100** chip.
- The app showed stock firmware **1.8.7.0F_201809191400** and offered an update to `1.8.7.0F_202608271657`. **We didn't install it.**
- The camera wasn't on USB. It was on Wi-Fi, and its MAC vendor (Shenzhen Zowee, `b0:d5:9d`) picked it out of the router's device list. Every useful port was closed: 21, 23, 80 and 554.

## 2. Dead End: The Modern Hacks

- **yi-hack-v5** lists exactly our firmware (`1.8.7.0F_201809191400`) as the base for "Yi Home", which looked like a match. Then we found [v5 #473](https://github.com/alienatedsec/yi-hack-v5/issues/473): same model, same 22US prefix, same firmware. The camera **silently ignores** `rootfs_y18` / `home_y18`. [v5 #382](https://github.com/alienatedsec/yi-hack-v5/issues/382) shows that renaming the files to force them in **left a 22EU unable to boot**. It was recovered with images posted in that thread.
- **yi-hack-v4**, **yi-hack-MStar** and **yi-hack-Allwinner(-v2)** are all for other chips.
- **No-hack alternatives:** tinyCam Monitor added YI cloud support in 2019, and its PRO version can re-stream to other software. We couldn't confirm it still works, and the camera would stay cloud-dependent. Running the YI app in an Android emulator and capturing the screen is possible but fragile. We kept both as fallbacks and didn't need them.

## 3. What Worked: The 2017 Method

[fritz-smh/yi-hack #166](https://github.com/fritz-smh/yi-hack/issues/166) ("US version firmware 1.8.7 can't hack for RTSP") turned out to have a working recipe from mid-2017. One user got five US 720p cameras streaming with it:

1. Downgrade to stock **1.8.5** by putting the image on the SD card as `home`.
2. Add the `test` folder from `test-rtspfix-07.zip`. It uses the factory-test hook (`test/equip_test.sh`) to install an RTSP server.

The same thread also has failures: cameras that wouldn't take the downgrade, and a few bricked by renaming files to `home_y18`. Our firmware (1.8.7.0F) was newer than anyone's there, so the downgrade might have been refused. It wasn't.

### Checking The Files First

- The firmware images are U-Boot uImages (magic `27 05 19 56`, name `7518-hi3518-home`). All of them passed header and data CRC checks, and their build dates matched their version strings. See [tools/](../tools).
- **Windows Defender flagged `test/server`** (the bundle's replacement web server) as `Trojan:Linux/SAgnt!MTB`. RTSP doesn't need it, so we dropped it and removed the lines that install it. The three `rtspsvr` builds weren't flagged.

### The Downgrade

Blinking amber, then solid amber with the lens filter clicking. The camera came back on Wi-Fi by itself. The YI app couldn't show the version on 1.8.5: it said "offline" but still gave a live view. **The real confirmation came from the SD card:** the camera writes `log_*_yi_login.tar.gz`, and its `log.txt` contained `version=1.8.5.1N_201601071352`.

### The RTSP Hack

About 8 minutes after powering on with the `test` folder, ports 21, 23 and 554 opened:

- `ch0_0.h264`: 1280×720 H.264 + AAC
- `ch0_1.h264`: 640×360

## 4. Locking It Down

The hack also opened two holes:

- **telnet** with the public factory root password;
- **FTP of the whole filesystem, writable, no login** (`ftpd -w /`).

Rather than log in with the factory password, we wrote a second hook script (step 3). It deletes the telnet startup file and restarts FTP as read-only, limited to `/home/hd1/record`. Afterwards: port 23 closed, FTP showed only recordings, and an upload test failed.

## 5. Blocking The Internet

This keeps YI from pushing an update that would undo the hack (some units reportedly auto-update), and keeps the anonymous 2017 binaries offline.

- **Router route (failed):** the router's "Block Services" page never saved the rule. After four tries the page froze on a pop-up, and the rule list stayed empty. (A DHCP reservation for the camera did save fine.)
- **Camera route (worked):** a startup script on the camera (`/etc/init.d/S95nointernet`) deletes the default route every 30 seconds. The camera keeps its home-network route, so Home Assistant still works, but it has nowhere to send internet traffic.

### Our Mistake, Worth Knowing

To check the block, we added a hook script that waited 3 minutes and logged the routes, **without rebooting**. The camera then sat on **solid amber** and never rejoined Wi-Fi. While `test/equip_test.sh` exists, the camera runs it **instead of** its normal startup: no Wi-Fi, no camera software. A power cycle fixed it, because the script had already renamed itself. Its log showed no network at all, which explained everything.

**Rule: every hook script renames itself first and ends with `reboot`.**

The fix was to make the blocker itself write a status file into the recordings folder every ~5 minutes, readable over the read-only FTP. The first report showed only the home-network route, the router and Home Assistant answering pings, and `8.8.8.8` → `Network is unreachable`.

## 6. Small Things We Learned

- **Status light:** it blinks amber while booting, then follows the light setting from the YI app. Ours had been set to "off" years ago, and that survived. A long *solid* amber means it skipped normal startup (see above).
- **Slower startup without internet:** the camera retries YI's servers for a few minutes first.
- **No time sync without internet:** SD timestamps can drift after a power cut.
- **Home Assistant:** the Generic Camera integration with RTSP over TCP. Live view works. There's no snapshot URL, so dashboard tiles show a placeholder until opened.
- **Windows card readers:** after "Eject", the reader may need to be unplugged and replugged before Windows sees the card again. Flushing the drive cache instead of ejecting avoids that.

## Files Produced

- `scripts/step2-rtsp`: adapted `test-rtspfix-07` (no `server` swap)
- `scripts/step3-lockdown`: telnet off, FTP read-only on recordings
- `scripts/step4-nointernet`: route blocker plus status file
- `tools/verify-uimage.ps1`, `tools/verify_uimage.py`: firmware image checks
