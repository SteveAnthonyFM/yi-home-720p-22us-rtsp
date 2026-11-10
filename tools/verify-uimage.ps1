# Checks YI firmware images (U-Boot uImage format) before you flash them.
# Prints the image name, build date, and whether the size, header CRC and
# data CRC are correct. Any "False" means: don't flash that file.
#
# Usage (PowerShell):
#   powershell -ExecutionPolicy Bypass -File verify-uimage.ps1 -Paths .\home, .\rootfs
param([Parameter(Mandatory = $true)][string[]]$Paths)

Add-Type -TypeDefinition @'
public static class UImg {
  static uint[] T = Make();
  static uint[] Make() { var t = new uint[256]; for (uint i = 0; i < 256; i++) { uint c = i; for (int k = 0; k < 8; k++) c = (c & 1) != 0 ? 0xEDB88320u ^ (c >> 1) : c >> 1; t[i] = c; } return t; }
  public static uint Crc(byte[] b, int off, int len) { uint c = 0xFFFFFFFFu; for (int i = off; i < off + len; i++) c = T[(c ^ b[i]) & 0xFF] ^ (c >> 8); return c ^ 0xFFFFFFFFu; }
  public static uint BE(byte[] b, int o) { return ((uint)b[o] << 24) | ((uint)b[o+1] << 16) | ((uint)b[o+2] << 8) | b[o+3]; }
}
'@

foreach ($p in $Paths) {
  $b = [IO.File]::ReadAllBytes((Resolve-Path $p))
  if ($b.Length -lt 64 -or [UImg]::BE($b, 0) -ne 0x27051956) { "{0}`n  NOT a uImage (bad magic) - don't flash" -f $p; continue }
  $hcrc = [UImg]::BE($b, 4); $ts = [UImg]::BE($b, 8); $size = [UImg]::BE($b, 12); $dcrc = [UImg]::BE($b, 24)
  $name = [Text.Encoding]::ASCII.GetString($b, 32, 32).TrimEnd([char]0)
  [byte[]]$h = $b[0..63]; $h[4] = 0; $h[5] = 0; $h[6] = 0; $h[7] = 0
  $sizeOk = ($size -eq $b.Length - 64)
  $dataOk = $sizeOk -and ([UImg]::Crc($b, 64, [int]$size) -eq $dcrc)
  $built = [DateTimeOffset]::FromUnixTimeSeconds($ts).ToString('yyyy-MM-dd')
  "{0}`n  name={1} built={2} sizeOK={3} headerCRC={4} dataCRC={5}" -f $p, $name, $built, $sizeOk, ([UImg]::Crc($h, 0, 64) -eq $hcrc), $dataOk
}
