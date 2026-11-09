# Python Job v3 단일 실행 독립 결과 심사

판정: **실패 1회, 0/6 통과. 자동 재시도 금지.** `PYTHON-JOB-V3-ONE-SHOT-RESULT.md` SHA `0b50c813ed791ab266b31ae85a70077427fd063cda8c446a9c07ad652620f0c1`, evidence JSON SHA `ba6873cce8f0f41dcf66d1586aae36bc796086c2cae362a7ff734cb1b7fad2cf` 확인. 심사 모델 gpt-6.1-terra. 이 심사에서 추가 프로세스·Job·제품·Godot은 실행하지 않았다.

원문 `normal/outer.jsonl` SHA `7c60a868a29217e0ca524cd1ecb19ff9f9faba76639cc9992cae703164be59a9`은 case-start 후 case-running의 owned drain true, broker exit 125, payload PID null·inner receipt false 및 보유 Python PID 21620 signalled를 보여 준다. 외부 stderr SHA `45f6b1cc6a54bea83cd33756ac4dadd1eea8bb177950b775eae084083534fc8c`의 최초 오류는 supervisor `observe_owned_engine_handles()`의 `unexpected owned image`이고 정리 중 `payload not observed in outer Job`이 뒤따른다. 후자는 최초 원인의 증거가 아니다. external journal SHA `3381b09dd281618397d4d6e76f35bc6cb95f060bf78868f4af44cf964cda7578`은 exit 1, owned_drained/output_complete true, sentinel journal SHA `a41603ce4ca62dec91c42cabfe05db38481c21447a550a01210fb473f237778a`은 정상 exit 0을 기록한다. 관측된 범위의 정리만 증명하며 payload 존재·정상 종료나 나머지 다섯 사례 통과는 증명하지 않는다.

실제 거부된 이미지 경로·PID·creation time이 오류 원문에 없다. 따라서 경로 정규화, Python 리다이렉션, 예상 밖 진짜 자손, 관측 경합 중 어느 원인도 확인되지 않았다. 허용 목록을 넓히거나 실패를 무시해 통과시키면 원래 소유 경계를 무너뜨린다. 보호 대상 14 입력/6 파일 및 HEAD/ref 전후 일치는 전달 기록에 있고 시점 간 변화 부재나 다른 경로 전체 불변을 뜻하지 않는다. 기존 scratch·원문·승인 manifest와 K1~K5/K6 잔여 1회를 보존한다. 본 Python 비제품 1회 실패는 제품 K6이 아니나 Python 시험 시도 기록을 지우거나 새 계획에서 0으로 초기화하지 않는다. 최초 승인된 one-shot은 이미 종료돼 동일 승인으로 재실행할 수 없다.

재개를 위한 최소 독립 계획은 먼저 read-only 정적 분석으로 API가 반환한 image 값을 오류 직전에 보존하지 못하는 지점을 명시하고, 새로운 진단 전용 후보에서 **해당 owned Job의 보유 HANDLE**에 한해 PID·creation time·raw image path·정규화 값·기대 allowlist·membership·오류 시점을 bounded 외부 원문에 저장하도록 설계하는 것이다. 기존 실패를 덮지 않고 실패 원인과 cleanup 실패를 각각 보존하며, 경로 값만 보고 제3 프로세스를 조작하지 않는다. 정적 synthetic에서 실제 미일치·동일 경로 spelling·단명 프로세스·PID 재사용·출력 누락 및 거부 분기를 검사한다. 추가 실제 시험이 필요하면 원인 가설과 K 상한에 이 실패를 포함한 잔여 예산, 새 scratch·정확 immutable manifest/argv 및 소유 종료 경계를 먼저 정의해 독립 재심한다. 원인 확인 전 allowlist 변경이나 임의 재시도는 금지한다.

GUI per-request provenance, 실제 Godot child 및 전체 Job 적합성은 여전히 미확인이다. 제품 fixture/import는 수행하지 않았으며 마지막 제품 K6은 남아 있다. 이 결과는 ABI·GUI 또는 21행 통과의 근거가 아니다.

