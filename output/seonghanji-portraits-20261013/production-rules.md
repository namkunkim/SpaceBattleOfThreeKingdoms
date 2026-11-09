# 확정 제작 규칙

- 문서 출처: `C:/WorkSpace/Seonghanji/docs/02-characters/`.
- 원본 스타일 참고: `C:/Users/nk782/Downloads/image_f1772f7f.jpg`.
- 내장 `image_gen` 도구를 사용해 각 인물을 별도 생성한다.
- 최종 PNG: **561×701픽셀**, 최초 조조 초상 1122×1402의 가로·세로 각각 절반.
- **이미지 내부 글자·이름·태그·명패 금지**. 이름과 식별 정보는 `tags.json` / `tags.csv`에 분리한다.
- 파일 연결: `id` → `images/<id>.png`. 동명이인은 `id`와 `faction`으로 구분한다.
- 여러 인종 및 혼혈 인물을 세력·역할 전반에 배치한다. 외모·인종 설정은 SF 세계관의 창작 해석이다.
- 여성 20명은 모두 아름다운 **성인 여성**으로 표현하며 각 인물의 역할과 제복·갑옷을 유지한다.
- 중단 시 `manifest.json`의 `generated` 인물은 건너뛰고 `pending` 인물부터 재개한다.
- `prepare.cjs`는 최초 명단 추출 기록이며 기존 manifest가 있으면 재실행을 막는다.
- `next.cjs 5`로 다음 인물 5명의 프롬프트를 확인한다. `next.cjs 1 female`로 미완료 여성 인물만 확인한다.
- 내장 생성 결과를 `resize.ps1`로 요청된 크기에 맞춘 후 `save-result.cjs`로 완료 상태와 식별 파일을 갱신한다.
- `verify.ps1`로 완료 파일 존재 여부, PNG 규격, 식별 파일의 전체 인원수를 확인한다.
- `index.html`은 완료 이미지 검색용 목록이며 PNG에 이름·태그를 합성하지 않는다.
