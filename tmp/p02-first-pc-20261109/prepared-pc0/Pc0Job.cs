using System;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class Pc0Job {
    const uint Suspended = 4, KillOnClose = 0x2000, WaitTimeout = 258;

    [StructLayout(LayoutKind.Sequential)]
    struct Startup {
        public int Size;
        public IntPtr Reserved, Desktop, Title;
        public int X, Y, XSize, YSize, XChars, YChars, Fill, Flags;
        public short Show, ReservedSize;
        public IntPtr Reserved2, Stdin, Stdout, Stderr;
    }
    [StructLayout(LayoutKind.Sequential)]
    struct Proc { public IntPtr Handle, Thread; public uint Pid, Tid; }
    [StructLayout(LayoutKind.Sequential)]
    struct Limits {
        public long ProcessTime, JobTime;
        public uint Flags;
        public UIntPtr WorkingSetMin, WorkingSetMax;
        public uint Active;
        public UIntPtr Affinity;
        public uint Priority, Scheduling;
        public ulong ReadOperations, WriteOperations, OtherOperations, ReadBytes, WriteBytes, OtherBytes;
        public UIntPtr ProcessMem, JobMem, PeakProcess, PeakJob;
    }
    [StructLayout(LayoutKind.Sequential)]
    struct Accounting {
        public long TotalUser, TotalKernel, PeriodUser, PeriodKernel;
        public uint Faults, Total, Active, Terminated;
    }
    [StructLayout(LayoutKind.Sequential)]
    struct Rect { public int Left, Top, Right, Bottom; }
    delegate bool EnumCallback(IntPtr hwnd, IntPtr param);
    [DllImport("kernel32", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern IntPtr CreateJobObject(IntPtr attributes, string name);
    [DllImport("kernel32", SetLastError=true)]
    static extern bool SetInformationJobObject(IntPtr job, int type, ref Limits info, uint len);
    [DllImport("kernel32", SetLastError=true)]
    static extern bool QueryInformationJobObject(IntPtr job, int type, out Accounting info, uint len, IntPtr ret);
    [DllImport("kernel32", SetLastError=true)]
    static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);
    [DllImport("kernel32", SetLastError=true)]
    static extern bool IsProcessInJob(IntPtr process, IntPtr job, out bool result);
    [DllImport("kernel32", SetLastError=true)]
    static extern bool TerminateJobObject(IntPtr job, uint exit);
    [DllImport("kernel32", SetLastError=true)]
    static extern bool TerminateProcess(IntPtr process, uint exit);
    [DllImport("kernel32", SetLastError=true)]
    static extern uint ResumeThread(IntPtr thread);
    [DllImport("kernel32", SetLastError=true)]
    static extern bool CloseHandle(IntPtr handle);
    [DllImport("kernel32", SetLastError=true)]
    static extern uint WaitForSingleObject(IntPtr handle, uint ms);
    [DllImport("kernel32", SetLastError=true)]
    static extern bool GetExitCodeProcess(IntPtr process, out uint code);
    [DllImport("kernel32", SetLastError=true)]
    static extern bool GetProcessTimes(IntPtr process, out long creation, out long exit, out long kernel, out long user);
    [DllImport("kernel32", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern bool QueryFullProcessImageName(IntPtr process, uint flags, StringBuilder result, ref uint size);
    [DllImport("kernel32", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern bool CreateProcess(string application, StringBuilder cmd, IntPtr processAttributes,
        IntPtr threadAttributes, bool inherit, uint flags, IntPtr environment, string cwd, ref Startup startup, out Proc process);
    [DllImport("user32")]
    static extern bool EnumWindows(EnumCallback callback, IntPtr param);
    [DllImport("user32")]
    static extern uint GetWindowThreadProcessId(IntPtr window, out uint pid);
    [DllImport("user32")]
    static extern IntPtr GetForegroundWindow();
    [DllImport("user32")]
    static extern bool IsWindowVisible(IntPtr window);
    [DllImport("user32")]
    static extern bool GetClientRect(IntPtr window, out Rect rect);
    [DllImport("user32")]
    static extern bool ClientToScreen(IntPtr window, ref Rect point);
    [DllImport("user32")]
    static extern uint GetDpiForWindow(IntPtr window);
    [DllImport("user32")]
    static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);

    static void Check(bool ok, string call) {
        if (!ok) throw new Win32Exception(Marshal.GetLastWin32Error(), call);
    }
    static void Record(string file, string fields) {
        File.AppendAllText(file, Environment.TickCount64 + "\t" + DateTime.UtcNow.ToString("O") + "\t" + fields + "\n");
    }
    static uint Active(IntPtr job) {
        Accounting a;
        Check(QueryInformationJobObject(job, 1, out a, (uint)Marshal.SizeOf(typeof(Accounting)), IntPtr.Zero), "Query job");
        return a.Active;
    }
    static string Window(uint pid) {
        IntPtr focus = GetForegroundWindow();
        IntPtr owned = IntPtr.Zero;
        int count = 0;
        EnumWindows(delegate(IntPtr w, IntPtr unused) {
            uint owner;
            GetWindowThreadProcessId(w, out owner);
            if (owner == pid && IsWindowVisible(w)) { count++; owned = w; }
            return true;
        }, IntPtr.Zero);
        Rect r, xy = new Rect();
        if (count != 1 || !GetClientRect(owned, out r) || !ClientToScreen(owned, ref xy))
            return "window\t" + count + "\t" + focus.ToInt64();
        return "window\t1\t" + focus.ToInt64() + "\t" + owned.ToInt64() + "\t" + pid + "\t" +
            xy.Left + "\t" + xy.Top + "\t" + r.Right + "\t" + r.Bottom + "\t" + GetDpiForWindow(owned);
    }

    public static uint Run(string exe, string cmd, string cwd, string events, string abort, int deadlineMs, bool product) {
        IntPtr job = CreateJobObject(IntPtr.Zero, null);
        Check(job != IntPtr.Zero, "Create private Job");
        Proc p = new Proc();
        bool assigned = false;
        try {
            var limit = new Limits { Flags = KillOnClose };
            Check(SetInformationJobObject(job, 9, ref limit, (uint)Marshal.SizeOf(typeof(Limits))), "Set kill-on-close");
            var startup = new Startup { Size = Marshal.SizeOf(typeof(Startup)) };
            Check(CreateProcess(exe, new StringBuilder(cmd), IntPtr.Zero, IntPtr.Zero, false, Suspended,
                IntPtr.Zero, cwd, ref startup, out p), "Create exact suspended GUI executable");
            Check(AssignProcessToJobObject(job, p.Handle), "Assign suspended process");
            assigned = true;
            bool member;
            Check(IsProcessInJob(p.Handle, job, out member) && member, "Verify Job membership");
            long created, exit, kernel, user;
            Check(GetProcessTimes(p.Handle, out created, out exit, out kernel, out user), "Read creation");
            var image = new StringBuilder(32768);
            uint length = (uint)image.Capacity;
            Check(QueryFullProcessImageName(p.Handle, 0, image, ref length), "Read image");
            if (!String.Equals(Path.GetFullPath(exe), image.ToString(), StringComparison.OrdinalIgnoreCase) || Active(job) != 1)
                throw new InvalidOperationException("Unexpected Job member or image");
            Record(events, "member\t" + p.Pid + "\t" + created + "\t" + image);
            var start = Environment.TickCount64;
            if (ResumeThread(p.Thread) != 1) throw new InvalidOperationException("ResumeThread failed");
            if (product)
                Check(SetThreadDpiAwarenessContext(new IntPtr(-4)) != IntPtr.Zero, "Set per-monitor DPI");
            string[] marker = { "brief", "resume", "terminal", "map" };
            int[] stageMs = { 180000, 180000, 1440000, 120000 };
            var stage = 0;
            var stageStart = start;
            while (true) {
                var status = WaitForSingleObject(p.Handle, 100);
                if (status == 0) break;
                if (status != WaitTimeout) throw new Win32Exception(Marshal.GetLastWin32Error(), "Wait process");
                if (Active(job) != 1) throw new InvalidOperationException("Unexpected child in Job");
                if (Environment.TickCount64 - start >= deadlineMs || File.Exists(abort))
                    throw new TimeoutException("PC0 deadline or controller abort");
                if (product) {
                    long now = Environment.TickCount64;
                    if (stage < marker.Length) {
                        if (now - stageStart >= stageMs[stage])
                            throw new TimeoutException("PC0 stage " + marker[stage]);
                        if (File.Exists(Path.Combine(Path.GetDirectoryName(events), marker[stage] + ".witness"))) {
                            Record(events, "witness\t" + marker[stage]);
                            stage++;
                            stageStart = now;
                        }
                    }
                    Record(events, Window(p.Pid));
                }
            }
            uint code;
            Check(GetExitCodeProcess(p.Handle, out code), "Read exit code");
            Record(events, "exit\t" + code);
            return code;
        } finally {
            try {
                if (assigned && Active(job) != 0)
                    Check(TerminateJobObject(job, 125), "Terminate private Job");
                if (!assigned && p.Handle != IntPtr.Zero && WaitForSingleObject(p.Handle, 0) == WaitTimeout)
                    Check(TerminateProcess(p.Handle, 126), "Terminate unassigned suspended process");
                if (p.Handle != IntPtr.Zero && WaitForSingleObject(p.Handle, 5000) != 0)
                    throw new TimeoutException("Owned root process did not exit during cleanup");
                var stop = Environment.TickCount64 + 5000;
                while (Active(job) != 0 && Environment.TickCount64 < stop) Thread.Sleep(50);
                var remaining = Active(job);
                Record(events, "cleanup\t" + remaining);
                if (remaining != 0) throw new InvalidOperationException("Job is not empty");
            } finally {
                if (p.Thread != IntPtr.Zero) CloseHandle(p.Thread);
                if (p.Handle != IntPtr.Zero) CloseHandle(p.Handle);
                CloseHandle(job);
            }
        }
    }
}
