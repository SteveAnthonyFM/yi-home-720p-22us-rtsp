#!/usr/bin/env python3
"""Check YI firmware images (U-Boot uImage format) before you flash them.

Prints the image name, build date, and whether the size, header CRC and
data CRC are correct. Any "False" means: don't flash that file.

Usage:  python3 verify_uimage.py home rootfs
"""
import struct
import sys
import time
import zlib

MAGIC = 0x27051956


def check(path):
    with open(path, "rb") as fh:
        data = fh.read()
    if len(data) < 64 or struct.unpack(">I", data[:4])[0] != MAGIC:
        print(f"{path}\n  NOT a uImage (bad magic) - don't flash")
        return
    _, hcrc, ts, size, _, _, dcrc = struct.unpack(">7I", data[:28])
    name = data[32:64].rstrip(b"\0").decode("ascii", "replace")
    header = bytearray(data[:64])
    header[4:8] = b"\0\0\0\0"
    size_ok = size == len(data) - 64
    header_ok = (zlib.crc32(bytes(header)) & 0xFFFFFFFF) == hcrc
    data_ok = size_ok and (zlib.crc32(data[64:64 + size]) & 0xFFFFFFFF) == dcrc
    built = time.strftime("%Y-%m-%d", time.gmtime(ts))
    print(f"{path}\n  name={name} built={built} sizeOK={size_ok} "
          f"headerCRC={header_ok} dataCRC={data_ok}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    for p in sys.argv[1:]:
        check(p)
