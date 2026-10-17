/** Constant program: printer names and bytes arrive only as JSON on stdin, never as executable code. */
export const WINDOWS_RAW_SCRIPT = String.raw`
$ErrorActionPreference = 'Stop'
try {
  Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
public static class SmartShopRawPrinter {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
  public class DocInfo {
    [MarshalAs(UnmanagedType.LPWStr)] public string pDocName = "SmartShop POS";
    [MarshalAs(UnmanagedType.LPWStr)] public string pOutputFile = null;
    [MarshalAs(UnmanagedType.LPWStr)] public string pDatatype = "RAW";
  }
  [DllImport("winspool.drv", EntryPoint="OpenPrinterW", SetLastError=true, CharSet=CharSet.Unicode)]
  static extern bool OpenPrinter(string name, out IntPtr handle, IntPtr defaults);
  [DllImport("winspool.drv", EntryPoint="StartDocPrinterW", SetLastError=true, CharSet=CharSet.Unicode)]
  static extern uint StartDocPrinter(IntPtr handle, uint level, [In] DocInfo info);
  [DllImport("winspool.drv", SetLastError=true)] static extern bool StartPagePrinter(IntPtr handle);
  [DllImport("winspool.drv", SetLastError=true)] static extern bool WritePrinter(IntPtr handle, IntPtr data, uint count, out uint written);
  [DllImport("winspool.drv", SetLastError=true)] static extern bool EndPagePrinter(IntPtr handle);
  [DllImport("winspool.drv", SetLastError=true)] static extern bool EndDocPrinter(IntPtr handle);
  [DllImport("winspool.drv", SetLastError=true)] static extern bool AbortPrinter(IntPtr handle);
  [DllImport("winspool.drv", SetLastError=true)] static extern bool ClosePrinter(IntPtr handle);
  static void Check(bool result) { if (!result) throw new Win32Exception(Marshal.GetLastWin32Error()); }
  public static uint Send(string name, byte[] bytes) {
    IntPtr handle;
    Check(OpenPrinter(name, out handle, IntPtr.Zero));
    bool started = false, completed = false;
    GCHandle pinned = default(GCHandle);
    try {
      uint job = StartDocPrinter(handle, 1, new DocInfo());
      if (job == 0) throw new Win32Exception(Marshal.GetLastWin32Error());
      started = true;
      Check(StartPagePrinter(handle));
      pinned = GCHandle.Alloc(bytes, GCHandleType.Pinned);
      int offset = 0;
      while (offset < bytes.Length) {
        uint written;
        Check(WritePrinter(handle, IntPtr.Add(pinned.AddrOfPinnedObject(), offset), (uint)(bytes.Length-offset), out written));
        if (written == 0) throw new InvalidOperationException("Printer accepted zero bytes");
        offset += checked((int)written);
      }
      Check(EndPagePrinter(handle));
      Check(EndDocPrinter(handle));
      completed = true;
      return job;
    } finally {
      if (pinned.IsAllocated) pinned.Free();
      if (started && !completed) AbortPrinter(handle);
      ClosePrinter(handle);
    }
  }
}
'@
  $reader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
  $request = $reader.ReadToEnd() | ConvertFrom-Json
  $reader.Dispose()
  $bytes = [Convert]::FromBase64String($request.data)
  $job = [SmartShopRawPrinter]::Send([string]$request.printerName, $bytes)
  [Console]::Out.WriteLine((@{jobId=$job} | ConvertTo-Json -Compress))
} catch {
  [Console]::Error.WriteLine('The Windows printer queue did not accept the complete job.')
  exit 1
}
`;
