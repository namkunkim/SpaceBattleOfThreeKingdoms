# P05 표시 가속도 오프라인 검증 — 2026-11-13

격리 작업본 `c40e83f9`에서 Godot 4.7.2로 실제 39척·21척의 고정 방향 렌더러 경로와 위상 경계를 추출했다. 각 위상의 인증 여유는 0.001이다. 분석에서는 위상 시간을 표시 갱신 간격의 정수배로 올림했고, 공백 중에는 현재 위상 끝까지 진행한 뒤 다음 갱신을 기다렸다. 두 함대, 양방향, 30·60·120Hz, 공백 없음·0.35초·5초 조합 **36건**에서 최대 차분 가속도는 각각 원래 5차 경로의 분석 최대값 이하였다. 이 분석값은 예행 검증의 잠정 비교 기준이다.

| 표시 빈도 | 공백 없음 지연 | 0.35초 공백 지연 | 초기 5초 공백 지연 | 최대 차분/기준 |
| --- | ---: | ---: | ---: | ---: |
| 30Hz | 0.767–1.400초 | 0.983–1.717초 | 5.667–6.333초 | 0.79 |
| 60Hz | 0.333–0.650초 | 0.517–0.950초 | 5.233–5.600초 | 0.92 |
| 120Hz | 0.175–0.375초 | 0.417–0.700초 | 5.083–5.333초 | 0.98 |

지연은 권위 완료 시점인 5초 이후의 표시 시간이다. 시작부터 표시 완료까지 공백 없이 **5.175–6.400초**, 초기 5초 공백에서 **10.083–11.333초**였다. 0.35초 공백은 약 1.7초에 한 번 적용했다. 제품 가속도 상한과 완료 시한은 미확정이다. 이동·선회, 전환 중 새 명령, 임의 가변 주사율과 실제 화면 성능 검증이 남아 있다. 제품 동작 변경은 없다.

| 격리 산출물 | SHA-256 |
| --- | --- |
| [36개 결과](F:/WorkSpace/Campaign-Orchestration/P05-display-governor-20261113/RESULT.json) | `5f58ff740098f269685eccb7c0a7617f495f08a763fb7f8c732618e86ac4ad84` |
| [Godot 경로 추출](F:/WorkSpace/Campaign-Orchestration/P05-display-governor-20261113/schedule.out) | `953de0780c73b24e09581dfb8628afd3f0797074936d66fc866c2405b2c75c06` |
| [분석 스크립트](F:/WorkSpace/Campaign-Orchestration/P05-display-governor-20261113/analyze.py) | `0d41722a6b28e4d95a58a4485cc6dd59b1c277e3be622006c15308399d07c3f0` |
| [원본 분석 기록](F:/WorkSpace/Campaign-Orchestration/P05-display-governor-20261113/RESULTS.md) | `46adeae5793aa2cf2d3db30e2e1af26691e39b9fdecbfe93a44233e95e6842ca` |

## 고정 주사율에서 위상별 최소 시간

기존 인증 순서(39척 78개 위상, 21척 41개 위상)와 5차 보간을 유지했다. 갱신 공백 없이 30·60·120Hz로 고정했고 모든 위상 경계를 프레임에 표시했다. 이 조건에서 잠정 연속 가속도 기준을 지키는 최소 프레임 수와, 표시 좌표의 차분만 제한했을 때의 최소 프레임 수를 각각 계산했다.

| 편성 | 갱신 빈도 | 연속 기준 최소 프레임 / 초 | 차분 기준 최소 프레임 / 초 |
| --- | ---: | ---: | ---: |
| 39척 | 30Hz | 192 / 6.400 | 97 / 3.233 |
| 39척 | 60Hz | 339 / 5.650 | 270 / 4.500 |
| 39척 | 120Hz | 645 / 5.375 | 609 / 5.075 |
| 21척 | 30Hz | 173 / 5.767 | 120 / 4.000 |
| 21척 | 60Hz | 320 / 5.333 | 305 / 5.083 |
| 21척 | 120Hz | 621 / 5.175 | 613 / 5.108 |

