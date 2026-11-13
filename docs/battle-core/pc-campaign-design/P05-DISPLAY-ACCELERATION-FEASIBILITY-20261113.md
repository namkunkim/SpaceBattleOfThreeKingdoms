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

## 39척·30Hz 이동 순서 탐색

기존 258개 이동의 순서에서 서로 다른 함선의 인접 이동을 바꾼 중간 자세를 후보에 추가했다. 최대 24개 원래 이동 간격에서 후보 구간 13,720개를 기존 Sweep 검증기와 여유 0.001로 검사했다. 7,040개 구간이 정방향과 역방향 모두를 통과했다.

독립 검토에서 고정 방향·중심, 공백 없는 30Hz, 램프 비율 0.03인 시간표를 확인했다. **68개 위상·147프레임·4.900초**이며 최대 연속 가속도는 잠정 상한의 **0.971448배**였다. 같은 그래프에서 램프 비율 0.05는 153프레임·5.100초였다. 이 결과는 인증된 후보 자세와 프레임별 위상 경계 표시에 한정된다. 임의 갱신·공백, 제품 저크 기준, 전환 중 명령, 실제 표시와 권위 시계 연결은 추가 검증 범위다.

| 격리 산출물 | SHA-256 |
| --- | --- |
| [실험 기록](F:/WorkSpace/Campaign-Orchestration/P05-reordered-moves-20261113/RESULTS.md) | `765dc8f74e09104ffff29244c194594170e6d9511c3655e85b7b1aa473275814` |
| [Godot 양방향 검사](F:/WorkSpace/Campaign-Orchestration/P05-reordered-moves-20261113/graph-wide.out) | `223762259f7f01d3be073e7a34bf0259ac517b1a2914c07500f0d4e30a338785` |
| [Godot 추출 스크립트](F:/WorkSpace/Campaign-Orchestration/P05-reordered-moves-20261113/export-wide.gd) | `cc4696794ae2753eb12224990068ade4611a777b98f099e029d00e71a899f712` |
| [프레임 계산](F:/WorkSpace/Campaign-Orchestration/P05-reordered-moves-20261113/analyze-wide.py) | `7f425155f3399eaa6d6a3931d04ae2c8808c6ae038d66070868f8eab8c6bcc5d` |
| [램프 탐색](F:/WorkSpace/Campaign-Orchestration/P05-reordered-moves-20261113/ramp-search.py) | `da1314b10068c6b98f9bc1125c6cdf10b0ce4c4e2e5128a56c6e29cbc65eb524` |
| [147프레임 경로](F:/WorkSpace/Campaign-Orchestration/P05-reordered-moves-20261113/RESULT-RAMP-SEARCH.json) | `0687c9d4ce28e03bc6e7017db0218e45ff1f602e1b35f68e5549054ca4b39773` |

## 39척 경로의 헤드리스 렌더러 검증

기존 FleetRenderer의 선택 적용 경로에 시험 스크립트로 재구성한 68개 위상 시간표를 주입했다. 39척의 전환 구간을 여유 0.001로 양방향 재검증했고, 렌더러 슬롯 좌표가 그리는 구간도 양방향에서 안전했다. 같은 편성이라도 바인딩하지 않은 함대는 기존 표시 경로를 사용했다. 독립 검토는 이 시험 범위의 결과를 확인했다.

| 시계 조건 | 정방향 도착 | 역방향 도착 | 양방향 최대 차분 가속도 |
| --- | ---: | ---: | ---: |
| 30Hz 표시 시계 | 147프레임·4.900초 | 150프레임·5.000초 | 23,786.523056 |
| 10Hz 권위 스냅샷, 30Hz 표시 갱신 | 204프레임·6.800초 | 207프레임·6.900초 | 89,868.699646 |

역방향 시간표는 3프레임 정지 구간에서 시작한다. 표의 가속도는 실제 제출된 슬롯 좌표의 프레임 차분 값이며 단위는 전술 단위/s²다. 앞 절의 연속 가속도 분석값과 측정 방식이 다르다. 10Hz 시험에서는 안전 구간을 유지했지만 표시 시계가 요청 시점보다 뒤처졌고, 차분 가속도는 잠정 연속 기준 25,883.497247을 넘었다.

