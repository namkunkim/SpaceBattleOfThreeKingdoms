# P08 PresentMon offline fixture verification

PresentMon Console 2.6.0 x64 read the official Gold test case 2 from disk with `--etl_file`. The run exited 0. The output matched all 26 expected CSV headers and all 56 ordered data rows for PID 1300 byte-for-byte per line, and contained only PID 1300. The test verifies offline replay, PID filtering and the v2 metrics CSV for this fixture.

[PresentMon v2.6.0 Gold fixture](https://github.com/GameTechDev/PresentMon/tree/e13fce6acdb55a808fd8318175a56863e532d95f/Tests/Gold) · [Upstream test documentation](https://github.com/GameTechDev/PresentMon/blob/e13fce6acdb55a808fd8318175a56863e532d95f/Tests/README.md)

The ETL and expected CSV matched their upstream Git blob IDs. The upstream repository ships them as Gold test fixtures under its MIT license. The public Gold CSV contains executable basenames and numeric metrics. The check found no paths, email addresses, or populated input latency values in that CSV. Upstream does not describe whether the ETL itself was sanitized.

| Artifact | SHA-256 | Upstream Git blob |
| --- | --- | --- |
| Existing PresentMon-2.6.0-x64.exe | B2A706BC6AD475749E3B7E3409263AA1E6906D45BDCF993F6DBC0F660188F1AF | |
| test_case_2.etl | 71194538CF20CCE3ADA1FEBCE98DD12E978920DB00ADEE7FDD1AF2886983FAF3 | 6149f180b21e511c6ad2eaed7ee45a60686e2f77 |
| test_case_2_v2.csv | C59EE6459DD3977B10B3E096A0C9598649DD1F1029758027F2DF4E03D0D4D7E9 | 49e22cbf1f85e5fc2fb7e6e2866575949cba8b8a |
| pid-1300.csv | 810B9920425A4CFA0E8EE9C2684077C7997BC3405173105476F68A4160F5EE74 | |

From this directory, the executed command was equivalent to:

```powershell
& ../P08-presentmon-preflight-7f138c2d-01/PresentMon-2.6.0-x64.exe --etl_file ./test_case_2.etl --process_id 1300 --output_file ./pid-1300.csv --no_console_stats --v2_metrics --qpc_time --track_gpu_video --track_frame_type --track_app_timing
```
