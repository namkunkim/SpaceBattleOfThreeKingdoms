class_name TestCheck
extends RefCounted

# assert는 실패하면 멈춰서 헤드리스 실행이 끝나지 않는다.
# 실패를 오류로 남기고 종료 코드 1로 끝낸다. 호출부는 false면 바로 return 한다.
static func ok(tree: SceneTree, cond: bool, msg: String = "") -> bool:
	if not cond:
		push_error("TEST_FAIL " + msg)
		tree.quit(1)
	return cond