연속 기준의 최소 시간은 여섯 조건 모두 5초를 초과했다. 차분 기준에서 5초 이내인 세 조건의 프레임 사이 연속 가속도는 잠정 기준의 5.57–7.40배였다. 이 최소값은 위의 경로·보간·경계 표시 제약에 한정된다. 다른 경로나 갱신 방식은 별도 검증 범위다. 제품 기준과 동작은 변경하지 않았다.

| 격리 산출물 | SHA-256 |
| --- | --- |
| [분석 기록](F:/WorkSpace/Campaign-Orchestration/P05-display-frame-optimum-20261113/RESULTS.md) | `4fc9b26890a45b365554f0bc7590e3a540e8cf22ff2f4ebad91929a45e03717f` |
| [상세 결과](F:/WorkSpace/Campaign-Orchestration/P05-display-frame-optimum-20261113/RESULT.json) | `05aaa0220d0364e3855020706b42eebea886d2142b5e0369488e6e7bd726bad9` |
| [재현 스크립트](F:/WorkSpace/Campaign-Orchestration/P05-display-frame-optimum-20261113/optimize.py) | `acf18018800ed42c7c01c7dcb4a961f1a75d5dbe71f5ff61a7f208263ddd1c10` |

## 기존 위상 경계 병합

39척 경로의 경계 쌍 3,081개와 21척 경로의 861개를 기존 Sweep 검증기의 여유 0.001로 검사했다. 통과 구간은 역방향에서도 확인했다. 39척은 인접 구간 외 두 구간을 추가로 통과해 78개 위상을 76개로 줄였다. 21척은 인접 구간 41개를 유지했다.

| 편성 | 30Hz 최소 프레임 / 초 | 60Hz 최소 프레임 / 초 | 120Hz 최소 프레임 / 초 |
| --- | ---: | ---: | ---: |
| 39척 | 188 / 6.267 | 331 / 5.517 | 629 / 5.242 |
| 21척 | 173 / 5.767 | 320 / 5.333 | 621 / 5.175 |

기존 경계 순서, 5차 보간, 공백 없는 고정 갱신 및 잠정 연속 가속도 기준을 적용한 최소값이다. 기존 경계 병합만으로는 여섯 조건 모두 5초를 초과했다. 새 경유 자세와 제품 기준은 별도 검증 범위다. 런타임 변경은 없다.

| 격리 산출물 | SHA-256 |
| --- | --- |
| [분석 기록](F:/WorkSpace/Campaign-Orchestration/P05-phase-merge-20261113/RESULTS.md) | `70ff01512e899ec81e378cb42425f2c45e3240ebdb31bdb0420730e2a7c3f28f` |
| [상세 결과](F:/WorkSpace/Campaign-Orchestration/P05-phase-merge-20261113/RESULT.json) | `61b6381700154d78d328717cc6cec9bcb6dd3c3da236078169d5c05b20f6705c` |
| [Godot 검증 출력](F:/WorkSpace/Campaign-Orchestration/P05-phase-merge-20261113/merges.out) | `1901506b448be8120c7ed3a73982997a18f524d8e427b060d71e9b51c6a3182d` |
| [Godot 추출 스크립트](F:/WorkSpace/Campaign-Orchestration/P05-phase-merge-20261113/export_merges.gd) | `8227337a1314dea47c1102687c8f84dc4c328dca449e8c67158e319d067d1640` |
| [최소 프레임 계산](F:/WorkSpace/Campaign-Orchestration/P05-phase-merge-20261113/optimize_merges.py) | `0d90e0baf31a4b24eafa5c51cdf1d76ca10d67e476e16b2100cfb97979435d47` |

## 위상 중간 자세를 경유하는 지름길

각 인증 위상의 중간 자세를 후보로 추가했다. 최대 여덟 반위상 간격에서 중간 자세가 포함된 구간 1,384개를 기존 Sweep 검증기와 여유 0.001로 검사했다. 39척은 914개 중 166개, 21척은 470개 중 82개를 양방향으로 통과했다. 기존 경계만 사용한 최단 경로를 대조군으로 유지했다.

