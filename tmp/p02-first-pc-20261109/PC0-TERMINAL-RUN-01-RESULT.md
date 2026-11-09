# PC0 격리 기준선 실행 01 — 임포트 가드에서 중단

승인 SHA `4783b7dbad772643726a8cf7b253f353aa48f0481b732634afc3bc41436b1cc7`의 감독기를 기본 관리 샌드박스에서 1회 실행했다. 실행 직전 승인 파일·계획·12개 파트·두 엔진 해시, 1,470개 source manifest와 Git HEAD·인덱스·P03·worker, 신규 run 경로 부재를 확인했다. 아래 시각은 감독기가 남긴 UTC 원문 기준이다.

| 단계 | 실측 | 정리 |
|---|---|---|
| 격리 probe | 17:25:47.988Z, PID 34472. Godot 4.7.2, 전용 `run-01/appdata` 아래 `user://`와 별도 probe 프로젝트 확인. 엔진 exit 0. | Job active 0 |
| 리소스 임포트 | 17:25:48.686Z, PID 24456. 엔진 로그에는 Godot 버전 헤더만 남았다. 감독기가 `Unexpected child in Job` 예외로 중단했다. | 17:25:49.144Z Job active 0. 이 예외 경로에 import 엔진 exit code와 자식 PID·이미지는 기록되지 않았다. |
| 제품 GUI | launch 미도달. GUI 입력 0회, screenshot 0장, 전투 및 지도 결산 미측정. | 해당 없음 |

감독기 명령의 실제 exit code는 1이다. 터미널 원문은 다음과 같다.

```text
Frozen Git, source manifest and P03/worker matched
supervisor.ps1: Exception calling "Run" with "7" argument(s): "Unexpected child in Job"
```

두 소유 루트 PID는 사후 프로세스 조회에 없었다. 원본 user/cache inventory 파일은 실행 전후 SHA `c6e095a2ca413a2d61c419d7e19ec64ed2c78ca0775370cfb479747b5605a976`로 일치했다. 사후 Git·P03·worker 보호 확인도 통과했다. 임포트가 격리된 user 디렉터리에 남긴 `.recovery_mode_lock`을 비롯해 부분 결과는 보존했다.

원문은 [isolation.log](run-01/isolation.log), [isolation.os.tsv](run-01/isolation.os.tsv), [import.argv.json](run-01/import.argv.json), [import.log](run-01/import.log), [import.os.tsv](run-01/import.os.tsv)에 있다. 이 실행의 PC0은 미완료다. 5-a 전투/경로 판정기의 전제인 제품 trace와 UI 증거가 생성되지 않았다. 승인된 단일 시도는 소진됐다. 여덟째 후보 K6는 미실행이다.