다음 검증 후보는 확인된 스냅샷 사이를 지연 보간하는 표시 시계다. 이상적 30Hz에서 10Hz 스냅샷 한 틱을 완충하면 정방향 5.000초·역방향 5.100초가 된다. 다른 후보는 최신 확인 시점까지만 표시를 진행하고, 정지점까지 필요한 구간이 확인된 뒤 위상을 시작하는 방식이다. 종료가 확정되면 동일한 종료 스냅샷을 고정한 채 안전 구간으로 표시를 마무리한다. 60·120Hz, 불규칙 갱신·공백, 전환 취소·재명령과 허용 지연·가속도 기준은 남아 있다. 공개 제품 명령이나 기본 렌더러에 연결한 변경은 없다.

| 격리 산출물 | SHA-256 |
| --- | --- |
| [표시 시계 스크립트](F:/WorkSpace/Campaign-Orchestration/P05-native-reordered-renderer-20261113/native_probe.gd) | `dc28fe14d80f4bff2487e6a0fb602dd644fe9c948052c1908942ed4f37dfd7ce` |
| [표시 시계 결과](F:/WorkSpace/Campaign-Orchestration/P05-native-reordered-renderer-20261113/native.out) | `7b34ae242dd90a89e74d33bfa0bdb9acadc677cf17808f2ddf78de2fc1f6cd7c` |
| [권위 스냅샷 스크립트](F:/WorkSpace/Campaign-Orchestration/P05-native-reordered-renderer-20261113/native_authority_probe.gd) | `ce2af903e42e49015b733f36f05a19fa81327f6983f826934d4c95f079b70d1e` |
| [권위 스냅샷 결과](F:/WorkSpace/Campaign-Orchestration/P05-native-reordered-renderer-20261113/authority-checked.out) | `969723372d3807d3a19194314bee42cc84492afcf49bc15786aa225c6d9238ce` |

## 확인된 위상만 표시하는 시계 실험

39척의 같은 68개 위상 램프 시간표를 사용했다. 합성 10Hz 권위 스냅샷에서 위상 끝까지 확인되면 정지점에서 시작해 30Hz 표시 갱신당 한 표본만 진행했다. 기존 렌더러 바인딩에 시험용 `sq.tick`을 전달했다. 이 값은 표시 표본 순번이며 실제 작전 권위 틱과 별개다. 역방향의 시작 정지 구간도 유지했다.

| 권위 스냅샷 조건 | 정방향 도착 | 역방향 도착 |
| --- | ---: | ---: |
| 정상 갱신 | 152프레임·5.067초 | 154프레임·5.133초 |
| 권위 갱신 11표시 프레임·366.7ms 억제 | 160프레임·5.333초 | 163프레임·5.433초 |

두 조건 모두 표시 갱신은 30Hz를 유지했다. 독립 검토에서 네 조건 모두 표시 진행이 확인 범위를 넘지 않았고, 제출 슬롯의 이동 구간이 안전했으며, 최대 차분 가속도는 23,786.523056 전술 단위/s²였다. 모든 도착 시간은 5초를 초과했다. 이 결과는 합성 스냅샷의 헤드리스 시험에 한정된다. 제품 권위 경로와 렌더러는 변경하지 않았다.

| 격리 산출물 | SHA-256 |
| --- | --- |
| [시험 스크립트](F:/WorkSpace/Campaign-Orchestration/P05-confirmed-frontier-renderer-20261113/frontier_probe.gd) | `cdedaa8297a0d984044d0f6ebf66dd6edd769b40b2b6babe47906ead9ba6ba3e` |
| [정상 갱신 로그](F:/WorkSpace/Campaign-Orchestration/P05-confirmed-frontier-renderer-20261113/frontier-0.out) | `7621ea239e098348c48c10cb0d8179b64e60626b12230cea06506aafee495410` |
| [권위 갱신 억제 로그](F:/WorkSpace/Campaign-Orchestration/P05-confirmed-frontier-renderer-20261113/frontier-1.out) | `29b5f78788fad19ab756b87a8a60fcc1568a50a0c6a805e21d3dff309d5d69b9` |
| [147프레임 입력 경로](F:/WorkSpace/Campaign-Orchestration/P05-reordered-moves-20261113/RESULT-RAMP-SEARCH.json) | `0687c9d4ce28e03bc6e7017db0218e45ff1f602e1b35f68e5549054ca4b39773` |