39척은 30·60·120Hz에서 한 프레임씩 줄어 **187 / 330 / 628프레임(6.233 / 5.500 / 5.233초)**이었다. 21척은 **173 / 320 / 621프레임(5.767 / 5.333 / 5.175초)**을 유지했다. 고정 방향·공백 없는 갱신·잠정 연속 가속도 기준에서 여섯 조건 모두 5초를 초과했다. 독립 검토는 이 제한된 탐색과 결과를 확인했다. 제품 동작과 완료 조건은 기존 상태를 유지한다.

| 격리 산출물 | SHA-256 |
| --- | --- |
| [상세 결과](F:/WorkSpace/Campaign-Orchestration/P05-midpoint-shortcuts-20261113/RESULT.json) | `8dd762c5616364b552aff0b9a46ea7206614da1502455bdaf13027b696376400` |
| [Godot 검사 출력](F:/WorkSpace/Campaign-Orchestration/P05-midpoint-shortcuts-20261113/midpoints.out) | `38e89a115e6a7a29fec939ecdd9880087532be854597856857227eea752b59ba` |
| [Godot 추출 스크립트](F:/WorkSpace/Campaign-Orchestration/P05-midpoint-shortcuts-20261113/export_midpoints.gd) | `f857659cd660e9f2e3bd69b2c4dea10d9450fcc3bdab7d5e855dbbc06fbba431` |
| [최소 프레임 계산](F:/WorkSpace/Campaign-Orchestration/P05-midpoint-shortcuts-20261113/optimize_midpoints.py) | `6c0006591c1c1dfcffa3eac026859b4915502eea82d11d430d965df650276597` |

## 연속 가속도 램프 시간표

기존·중간 자세의 양방향 인증 구간과 여유 0.001을 재사용했다. 5차 보간 대신 각 위상의 시작과 끝에서 속도·가속도가 0인 대칭 가속도 램프를 적용했다. 끝 램프가 위상 시간에서 차지하는 비율을 r로 두면 최대 가속도 계수는 4/(1−2r)이다. 함대별 기존 5차 경로의 분석 최대값을 잠정 연속 가속도 기준으로 유지하고, 각 위상의 최소 시간을 정수 프레임으로 올렸다. 독립 검토에서 이 조건의 시간표를 확인했다.

| 편성 | r | 30Hz | 60Hz | 120Hz |
| --- | ---: | ---: | ---: | ---: |
| 39척 | 0.05 | 5.567초 | 4.850초 | 4.600초 |
| 21척 | 0.05 | 4.933초 | 4.667초 | 4.542초 |
| 39척 | 0.10 | 5.967초 | 5.200초 | 4.808초 |
| 21척 | 0.10 | 5.433초 | 5.017초 | 4.833초 |

r=0.05에서 두 편성 모두 60·120Hz에서 5초 이내였다. 39척·30Hz는 r이 0에 접근하는 경우에도 **157프레임·5.233초**가 하한이다. 이 하한은 현재 인증 그래프, 위상별 정지 및 프레임 경계 표시, 잠정 연속 가속도 기준에 한정된다. 고정 중심·방향, 공백 없는 고정 주사율의 오프라인 실험이다. 가변 갱신, 공백, 제품 저크·완료 기준은 별도 검증 범위다.

| 격리 산출물 | SHA-256 |
| --- | --- |
| [실험 기록](F:/WorkSpace/Campaign-Orchestration/P05-ramped-acceleration-20261113/RESULTS.md) | `307d0b89c10bf263c557620f4ae1cd5f9b326b392123c3851ae57e30e3d9aff4` |
| [12개 시간표](F:/WorkSpace/Campaign-Orchestration/P05-ramped-acceleration-20261113/RESULT.json) | `6b6eeb45f69c4139c3073209e496a8ff7577694bf5ab067e56b38d95a6149550` |
| [시간표 계산](F:/WorkSpace/Campaign-Orchestration/P05-ramped-acceleration-20261113/analyze.py) | `cd640c87a68cf8d8dc311ac94e60dbdff549947d11fc63cc4c00cb309c9cb912` |
| [39척·30Hz 하한](F:/WorkSpace/Campaign-Orchestration/P05-ramped-acceleration-20261113/LIMIT-30HZ.json) | `e259ec2938c9d3c96d4cef6324be69362c259fc59b3b3d964cb56a99aa963985` |
