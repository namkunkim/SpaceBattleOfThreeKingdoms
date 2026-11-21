extends RefCounted


static func collect(source: Dictionary, eligible: Callable) -> Dictionary:
	if not source.ok:
		return source
	var parents := {}
	for parent_id: String in source.head.completed:
		var receipt: Dictionary = source.head.completed[parent_id]
		var settlement: Dictionary = receipt.settlement
		if not eligible.call(settlement):
			continue
		var digest := JSON.stringify([parent_id, receipt], "", true, true).sha256_text()
		parents[settlement.id] = {"parent_id": parent_id, "digest": digest, "receipt": receipt}
	return {"ok": true, "parents": parents}
