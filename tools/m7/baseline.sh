#!/bin/bash
# M7 AI 대 AI 기준선: 난이도별 시드 묶음을 병렬로 돌려 user://m7_<난이도>_<시작>.json에 요약을 남긴다.
# 환경변수 EXTRA(추가 인자, 예 "--cao-fleets 14"), TAG(출력 이름 꼬리표). 사용: tools/m7/baseline.sh <난이도> <총 시드> <병렬 수> [시작 시드]   (Godot 경로는 G, 기본 C:\Tools\Godot)
G=${G:-/c/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe}
diff=$1; total=$2; par=$3; from=${4:-0}
per=$(( (total + par - 1) / par ))
for ((i=0; i<par; i++)); do
  s=$(( from + i * per ))
  "$G" --headless --path . -s tests/autoresolve.gd -- --profile red_cliffs --difficulty "$diff" --policies none --from $s --runs $per --rows 1 $EXTRA --out "user://m7_${diff}${TAG}_${s}.json" 2>&1 | grep -E "none:" &
done
wait
