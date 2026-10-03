class_name PocSetup
extends RefCounted

# POC 편성(적벽 회랑 데모). M2에서 data/scenarios/의 정본 편성으로 바꾼다.

const ALLY_DEF := [
	{"name": "유비", "role": "사령관 · 기함 전대", "ships": 120, "lv": 12, "x": 620, "y": 1150, "flag": true, "p": 0},
	{"name": "관우", "role": "제1분함대", "ships": 108, "lv": 8, "x": 840, "y": 960, "p": 1},
	{"name": "제갈량", "role": "제2분함대", "ships": 108, "lv": 7, "x": 840, "y": 1340, "p": 2},
	{"name": "조운", "role": "제3분함대 · 고속", "ships": 96, "lv": 9, "x": 1000, "y": 830, "spd": 1.18, "p": 3},
	{"name": "마초", "role": "제4분함대 · 고속", "ships": 96, "lv": 6, "x": 1000, "y": 1470, "spd": 1.18, "p": 5},
	{"name": "장비", "role": "제5분함대 · 전위", "ships": 100, "lv": 10, "x": 1040, "y": 1150, "p": 1},
]
const FOE_DEF := [
	{"name": "조조", "role": "원정군 총사령", "ships": 125, "lv": 12, "x": 2950, "y": 1150, "flag": true, "wait": 0, "p": 4},
	{"name": "하후돈", "role": "위 제2분함대", "ships": 110, "lv": 9, "x": 2500, "y": 880, "wait": 5, "p": 5},
	{"name": "조인", "role": "위 제3분함대", "ships": 105, "lv": 8, "x": 2500, "y": 1420, "wait": 9, "p": 5},
	{"name": "장료", "role": "위 선봉", "ships": 100, "lv": 7, "x": 2330, "y": 1150, "wait": 0, "p": 4},
	{"name": "서황", "role": "위 제4분함대", "ships": 95, "lv": 6, "x": 2680, "y": 680, "wait": 20, "p": 3},
	{"name": "악진", "role": "위 제5분함대", "ships": 95, "lv": 7, "x": 2680, "y": 1620, "wait": 16, "p": 3},
	{"name": "허저", "role": "위 친위대", "ships": 95, "lv": 10, "x": 2780, "y": 1150, "wait": 28, "p": 5},
]
const REINF_DEF := [
	{"name": "하후연", "role": "위 별동대", "ships": 85, "lv": 8, "x": 3300, "y": 260, "wait": 0, "spd": 1.15, "p": 4},
	{"name": "장합", "role": "위 별동대", "ships": 85, "lv": 9, "x": 3300, "y": 2040, "wait": 0, "spd": 1.15, "p": 5},
]