## 39척 확인 범위 정렬 표시

독립 검토에서 격리 Godot 헤드리스 시험 네 건을 확인했다. 기존 양방향 인증 그래프와 잠정 연속 가속도 상한을 유지했다. 램프 비율 0.01에서 양방향의 위상 길이를 각각 선택했다. 30Hz 표시 갱신마다 한 표본씩 진행했고, 합성 10Hz 권위 스냅샷으로 위상 끝이 확인되기 전에는 정지점에서 기다렸다. 표시 슬롯은 확인 범위를 넘지 않았으며 이동 구간은 양방향 모두 안전했다.

| 합성 권위 조건 | 정방향 표시 도착 | 역방향 표시 도착 | 시험용 표시 확정 |
| --- | ---: | ---: | ---: |
| 정상 | 149프레임·4.967초 | 149프레임·4.967초 | 양방향 150프레임·5.000초 |
| 표시 프레임 51–61의 권위 갱신만 억제 | 158프레임·5.267초 | 159프레임·5.300초 | 각각 158·159프레임 |

공백 조건에서도 표시 주사율은 30Hz였다. 권위 갱신만 11표시 프레임·366.7ms 동안 억제했다. 공백은 종료 이전에 해소되었고, 합성 권위 종료 기준은 150프레임이었다. 공백 시험의 표시 확정은 그 기준과 표시 도착을 모두 기다렸다. 이는 시험 어댑터의 확정 동작이며 제품 권위 결산 지연을 의미하지 않는다. 네 조건의 표시 좌표 최대 차분 가속도는 모두 22,913.480758667 전술 단위/s²였다. 실제 권위 연결, 불규칙 표시 갱신과 제품 저크 상한은 검증 범위 밖이다.

| 파일 | SHA-256 |
| --- | --- |
| [solve.py](F:/WorkSpace/Campaign-Orchestration/P05-frontier-aligned-20261113/solve.py) | `0439841822fe24521e4e4cdb074a6462f975b1dc40375e31a615095e5f05e6e3` |
| [RESULT.json](F:/WorkSpace/Campaign-Orchestration/P05-frontier-aligned-20261113/RESULT.json) | `2ffa837f94d19967e3405e8b2cc9d380f060b510adc36aeffd14cddf94f4db85` |
| [probe.gd](F:/WorkSpace/Campaign-Orchestration/P05-frontier-aligned-20261113/probe.gd) | `db0188faff33082d8c2f3025df3e8c92bd48eabe858908d8e0e89298c326c689` |
| [final-0.out](F:/WorkSpace/Campaign-Orchestration/P05-frontier-aligned-20261113/final-0.out) | `c700f8060837962e834f3328f4ba5e30e0f05de4e040f66a00a0c99f2e186d0e` |
| [final-1.out](F:/WorkSpace/Campaign-Orchestration/P05-frontier-aligned-20261113/final-1.out) | `a65af7cda40721c69465204534f79b572aee0fe3adaaa4f6e9704f6c7e02f69a` |
| [gap_probe.gd](F:/WorkSpace/Campaign-Orchestration/P05-frontier-aligned-20261113/gap_probe.gd) | `e21a5035ac980097ba2a8c2c801695ebfd23a50473ae0d4589ea00183fbc16bd` |
| [gap-0.out](F:/WorkSpace/Campaign-Orchestration/P05-frontier-aligned-20261113/gap-0.out) | `b95c00b8f537e030f706621f8c2f8e0e83a53580bab996ddcdb58ad5a293c8c3` |
| [gap-1.out](F:/WorkSpace/Campaign-Orchestration/P05-frontier-aligned-20261113/gap-1.out) | `1fdf50f35ad9f16aa05f52b248abcc3ac7bf49fcac7a002c306ab65f1ef0c873` |

## 실제 전투 코어 확인 범위와 39척 표시

