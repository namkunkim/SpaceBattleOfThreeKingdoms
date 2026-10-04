# 전투 효과음

`python tools/gen_sfx.py`로 합성한다(표준 라이브러리만 쓰고, 외부 자산이 아니라서 라이선스 문제가 없다). 44.1kHz 16bit 모노 WAV. 소리를 고치려면 생성기 함수를 고치고 다시 실행한다.

| 파일 | 용도 | 길이 |
|---|---|---|
| `laser_light` | 경레이저포 단발 | 0.4초 |
| `laser_heavy` | 주포 레이저(충전 뒤 발사) | 1.5초 |
| `beam_loop` | 지속 빔 (루프) | 2.0초 |
| `volley` | 근접 방어포 연사 · 기존 사건 `volley` | 0.1초 |
| `salvo` | 주포 일제사격 · 기존 사건 `salvo` | 1.2초 |
| `missile_launch` | 미사일 발사 | 1.6초 |
| `missile_hit` | 미사일 명중 폭발 | 1.3초 |
| `fighter_launch` | 함재기 사출·발진 | 2.0초 |
| `fighter_guns` | 함재기 기관포 | 0.5초 |
| `fighter_dock` | 함재기 회수·도킹 | 0.8초 |
| `engine_loop` | 함선 순항 엔진 (루프) | 3.0초 |
| `engine_boost` | 가속·추진 점화 | 1.8초 |
| `shield_hit` | 보호막 피격 | 1.0초 |
| `armor_hit` | 장갑 피격 | 0.5초 |
| `ship_kill` | 함선 격침 · 기존 사건 `ship_kill` | 1.8초 |
| `fleet_destroyed` | 전대 괴멸(대폭발과 2차 폭발) · 기존 사건 `fleet_destroyed` | 3.8초 |
| `chain_explosion` | 연쇄 폭발(연환 대형 화공) | 2.6초 |
| `fire_ignite` | 화공 발동 | 1.6초 |
| `fire_loop` | 번지는 불 (루프) | 3.0초 |

- 기존 사건 이름과 같은 4종은 `hud/ui_kit/ui_sound.gd`가 합성 임시음 대신 바로 쓴다.
- `*_loop`는 WAV `smpl` 청크에 루프 구간을 넣었다. Godot가 `loop_mode=Forward`로 임포트한다.
- UI 효과음(버튼·경보 등)은 지금처럼 `ui_sound.gd`의 합성음을 쓴다.
