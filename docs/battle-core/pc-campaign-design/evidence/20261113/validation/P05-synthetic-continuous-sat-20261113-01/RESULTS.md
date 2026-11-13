# P05 synthetic continuous SAT results

Proposal SHA-256 `F7945C651845AD8F31E1BF96EEECEE301AE41AB5EE38B92605F5DB01C63E1988` verified before implementation. Reproduce with `python continuous_sat.py` using Python 3.10 or later and the standard library. The saved stdout records 33 assertions.

The oracle takes fixed, already oriented, nondegenerate convex hulls as cyclic point tuples with exact integer or rational coordinates. It supports one affine leg per hull, held at its endpoint poses outside its leg, and takes an explicitly closed analysis window in ms. For every edge normal of both hulls, it derives two projection inequalities on B's relative offset, maps their bounds to time, and intersects the resulting intervals. The piecewise helper cuts at both hulls' start/end events. In strict interior mode the infimum can be excluded, which the returned flag records.

## Hand-derived expected values

- The two centered unit-halfwidth squares meet when relative x lies in [-2, 2], with both bounds excluded for interior overlap. The crossing x=t−4 has interval [2, 6] and both endpoints miss. A fixed y=2 gives edge contact only. With y=21/10 there is a gap, and y=19/10 gives interior overlap on (2, 6).
- The two unit diamonds meet when |x|+|y| ≤ 2. At y=2, x=t−4 gives a single vertex contact at t=4. At y=1/2, x=t−4 yields [5/2, 11/2] on [0, 6], and x=2−t yields its time reversal [1/2, 7/2]. Both oblique crossings have strict open bounds. At (3/2, 3/2) the two diamonds are separated.
- A square's greatest x+y is 2. The diamond translated by (7/4, 7/4) has smallest x+y=5/2, so the hulls are disjoint although their x and y projections overlap.
- At x=2+t/4 only t=0 is contact. At x=1+t/2 the strict interval is [0, 2), with attained infimum 0.
- With one hull moving 0→4 during [0, 4] and one moving 5→1 during [2, 6], the x offset is at least 3 through t=2. On [2, 4] it is 7−2t and first reaches 2 at t=5/2. Swapping hulls negates the offset without changing the result. In the single moving/static crossing, splitting exactly at 2 gives an included hit in the preceding segment for contact mode and an excluded infimum in the following segment for strict mode.

The run covers synthetic geometry for P05 checklist line 20. Product owner decisions for actual hulls, slot mappings, timing, contact and positive clearance remain separate. Euclidean clearance, roster validation, real radial bounds, dynamic heading and product runtime verification are outside this artifact's scope.
