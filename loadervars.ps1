$out = "C:\Users\karst\pop-setup\loadervars.txt"
$l = @("Start $(Get-Date -Format HH:mm:ss)")
$code = @'
using System;
using System.Runtime.InteropServices;
public class Fw3 {
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
  public static string Get(string name) {
    byte[] b = new byte[4096];
    uint n = GetFirmwareEnvironmentVariableW(name, "{4a67b082-0a4c-41cf-b6c7-440b29bb8c4f}", b, 4096);
    if (n == 0) return null;
    return System.Text.Encoding.Unicode.GetString(b, 0, (int)n).TrimEnd('\0');
  }
}
'@
Add-Type -TypeDefinition $code
[Fw3]::Enable()
foreach ($n in @("LoaderInfo","LoaderEntrySelected","LoaderEntryDefault","LoaderEntryOneShot","LoaderTimeMenuUSec","LoaderTimeInitUSec","LoaderEntries","LoaderFirmwareInfo")) {
  $v = [Fw3]::Get($n)
  $l += "$n = " + $(if ($null -eq $v) { "(nicht vorhanden)" } else { $v })
}
$l += "Boot-Zeit Windows: " + (Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToString("HH:mm:ss")
$l -join "`n" | Out-File $out -Encoding utf8