승인된 적벽 v1 작전 소유자를 격리 메모리에서 준비했다. 공개 작전 어댑터는 진형 명령을 `unsupported_dev_command`로 거부했다. 시험에서만 `BattleSim.issue`와 `NativeTick.advance_combat`을 호출했다. 역방향 시작 상태는 실제 코어에서 정방향 명령을 완료해 만들었다. 각 방향에서 공개 코어 투영의 현재·목표 진형과 남은 시간을 읽어 50틱 카운트다운 및 완료를 확인했다.

30Hz 렌더러에는 고정 원점·방향의 시험용 슬롯을 사용했다. 표시 진행의 확인 범위는 실제 10Hz 코어 투영의 틱에서 얻었으며, 렌더러 바인딩에 넣은 합성 `sq.tick`은 표시 표본 순번이다. 정상 전달에서 정·역방향 모두 이동 145프레임과 대기 4프레임을 거쳐 **149프레임·4.967초**에 표시 위치가 도착했다. 코어 진형과 시험 표시 확정은 모두 **150프레임·5.000초**였다. 확인 범위 내 진행과 슬롯 이동 구간의 안전성을 확인했고, 최대 차분 가속도는 양방향 **22,913.480758667 전술 단위/s²**였다. 두 실행 모두 종료 코드 0이었고 독립 검토에서 해당 결과를 확인했다.

시험 작업본은 `c40e83f9`이고, 사용한 렌더러·전투 코어·작전 어댑터 경로는 기준 `c72150fd`와 Git 차이가 없었다. 공개 작전 명령의 허용과 제품 투영·렌더러 연결은 별도 검증 범위다. 이번 시험은 고정 자세와 정상 전달 조건을 사용했다.

재현 시 `F:/WorkSpace/.codex/worktree/p05-formation-20261113`에서 Godot 4.7.2 콘솔로 실행했다. 각 방향에서 `P05_REVERSE`는 각각 0과 1을 사용했고, `APPDATA`·`LOCALAPPDATA`·`SBTK_P05_TRANSITION_PROFILE`은 같은 방향별 격리 프로필로 설정했다.

```text
C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script F:/WorkSpace/Campaign-Orchestration/P05-native-authority-aligned-20261113/probe.gd --log-file F:/WorkSpace/Campaign-Orchestration/P05-native-authority-aligned-20261113/native-{0,1}.log
```

| 격리 근거 | SHA-256 |
| --- | --- |
| [시험 스크립트](F:/WorkSpace/Campaign-Orchestration/P05-native-authority-aligned-20261113/probe.gd) | `53385cab5247a41a0cd049bae4f80f955647800140e2bf0e00a7ae5c6f729c67` |
| [정방향 로그](F:/WorkSpace/Campaign-Orchestration/P05-native-authority-aligned-20261113/native-0.out) | `ef7792292abd30e2642d150481e502b148e407669adb81f3ea8d8fe86a9969c3` |
| [역방향 로그](F:/WorkSpace/Campaign-Orchestration/P05-native-authority-aligned-20261113/native-1.out) | `e96df783b1ca1e06c697f02ce24b46fbe48fe7cf08dc5059b40a7e7af451043f` |

## 39척 진형 전환의 시험용 저널 복원

39척 편성의 `FRM-01` 명령을 틱 0에 적용하고, 역방향 `FRM-03` 명령은 틱 50에 적용할 대기 항목으로 두었다. 전환 중인 틱 26에서 적용·대기 명령과 네이티브 상태 다이제스트를 시험용 JSON 파일에 기록했다. JSON을 다시 읽을 때 명령 틱을 정수로 정규화했다. 같은 Godot 헤드리스 시험 프로세스 안에서 새 적벽 v1 작전 소유자를 준비해 초기 상태부터 틱 26까지 재생했다. 틱 26의 네이티브 다이제스트와 대기 명령이 일치했다. 이후 75틱의 상태 다이제스트도 매 틱 일치했고, 진형 완료 이벤트는 틱 50에 `FRM-01`, 틱 100에 `FRM-03`으로 각각 한 번 발생했다. 최종 실행 종료 코드는 0이었고 독립 검토에서 이 결과를 확인했다.

