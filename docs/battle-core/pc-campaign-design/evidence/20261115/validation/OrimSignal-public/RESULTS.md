# 〈오림의 마지막 신호〉 Windows 단일 PC 인수

2026-11-15 KST. Windows 1600×900 전경과 Godot 4.7.2 헤드리스에서 새 격리 프로필을 사용했다. 실제 〈퇴로의 등불〉 성공·포기 결산을 시험 사본으로 반입했다.

| 검증 | 결과 |
| --- | --- |
| 작전 규칙 | 26/26. 반경 경계, 이동 중 경합, 적 재점령과 아군 탈환, 정비 1회, 지휘 전대 손실·시한 우선순위, 포기 및 결정적 재생을 확인했다. |
| 공개 지도·저장·재개 | 37/37. 네 프로세스에서 처음 출격, 송신 중 329틱 저장, 새 프로세스 재개, 결산 재조회, 실패 부모 거부를 확인했다. 대기 명령은 한 번 실행됐고 소비 사건은 재발행되지 않았다. 실전 호스트와 내부 재생의 사건 순서·상태·449틱 성공 결산이 일치했다. 검증된 구출 척수는 최초·재개·결산에서 표시됐다. |
| Win32 운영 슬롯 | 51/51. 다섯 프로세스에서 실제 작성자 경합, 504틱 복원, 확정 명령 소급 삽입 거부, 교체 실패 및 재시도, 같은 부모의 결산 재조회와 원본 파일 보존을 확인했다. |
| Windows 1600×900 전경 | 격리 디버그 실행에서 실제 공개 메뉴, 두 전대 이동, 송신 완료 44.9초와 적벽 결산 화면 복귀를 확인했다. 송신 중 저장 및 프로세스 재시작은 위 공개 통합 시험에서 검증했다. |
| 별도 모델 리뷰 | 구현 전 작전 정의·범위를 확인했다. 구현 후 누락된 구출 척수 표시를 수정한 뒤 독립 재검토를 통과했다. 표시용 반환 필드만 추가한 슬롯 소스를 역적용한 SHA-256이 Win32 51건 검증본과 일치했다. |

## 원본 근거

- [작전 규칙 26건 로그](F:/WorkSpace/Campaign-Orchestration/OrimRuntime-r2/engine.log)
- [공개 저장](F:/WorkSpace/Campaign-Orchestration/Orim-public-20261115-r2/save.log) · [별도 프로세스 재개](F:/WorkSpace/Campaign-Orchestration/Orim-public-20261115-r2/resume.log) · [결산 재조회](F:/WorkSpace/Campaign-Orchestration/Orim-public-20261115-r2/receipt.log) · [실패 부모](F:/WorkSpace/Campaign-Orchestration/Orim-public-20261115-r2/failure.log) · [프로세스 결과](F:/WorkSpace/Campaign-Orchestration/Orim-public-20261115-r2/processes.jsonl)
- [Win32 운영 슬롯 51건](F:/WorkSpace/Campaign-Orchestration/Orim-slot-Win32-20261115-03/RESULTS.md) · [구조화 결과](F:/WorkSpace/Campaign-Orchestration/Orim-slot-Win32-20261115-03/result.json)
