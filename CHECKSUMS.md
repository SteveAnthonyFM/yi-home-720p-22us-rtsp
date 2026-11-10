# Checksums

SHA-256 of the files used on the tested camera (downloaded November 2026). If yours don't match, don't flash them.

Windows: `Get-FileHash <file>` · macOS/Linux: `shasum -a 256 <file>`

## Archives

| SHA-256 | File |
|---|---|
| `6ea2801fd02a8f6da267bb57147838359f04e4bb570d85dd81df73589ec01b80` | `Yi.Home.Firmware.Older.Versions.zip` |
| `3172b4c6d1517560c8530a07a2af27746bf600963cf502ddbdae23efb7068a22` | `test-rtspfix-07.zip` |
| `99678acadd8236a80812314d7d34343c6416fb67fef703653dac784646a6ba1f` | `22EU_Recovery.zip` |

## Extracted Files

| SHA-256 | File | Notes |
|---|---|---|
| `ed70df49154d797fceb30f9c8fb39ac7e803e361c4bdcd87b5733ca372d7d30d` | `1.8.5.1N_201601071352home_us` | uImage `7518-hi3518-home`, built 2016-01-07, CRCs OK. **This is the one used.** |
| `2e568caf44ba799dbb4b1503e094c97e0e86237df7bf41c729b284603ee9b7a7` | `1.8.6test.1B_201604071151home` | uImage, built 2016-04-07, CRCs OK |
| `5e7053bf8e7751fadf4adf5aafd877b16d2e47afd40cc15e8785646a3176887c` | `22EU_Recovery/Yi Home/home` | uImage `0001-hi3518-home`, built 2017-11-03, CRCs OK |
| `dab1e63154c070c79f274cd89ce550aa8deb61f9f31e2e8af70f80574952f538` | `22EU_Recovery/Yi Home/rootfs` | uImage `0001-hi3518-rootfs`, built 2017-10-05, CRCs OK |
| `b721f16d9149af98c15fe95c633da76bd4915bccfde07e3a74f01118a9ed5277` | `test/rtspsvrM` | Used for firmware 1.8.5.1M / 1.8.5.1N |
| `ad99b4cf49cf8510a9178af1b9acab704d35b5769dd2b75aa3ff2597c695ce6e` | `test/rtspsvrK` | 1.8.5.1J/K/L |
| `7f2bcf7f47e0869d37a2148522eba6fccebeb4c63eced597cb953e090ab8f2cb` | `test/rtspsvrI` | 1.8.5.1B/E/F/H/I |
| `0b2e6ea48acb4a4684b179665296bfbf0b652bcb8f3c2fde189d92e49191b472` | `test/equip_test.sh` | The original script; this repo ships an adapted copy |
| — | `test/server` | Not used; Windows Defender quarantines it |
