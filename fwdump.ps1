$out = "C:\Users\karst\pop-setup\fwdump.txt"
$l = @()
$code = @'
using System;
using System.Runtime.InteropServices;
public class Fw2 {
  [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
  public static extern uint GetFirmwareEnvironmentVariableW(string lpName, string lpGuid, byte[] pBuffer, uint nSize);
  [DllImport("advapi32.dll", SetLastError = true)]
  public static extern bool OpenProcessToken(IntPtr h, uint access, out IntPtr tok);
  [DllImport("advapi32.dll", SetLastError = true)]
  public static extern bool LookupPrivilegeValue(string host, string name, out long luid);
  [DllImport("advapi32.dll", SetLastError = true)]
  public static extern bool AdjustTokenPrivileges(IntPtr tok, bool dis, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
  [DllImport("kernel32.dll")] public static extern IntPtr GetCurrentProcess();
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  public struct TokPriv1Luid { public int Count; public long Luid; public int Attr; }
  public static void Enable() {
    IntPtr tok; OpenProcessToken(GetCurrentProcess(), 0x28, out tok);
    TokPriv1Luid tp; tp.Count = 1; tp.Attr = 2; LookupPrivilegeValue(null, "SeSystemEnvironmentPrivilege", out tp.Luid);
    AdjustTokenPrivileges(tok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
  }
  public static byte[] Get(string name) {
    byte[] b = new byte[4096];
    uint n = GetFirmwareEnvironmentVariableW(name, "{8BE4DF61-93CA-11D2-AA0D-00E098032B8C}", b, 4096);
    if (n == 0) return null;
    byte[] r = new byte[n]; Array.Copy(b, r, n); return r;
  }
}
'@
Add-Type -TypeDefinition $code
[Fw2]::Enable()
foreach ($name in @("Boot0000","Boot0002","Boot0003")) {
  $b = [Fw2]::Get($name)
  if (-not $b) { $l += "$name fehlt"; continue }
  $l += "=== $name ($($b.Length) Bytes) ==="
  $fplLen = [BitConverter]::ToUInt16($b, 4)
  $descEnd = 6; while ($descEnd -lt $b.Length - 1 -and -not ($b[$descEnd] -eq 0 -and $b[$descEnd+1] -eq 0)) { $descEnd += 2 }
  $dp = $b[($descEnd+2)..($descEnd+1+$fplLen)]
  $i = 0
  while ($i -lt $dp.Length - 4) {
    $type = $dp[$i]; $sub = $dp[$i+1]; $len = [BitConverter]::ToUInt16($dp, $i+2)
    if ($len -lt 4) { break }
    $node = $dp[$i..($i+$len-1)]
    if ($type -eq 4 -and $sub -eq 1) {
      $partNum = [BitConverter]::ToUInt32($node, 4)
      $sig = [Guid]::new([byte[]]$node[24..39])
      $l += "  HD: Partition $partNum  GUID $sig"
    } elseif ($type -eq 4 -and $sub -eq 4) {
      $p = [Text.Encoding]::Unicode.GetString($node[4..($len-1)]) -replace "`0", ''
      $l += "  Datei: $p"
    } else { $l += "  Node Typ $type/$sub Laenge $len" }
    $i += $len
  }
}
$l += "--- Partition-GUIDs auf Disk 0 ---"
$l += (Get-Partition -DiskNumber 0 | ForEach-Object { "P$($_.PartitionNumber) $($_.Guid) $([math]::Round($_.Size/1GB,1)) GB" }) -join "`n"
$l -join "`n" | Out-File $out -Encoding utf8
