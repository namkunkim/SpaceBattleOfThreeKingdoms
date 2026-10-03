# 탐지 재조정 기록 (진영 공유 탐지, 2026-10-03)

`EXPERIENCE-DESIGN.md` §8 "탐지 재조정"의 결과를 낸 에이전트 스크립트다. **기록 보존용**이다.

- `mkd.py` → `simd.py`: 세트 RX 시뮬레이터(`balance_rx/sim3.py`)에 탐지 옵션을 붙인 변형
- `grid2.py`: 변형 목록(JSON)을 실행한다. 예: `python -X utf8 grid2.py 표준,상급 100 f4.json`
- `dr.py`: 결과 집계, `tld.py`: 한 판의 사건 타임라인

변형 목록 JSON과 같은 폴더의 구버전 생성기를 import하는 구조다. 재현하려면 scratchpad의 `detect\` 폴더 전체가 필요하고, 시나리오 데이터는 조조군 x +150이 반영된 현재 값을 `cao_dx=0`으로 읽는다.
