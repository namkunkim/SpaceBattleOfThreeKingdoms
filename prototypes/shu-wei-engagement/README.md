# 촉·위 함대 교전 연출

Godot 4.7.2에서 `project.godot`을 가져와 실행하면 34초 장면을 반복 재생한다. 시작으로 돌아가려면 Enter 또는 Space를 누른다. `engagement.tscn` 루트의 `engagement_distance` 속성으로 두 함대 선두 함선 사이의 거리를 조정할 수 있다. 기본값은 22 Godot 월드 단위다.

위·촉 각 60척은 오국 카메라 프로토타입의 3층 편성에 맞췄다. 편성은 전열함 5척, 모함 4척, 포격함 6척, 보급함 8척, 공성함 11척, 요격함 11척, 전자전함 9척, 고속정 6척이다.

전략 격자와 천체, 항성, 소행성대, 성운, 천체·성운 셰이더는 `origin/codex/wu-fleet-camera`의 10개 함대 영상 기준 리소스를 사용한다. 교전 좌표는 해당 월드의 소행성 구간에 배치했다. 위·촉의 항로와 전술 표식은 같은 카메라로 두 함대의 현재 월드 좌표를 투영한다.

## 모델 출처

모델은 `F:/WorkSpace/SpaceBattleOfRedCliff3D/SourceAssets`에서 인계받은 최종 리비전의 GLB다. 편집 원본 Blender 파일은 같은 리비전 폴더에 있다.

| 함종 | 위 | 촉 |
| --- | --- | --- |
| 전열함 | WeiFleet/BattleshipOriginal/R7/terra-luoyang.glb | ShuFleet/line-of-battle/R4/line-of-battle.glb |
| 모함 | WeiFleet/CarrierOriginal/R8/wei-carrier.glb | ShuFleet/assault-carrier/R4/assault-carrier.glb |
| 포격함 | WeiFleet/FireSupportOriginal/R7/wei-fire-support.glb | ShuFleet/yizhou-artillery/R3/yizhou-artillery.glb |
| 보급함 | WeiFleet/SupplyScratch-R9/wei-supply.glb | ShuFleet/supply-repair/R3/supply-repair.glb |
| 공성함 | WeiFleet/Additional/siege-ship/R4/wei-siege-ship.glb | ShuFleet/siege-ship/R3/siege-ship.glb |
| 요격함 | WeiFleet/Additional/interceptor/R5/interceptor.glb | ShuFleet/interceptor/R4/interceptor.glb |
| 전자전함 | WeiFleet/Additional/electronic-warfare/R4/wei-electronic-warfare.glb | ShuFleet/electronic-warfare/R4/electronic-warfare.glb |
| 고속정 | WeiFleet/Additional/fast-craft/R5/fast-craft.glb | ShuFleet/fast-attack/R4/fast-attack.glb |