저널 형식은 `p05-formation-journal-test/1`이며, 격리 시험에서 코어 명령 순서와 복원을 검증하는 데 사용했다. 공개 v1 진형 명령의 허용 범위와 제품 저장·재생 형식은 유지했다. 별도 프로세스 재개, 작전 소유자 전체 상태·원장과 공개 체크포인트·리플레이 연동은 추가 검증 범위다. 제품 연결에는 버전, 명령의 대상 편성·진형 식별자 및 기존 이동·보급·철수와의 순서를 정해야 한다.

| 격리 근거 | SHA-256 |
| --- | --- |
| [시험 스크립트](F:/WorkSpace/Campaign-Orchestration/P05-formation-journal-20261113/journal.gd) | `d2b3e42a23e3cd9a8e37dce5e2d80773f91411b21fb458c149d8a8497cb195ea` |
| [최종 로그](F:/WorkSpace/Campaign-Orchestration/P05-formation-journal-20261113/journal-final.out) | `a60116eb326e43b94bc9133d6a27d60f2320440cddfdbf8427dbe7cb1394e406` |
| [시험용 저널](F:/WorkSpace/Campaign-Orchestration/P05-formation-journal-20261113/profile/journal-test.json) | `bc8718fd65ae1f5eec259c1685fecc04c5427f3a69b2429311785981f9022ee4` |

## 39척 진형·이동·정지 명령 순서

같은 Godot 헤드리스 프로세스에서 승인 입력으로 두 적벽 v1 소유자를 준비했다. 시험 코드가 첫 코어에 명령을 발행하고, 생성된 명령 로그 13건을 동일 순서로 두 번째 코어에 전달했다. 두 번째 소유자에서는 편성 식별자 `RC-LIU-SQ-01`을 네이티브 ID로 다시 해석했다. 네이티브 상태 다이제스트는 81틱 모두 일치했다. 21척 동료 편성의 현재·목표 진형 필드는 유지됐다.

| 네이티브 명령 순서 | 관측 결과 |
| --- | --- |
| 같은 틱 이동 → 정지 | 이동 플래그 해제, 진형 전환 유지 |
| 같은 틱 정지 → 이동 및 같은 목표 진형 재지정 | 이동 플래그 유지, 전환 타이머 40틱 유지 |
| 현재 진형 지정 | 진행 중 전환 취소 |
| 같은 틱 취소 → 목표 진형 재지정 | 전환 타이머 50틱으로 재시작 |

`FRM-01` 완료 사건은 틱 80에 한 번 발생했다. 설정 확인을 포함한 9개 검사와 종료 코드 0을 독립 검토에서 확인했다. 시험은 `BattleSim.issue`와 `NativeTick.advance_combat`을 사용해 이동 플래그와 진형 상태를 비교했다. 작전 경로가 소유한 실제 위치 이동과 공개 v1 명령·저장·재생은 별도 검증 범위다. 제품 정책 후보는 전환 동안 이동 요청 거부, 안전한 정지점까지 지연, 또는 별도 인증을 받은 이동 중 전환이다. 확정할 정책은 명령 우선순위, 안정 편성 식별자, 재생 순서와 함께 버전 계약에 기록해야 한다.

실행 프로젝트는 `F:/WorkSpace/.codex/worktree/p05-formation-20261113`의 `c40e83f9`다. 관련 전투·렌더러·작전 어댑터 경로는 검증 기준 `cc8394ec`와 Git 차이가 없었다. 이 프로젝트에서 `APPDATA`·`LOCALAPPDATA`·`SBTK_P05_TRANSITION_PROFILE`을 동일한 새 격리 프로필로 지정하고 실행한다.

```text
C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script F:/WorkSpace/Campaign-Orchestration/P05-mixed-command-order-20261113/mixed.gd
```

| 격리 근거 | SHA-256 |
| --- | --- |
| [시험 스크립트](F:/WorkSpace/Campaign-Orchestration/P05-mixed-command-order-20261113/mixed.gd) | `94d1230c8530d71c6f32b7747c503a2f7e2a69539dab80f98b868e616459791f` |
| [시험 로그](F:/WorkSpace/Campaign-Orchestration/P05-mixed-command-order-20261113/mixed.out) | `d0441c1a994260f5349f5922b5be295ea7991bf99a220c6316c2989caa5488f1` |
