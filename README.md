# YI Home 720p (22US) — Local RTSP Without The YI App

A tested guide for the **first-generation YI Home 720p** (model **YHS-113-IR**, serial starting **22US**) that the current `yi-hack` projects don't support. It gives the camera a local video stream for Home Assistant, Blue Iris, VLC and similar, with no app or cloud, and leaves it cut off from the internet.

> **Status:** worked on one camera in November 2026 (22US, stock firmware `1.8.7.0F_201809191400`). It's built on community work from 2015–2017. Read the [risks](#risks) first.

## What You Get

| | |
|---|---|
| Main stream | `rtsp://<camera-ip>:554/ch0_0.h264` — 1280×720 H.264 + AAC audio |
| Small stream | `rtsp://<camera-ip>:554/ch0_1.h264` — 640×360 |
| SD recordings | The camera keeps recording to its card; browse the clips read-only at `ftp://<camera-ip>/` |
| Internet | Blocked on the camera itself; only your home network can reach it |
| Remote login | Off (the hack turns telnet on with a public factory password; step 3 turns it off again) |

You lose the YI app. On old firmware it shows the camera as "offline", and once the internet is blocked it can't reach the camera at all.

## Is This Your Camera?

1. **Model:** `YHS-113-IR` on the base or stand. Other markings on the stand: FCC ID `2AFIB-H1500A`, CMIIT `2014DP4828`.
2. **Serial / QR code on the back:** the first four characters are the hardware variant. This guide is for **22US**. **22EU** is the same hardware and should also work (untested here).
3. **Chip:** Hisilicon **Hi3518eV100**. Newer 720p units (17CN / 27US / 47US) use the V200 and should use [yi-hack-v4](https://github.com/TheCrypt0/yi-hack-v4) or [yi-hack-v5](https://github.com/alienatedsec/yi-hack-v5) instead.

**Don't use yi-hack-v4 or v5 on a 22US/22EU.** The v5 table lists firmware `1.8.7.0F_201809191400` for "Yi Home", but a 22US running that exact version **ignores** the `rootfs_y18` / `home_y18` files. Renaming them to `rootfs` / `home` to force them in **left one camera unable to boot** ([v5 #382](https://github.com/alienatedsec/yi-hack-v5/issues/382), [v5 #473](https://github.com/alienatedsec/yi-hack-v5/issues/473)).

## How It Works

This is the 2017 method from [fritz-smh/yi-hack #166](https://github.com/fritz-smh/yi-hack/issues/166), with a few safety changes:

1. **Downgrade** to stock firmware **1.8.5.1N**. The camera installs any file named `home` from the root of the SD card.
2. **RTSP:** stock firmware runs `test/equip_test.sh` from the SD card at boot (a factory-test hook). The `test-rtspfix-07` script uses that hook to install an RTSP server.
3. **Lock down:** another hook script turns telnet off and limits FTP to the recordings folder, read-only.
4. **No internet:** a startup script on the camera deletes its default route every 30 seconds and writes a status file you can read over FTP.

Each hook script renames itself after running, so it only runs once.

## Before You Start

- A microSD card, **FAT32** (32 GB worked). **Everything on it gets deleted.**
- A computer with an SD card reader.
- The YI app, once, to confirm the camera is on Wi-Fi and to see the firmware version (*Settings → Camera Info*). It's fine if you can't get in.
- **Don't accept the firmware update the app offers.** Newer firmware may block the downgrade.
- Your router's admin page, to give the camera a fixed address (DHCP reservation).

### Downloads (not included in this repo)

They're attachments on old GitHub issues. Download them from the original posts and check them against [CHECKSUMS.md](CHECKSUMS.md):

| File | From | Used for |
|---|---|---|
| `Yi.Home.Firmware.Older.Versions.zip` | [fritz-smh/yi-hack #166](https://github.com/fritz-smh/yi-hack/issues/166) → `github.com/fritz-smh/yi-hack/files/1185266/...` | Stock 1.8.5.1N (US) and 1.8.6 firmware |
| `test-rtspfix-07.zip` | same thread → `.../files/1185267/...` | The `rtspsvrI/K/M` RTSP server binaries |
| `22EU_Recovery.zip` | [yi-hack-v5 #382](https://github.com/alienatedsec/yi-hack-v5/issues/382) | Recovery images, only if a camera won't boot |

**Check the firmware images before flashing:** [tools/verify-uimage.ps1](tools/verify-uimage.ps1) (Windows) or [tools/verify_uimage.py](tools/verify_uimage.py) (macOS/Linux). They check the U-Boot header and data CRCs. A truncated or corrupted download fails.

**Antivirus note:** Windows Defender flags `test/server` inside `test-rtspfix-07.zip` as `Trojan:Linux/SAgnt!MTB`. It's an optional replacement web server, and this guide **doesn't use it**. The `rtspsvr*` files weren't flagged.

## Step By Step

Unplug the camera before taking out or inserting the card, every time.

### Step 1 — Downgrade To 1.8.5.1N

1. Delete everything on the card. If the card came from the camera, a plain delete is enough; otherwise format it as FAT32.
2. From `Yi.Home.Firmware.Older.Versions.zip`, copy `1.8.5.1N_201601071352home_us` to the **root** of the card and rename it to exactly `home` (no extension).
3. Insert the card and power on. Expect **blinking amber for several minutes, then solid amber**, and the lens filter will click. **Don't unplug it during this.**
4. It comes back on Wi-Fi by itself.
5. **Confirm the version.** The app may not show it on old firmware. Instead, unplug the camera and open the SD card: it writes `log_*_yi_login.tar.gz`, and inside, `log.txt` should contain `version=1.8.5.1N_201601071352`.
   - Didn't take? The 2017 thread suggests loading **1.8.6** first, then 1.8.5.

### Step 2 — Turn On RTSP

1. Delete everything on the card again, including `home`.
2. Copy [scripts/step2-rtsp/test/equip_test.sh](scripts/step2-rtsp/test/equip_test.sh) to `test/` on the card, plus `rtspsvrI`, `rtspsvrK` and `rtspsvrM` from `test-rtspfix-07.zip`. **Leave out `server`.**
3. Edit `mytz=` in the script for your timezone (for example `UTC-8` = US Pacific, `UTC+1` = Central Europe).
4. Insert, power on, and wait. It restarts once by itself. On our camera, ports 21, 23 and 554 opened after about 8 minutes.
5. Test in VLC: `rtsp://<camera-ip>:554/ch0_0.h264`.

`test/equip_test.sh` should now be renamed to `equip_test-moved.sh` on the card, which means it ran.

### Step 3 — Lock It Down

Step 2 turned on **telnet with the public factory root password** and **writable FTP of the whole filesystem with no login**. Close both:

1. Put [scripts/step3-lockdown/test/equip_test.sh](scripts/step3-lockdown/test/equip_test.sh) into `test/` on the card (replace the moved one; the `rtspsvr*` files can stay).
2. Insert, power on, and wait for the restart.
3. Check: port 23 closed; `ftp://<camera-ip>/` lists only recordings, and uploads fail. The card gets `test/lockdown-result.txt`.

### Step 4 — Block The Internet

This stops YI from pushing an update that would undo the hack, and keeps the old binaries off the internet. Many routers can do this too, but some (ours included) wouldn't save the rule, so this does it on the camera:

1. Put [scripts/step4-nointernet/test/equip_test.sh](scripts/step4-nointernet/test/equip_test.sh) into `test/` on the card.
2. Insert, power on, and wait for the restart.
3. About a minute after boot, and every ~5 minutes after that, the camera writes **`ftp://<camera-ip>/nointernet-status.txt`**. A good result looks like:
   ```
   --- routes
   192.168.1.0   0.0.0.0   255.255.255.0   U   ...   ra0   <- home network only, no "default"
   --- ping router (should work)        1 packets received
   --- ping internet 8.8.8.8 (should fail)
   ping: sendto: Network is unreachable
   ```

To undo it later, put a hook script on the card that runs `rm /etc/init.d/S95nointernet` and then `reboot`.

### Step 5 — Fixed Address And Home Assistant

1. In your router, add a **DHCP / address reservation** for the camera's MAC. It often shows up as `ANTSCAM-…`.
2. In Home Assistant: **Settings → Devices & Services → Add Integration → Generic Camera**.
   - Stream source: `rtsp://<camera-ip>:554/ch0_0.h264`
   - Still image URL: leave empty (there isn't one)
   - More options → RTSP transport: **TCP**
3. Tick "Everything looks good" on the preview and give it a name. Live view works; dashboard tiles show a placeholder instead of a still.

## Lessons Learned (Read These)

- **A script in `test/` must end with `reboot`.** While `test/equip_test.sh` exists, the camera runs it *instead of* its normal startup. A script that doesn't reboot leaves the camera with no Wi-Fi and a solid amber light. Unplugging fixes it, since the script has already renamed itself.
- **Every script renames itself before anything risky.** Then if it hangs, the next power cycle boots normally.
- **The status light:** it blinks amber while booting, then follows your old YI app light setting. Ours stayed off because it was set to off years ago, and the setting survived the hack.
- **"Offline" in the app with a working live view** is normal on 1.8.5.
- **Startup is slower without internet:** the camera can take a few minutes to show up after a power cut.
- **No internet means no time sync.** SD recording timestamps can be wrong after a power cut. Live view isn't affected.
- **Windows:** after "Eject", some USB card readers stay disabled until you unplug and replug the reader.

## Risks

- **This can permanently brick the camera.** The 2017 thread has both successes and bricked units. Ours worked, and yours might not.
- The RTSP binaries came from an anonymous 2017 forum attachment. They run as root on the camera. Blocking the internet (step 4) limits the harm they could do.
- The stream has **no password**. Anyone on your home network can watch it. Keep the camera off any guest or public network.
- If it won't boot: the [22EU recovery images](https://github.com/alienatedsec/yi-hack-v5/issues/382) (`home` + `rootfs` on a blank card) recovered a 22EU unit. They're **untested on 22US**.

## Credits

All of this rests on other people's work and generosity:

- [fritz-smh/yi-hack](https://github.com/fritz-smh/yi-hack), and everyone in [issue #166](https://github.com/fritz-smh/yi-hack/issues/166), especially the user who posted the working US-model method (downgrade + `test-rtspfix-07`).
- The authors of `test-rtspfix-07` and the original Chinese-model method (MIUI forum, 2016).
- [alienatedsec/yi-hack-v5](https://github.com/alienatedsec/yi-hack-v5) contributors, whose issues [#382](https://github.com/alienatedsec/yi-hack-v5/issues/382) and [#473](https://github.com/alienatedsec/yi-hack-v5/issues/473) documented why v5 fails on 22US, and who shared the 22EU recovery images.
- [TheCrypt0/yi-hack-v4](https://github.com/TheCrypt0/yi-hack-v4) for the supported-models wiki.

See [docs/JOURNEY.md](docs/JOURNEY.md) for the full story, including the dead ends.

## License

The scripts and docs in this repo are MIT ([LICENSE](LICENSE)). `scripts/step2-rtsp/test/equip_test.sh` is adapted from `test-rtspfix-07`, whose original license is unknown; credit to its authors. YI firmware and the RTSP binaries are **not** included or relicensed. Get them from the original posts.
