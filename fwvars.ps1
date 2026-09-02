$out = "C:\Users\karst\pop-setup\fwvars.txt"
$l = @("Start $(Get-Date -Format HH:mm)")
try { $l += "SecureBoot: " + (Confirm-SecureBootUEFI) } catch { $l += "SecureBoot: " + $_.Exception.Message }
$code = @'
using System;
using System.Runtime.InteropServices;
public class Fw {
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
[Fw]::Enable()
function U16($b) { if ($b -and $b.Length -ge 2) { [BitConverter]::ToUInt16($b, 0) } else { $null } }
$cur = U16 ([Fw]::Get("BootCurrent"))
$l += "BootCurrent: " + ($(if ($cur -ne $null) { "Boot{0:X4}" -f $cur } else { "unbekannt" }))
$order = [Fw]::Get("BootOrder")
if ($order) { $ids = for ($i = 0; $i -lt $order.Length; $i += 2) { "Boot{0:X4}" -f [BitConverter]::ToUInt16($order, $i) }; $l += "BootOrder: " + ($ids -join ", ") }
$next = U16 ([Fw]::Get("BootNext"))
$l += "BootNext: " + ($(if ($next -ne $null) { "Boot{0:X4}" -f $next } else { "keins" }))
foreach ($i in 0..12) {
  $b = [Fw]::Get(("Boot{0:X4}" -f $i))
  if ($b) {
    $descBytes = $b[6..($b.Length-1)]
    $desc = [Text.Encoding]::Unicode.GetString($descBytes); $desc = $desc.Substring(0, $desc.IndexOf([char]0))
    $tail = [Text.Encoding]::Unicode.GetString($b) -replace '[^\x20-\x7E\\]', ''
    $path = if ($tail -match '(\\EFI\\[A-Za-z0-9_\\.\-]+)') { $Matches[1] } else { '' }
    $l += ("Boot{0:X4}: {1}  {2}" -f $i, $desc, $path)
  }
}
$l -join "`n" | Out-File $out -Encoding utf8
