# C source-only producer 준비 기록

c-producer-overlay-review-v2의 두 파일은 별도 검토 사본이다. 제품 파일에 적용하지 않았고 Godot parser나 실제 fixture는 실행하지 않았다. Source·overlay·정규화 diff의 SHA는 같은 폴더 SHA.json에 있다. 처음 사본의 script field observer는 _properties의 script-variable 비교에 영향을 줄 수 있어 v2에서는 Object metadata의 Callable로 이동했다.

- Detection._eval의 side 1 entry 직전에는 fixture가 명시 등록한 callback만 호출한다. 등록은 _detection의 a/b 한정이고 scope를 suffix 전에 해제한다. Raw fleet positions/formation offsets, stats, ship composition/stages, detection/formation configs, terrain zones 및 chain/skills 존재 여부를 읽는다. Detection.score나 기존 contacts를 기대값으로 복사하지 않는다.
- 첫/repaired _restore 각각의 primary/repeat, wrong-position direct call에 같은 wrapper를 연결했다. Wrapper는 실제 restore를 한 번 호출한 뒤 실제 반환을 돌려준다. Repeated no-effect 및 wrong-position fingerprint의 기존 short-circuit을 유지한다. Alias packet mutation 전후 source/target _all evidence를 별도 출력한다.
- 이 v2 draft는 decoder/geometry witness와 연결할 typed payload 원문을 제공한다. 원본 detach _check ID 개별 발행, suffix assertion stream, independent config/ship bound derivation, launcher run/Job identity와 결과 결합, immutable manifest, output size/time budget, 실제 GDScript 파싱은 아직 미검증이다. 큰 raw _all과 반복 config 직렬화가 만드는 출력량은 K6 전 별도 계약이 필요하다. 실제 producer 통합이 완성되었다고 판정하지 않는다.

제품 fixture를 사용하는 이 overlay의 실제 엔진 실행은 최초 제품 검증에 해당하므로 최종 독립 수용 전 실행하지 않는다. 별도의 비제품 ABI/managed sandbox 계획으로 이 행을 대신하지 않는다.
