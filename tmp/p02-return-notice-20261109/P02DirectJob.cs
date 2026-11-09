using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class P02DirectJob {
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
    [StructLayout(LayoutKind.Sequential)]
    struct Completion { public IntPtr Key, Port; }
    sealed class Seen { public IntPtr Handle; }

    [DllImport("kernel32", EntryPoint="SetInformationJobObject", SetLastError=true)]
    static extern bool SetCompletion(IntPtr job, int kind, ref Completion info, uint size);
    [DllImport("kernel32", EntryPoint="QueryInformationJobObject", SetLastError=true)]
    static extern bool QueryJobBuffer(IntPtr job, int kind, IntPtr buffer, uint len, IntPtr ret);
    [DllImport("kernel32", SetLastError=true)]
    static extern IntPtr CreateIoCompletionPort(IntPtr file, IntPtr port, IntPtr key, uint threads);
    [DllImport("kernel32", SetLastError=true)]
    static extern bool GetQueuedCompletionStatus(IntPtr port, out uint bytes, out IntPtr key, out IntPtr data, uint ms);
    [DllImport("kernel32", SetLastError=true)]
    static extern IntPtr OpenProcess(uint access, bool inherit, uint pid);

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
    static bool Member(IntPtr handle, IntPtr job) {
        bool member;
        Check(IsProcessInJob(handle, job, out member), "Query membership");
        return member;
    }
    static string Image(IntPtr handle) {
        var image = new StringBuilder(32768);
        uint size = (uint)image.Capacity;
        return QueryFullProcessImageName(handle, 0, image, ref size) ? image.ToString() : null;
    }
    static string HashImage(string path) {
        if (path == null) return "unavailable";
        try {
            using (var file = File.OpenRead(path))
            using (var sha = System.Security.Cryptography.SHA256.Create())
                return BitConverter.ToString(sha.ComputeHash(file)).Replace("-", "");
        } catch (IOException) { return "unavailable"; }
          catch (UnauthorizedAccessException) { return "unavailable"; }
    }
    static uint[] JobPids(IntPtr job) {
        for (var capacity = 8; capacity <= 4096; capacity *= 2) {
            int bytes = 8 + capacity * IntPtr.Size;
            IntPtr buffer = Marshal.AllocHGlobal(bytes);
            try {
                if (!QueryJobBuffer(job, 3, buffer, (uint)bytes, IntPtr.Zero)) {
                    if (Marshal.GetLastWin32Error() == 234) continue;
                    throw new Win32Exception(Marshal.GetLastWin32Error(), "Query own Job process list");
                }
                int assigned = Marshal.ReadInt32(buffer);
                int listed = Marshal.ReadInt32(buffer, 4);
                if (assigned > listed) continue;
                if (assigned < 0 || assigned != listed || listed > capacity)
                    throw new InvalidOperationException("Inconsistent Job PID list header");
                var result = new uint[listed];
                var unique = new HashSet<uint>();
                for (int i = 0; i < listed; i++) {
                    result[i] = checked((uint)Marshal.ReadIntPtr(buffer, 8 + i * IntPtr.Size).ToInt64());
                    if (result[i] == 0 || !unique.Add(result[i]))
                        throw new InvalidOperationException("Inconsistent Job PID list");
                }
                return result;
            } finally { Marshal.FreeHGlobal(buffer); }
        }
        throw new InvalidOperationException("Job PID snapshot exceeded bounded capacity");
    }
    static void Notifications(IntPtr port, IntPtr job, string events) {
        for (int i = 0; i < 256; i++) {
            uint message;
            IntPtr key, data;
            if (!GetQueuedCompletionStatus(port, out message, out key, out data, 0)) {
                if (Marshal.GetLastWin32Error() == WaitTimeout) return;
                throw new Win32Exception(Marshal.GetLastWin32Error(), "Read Job notifications");
            }
            if (key != job) throw new InvalidOperationException("Foreign Job notification");
            Record(events, "job_notice\t" + message + "\t" + data.ToInt64());
        }
        Record(events, "job_notice\tbatch_limit");
    }
    static void Snapshot(IntPtr job, IntPtr port, Proc root, string events, string stage,
        Dictionary<string, Seen> retained) {
        uint[] pids = JobPids(job);
        Record(events, "job_snapshot\t" + stage + "\t" + string.Join(",", pids));
        if (stage == "before_resume" && Array.IndexOf(pids, root.Pid) < 0)
            throw new InvalidOperationException("Suspended root absent from its Job snapshot");
        foreach (uint pid in pids) {
            if (pid == root.Pid && WaitForSingleObject(root.Handle, 0) == WaitTimeout)
                continue; // The independently held, exact root handle is logged separately.
            IntPtr process = OpenProcess(0x00101000, false, pid); // SYNCHRONIZE | QUERY_LIMITED_INFORMATION
            if (process == IntPtr.Zero) {
                Record(events, "member_unavailable\t" + pid + "\topen\t" + Marshal.GetLastWin32Error());
                continue;
            }
            try {
                bool member;
                if (!IsProcessInJob(process, job, out member) || !member) {
                    Record(events, "member_unavailable\t" + pid + "\tmembership_unconfirmed");
                    continue;
                }
                long created, exit, kernel, user;
                if (!GetProcessTimes(process, out created, out exit, out kernel, out user)) {
                    Record(events, "member_unavailable\t" + pid + "\tcreation_unavailable");
                    continue;
                }
                string identity = pid + ":" + created;
                if (retained.ContainsKey(identity)) continue;
                if (retained.Count >= 256)
                    throw new InvalidOperationException("Retained identity capacity exceeded");
                string image = Image(process);
                // Child image paths are observations, not file inputs to the watchdog.
                Record(events, "owned_identity\t" + pid + "\t" + created + "\tconfirmed\t" +
                    (image ?? "unavailable") + "\tnot-collected");
                retained.Add(identity, new Seen { Handle = process });
                process = IntPtr.Zero;
            } finally { if (process != IntPtr.Zero) CloseHandle(process); }
        }
        Notifications(port, job, events);
    }
    static long Deadline(long absolute, long stage, long now) {
        return Math.Min(Math.Min(absolute, stage), now + 10000);
    }
    static void FlushReceipt(string events) {
        using (var file = new FileStream(events, FileMode.Open, FileAccess.Write, FileShare.Read))
            file.Flush(true);
    }

    public static uint Run(string exe, string cmd, string cwd, string events, string abort, int deadlineMs, uint expectedExit) {
        IntPtr job = CreateJobObject(IntPtr.Zero, null);
        Check(job != IntPtr.Zero, "Create private Job");
        Proc p = new Proc();
        IntPtr port = IntPtr.Zero;
        bool assigned = false, resumed = false, natural = false;
        var retained = new Dictionary<string, Seen>();
        try {
            var limit = new Limits { Flags = KillOnClose };
            Check(SetInformationJobObject(job, 9, ref limit, (uint)Marshal.SizeOf(typeof(Limits))), "Set kill-on-close");
            port = CreateIoCompletionPort(new IntPtr(-1), IntPtr.Zero, IntPtr.Zero, 1);
            Check(port != IntPtr.Zero, "Create private Job completion port");
            var association = new Completion { Key = job, Port = port };
            Check(SetCompletion(job, 7, ref association, (uint)Marshal.SizeOf(typeof(Completion))), "Associate completion port");
            var startup = new Startup { Size = Marshal.SizeOf(typeof(Startup)) };
            Check(CreateProcess(exe, new StringBuilder(cmd), IntPtr.Zero, IntPtr.Zero, false, Suspended,
                IntPtr.Zero, cwd, ref startup, out p), "Create exact suspended GUI executable");
            Check(AssignProcessToJobObject(job, p.Handle), "Assign suspended process");
            assigned = true;
            if (!Member(p.Handle, job)) throw new InvalidOperationException("Root Job membership false");
            long created, exit, kernel, user;
            Check(GetProcessTimes(p.Handle, out created, out exit, out kernel, out user), "Read root creation");
            string image = Image(p.Handle);
            string imageHash = HashImage(image);
            if (!String.Equals(Path.GetFullPath(exe), image, StringComparison.OrdinalIgnoreCase) ||
                imageHash != "AB1824F85BFD8E0E4128182C000C4003A3E042245B2967848D089B2A04B22424")
                throw new InvalidOperationException("Root image identity mismatch");
            Record(events, "member\t" + p.Pid + "\t" + created + "\t" + image + "\t" + imageHash);
            Snapshot(job, port, p, events, "before_resume", retained);
            if (File.Exists(abort)) throw new OperationCanceledException("Controller abort before resume");
            var start = Environment.TickCount64;
            if (ResumeThread(p.Thread) != 1) throw new InvalidOperationException("ResumeThread failed");
            resumed = true;
            Record(events, "resume\t" + p.Pid);
            long nextSnapshot = start;
            while (true) {
                uint status = WaitForSingleObject(p.Handle, 100);
                long now = Environment.TickCount64;
                if (now - start >= deadlineMs || File.Exists(abort))
                    throw new TimeoutException("P02 direct headless deadline or controller abort");
                if (status == 0) break;
                if (status != WaitTimeout) throw new Win32Exception(Marshal.GetLastWin32Error(), "Wait root process");
                if (now >= nextSnapshot) {
                    Snapshot(job, port, p, events, "running", retained);
                    nextSnapshot = now + 250;
                }
            }
            uint code;
            Check(GetExitCodeProcess(p.Handle, out code), "Read signaled root exit code");
            Record(events, "exit\t" + code);
            if (code != expectedExit)
                throw new InvalidOperationException("Unexpected actual root exit");
            long drain = Deadline(start + deadlineMs, long.MaxValue, Environment.TickCount64);
            Snapshot(job, port, p, events, "root_signaled", retained);
            while (Active(job) != 0) {
                if (Environment.TickCount64 >= drain || File.Exists(abort))
                    throw new TimeoutException("Owned Job drain deadline or controller abort");
                Thread.Sleep(100);
                Snapshot(job, port, p, events, "drain", retained);
            }
            if (Environment.TickCount64 >= drain || File.Exists(abort))
                throw new TimeoutException("Owned Job drain deadline or controller abort");
            natural = true;
            return code;
        } catch (Exception error) {
            Record(events, "supervisor_error\t" + error.GetType().Name + "\t" + error.Message);
            throw;
        } finally {
            try {
                long stop = Environment.TickCount64 + 10000;
                if (assigned && Active(job) != 0) {
                    Record(events, "cleanup_request\tterminate_job");
                    Check(TerminateJobObject(job, 125), "Terminate private Job");
                }
                if (!assigned && p.Handle != IntPtr.Zero && WaitForSingleObject(p.Handle, 0) == WaitTimeout) {
                    Record(events, "cleanup_request\tterminate_suspended_root");
                    Check(TerminateProcess(p.Handle, 126), "Terminate unassigned suspended root");
                }
                uint rootSignal = p.Handle == IntPtr.Zero ? 0 : WaitForSingleObject(p.Handle,
                    (uint)Math.Max(0, stop - Environment.TickCount64));
                uint rootCode = 0;
                if (p.Handle != IntPtr.Zero && rootSignal == 0)
                    Check(GetExitCodeProcess(p.Handle, out rootCode), "Read root cleanup exit code");
                Record(events, "root_cleanup\t" + (p.Handle != IntPtr.Zero) + "\t" + resumed +
                    "\t" + rootSignal + "\t" + rootCode + "\t" + natural);
                while (Active(job) != 0 && Environment.TickCount64 < stop) Thread.Sleep(50);
                uint remaining = Active(job);
                Exception snapshotError = null;
                if (assigned) {
                    try { Snapshot(job, port, p, events, "cleanup", retained); }
                    catch (Exception error) {
                        snapshotError = error;
                        Record(events, "cleanup_snapshot_error\t" + error.GetType().Name + "\t" + error.Message);
                    }
                }
                bool membersDone = true;
                foreach (var identity in retained) {
                    uint signal = WaitForSingleObject(identity.Value.Handle,
                        (uint)Math.Max(0, stop - Environment.TickCount64));
                    uint code = 0;
                    string memberExit = signal == 0 && GetExitCodeProcess(identity.Value.Handle, out code)
                        ? code.ToString() : "unavailable";
                    Record(events, "owned_cleanup\t" + identity.Key + "\t" + signal + "\t" + memberExit);
                    membersDone &= signal == 0;
                }
                Record(events, "cleanup\t" + remaining);
                FlushReceipt(events);
                if (rootSignal != 0 || remaining != 0 || !membersDone || snapshotError != null)
                    throw new InvalidOperationException("Owned Job cleanup did not converge", snapshotError);
            } finally {
                foreach (var identity in retained.Values) CloseHandle(identity.Handle);
                if (p.Thread != IntPtr.Zero) CloseHandle(p.Thread);
                if (p.Handle != IntPtr.Zero) CloseHandle(p.Handle);
                CloseHandle(job);
                if (port != IntPtr.Zero) CloseHandle(port);
            }
        }
    }
}

