#!/usr/bin/env python3
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def oracle_dnc(arr, queries):
    ans = [0] * len(queries)
    q_list = [(l - 1, r - 1, idx) for idx, (l, r) in enumerate(queries)]

    def solve(lo, hi, items):
        if not items:
            return
        if lo == hi:
            val = arr[lo]
            for _, _, idx in items:
                ans[idx] = val
            return
        mid = (lo + hi) // 2
        left_items = []
        right_items = []
        cross_items = []
        for l, r, idx in items:
            if r <= mid:
                left_items.append((l, r, idx))
            elif l > mid:
                right_items.append((l, r, idx))
            else:
                cross_items.append((l, r, idx))
        if cross_items:
            sz_l = mid - lo + 1
            best_suff = [0] * sz_l
            cur_sum = 0
            cur_best = -10**18
            run_pref = 0
            best_inside_l = [0] * sz_l
            max_end = -10**18
            dp_cur = 0
            for pos in range(mid, lo - 1, -1):
                cur_sum += arr[pos]
                if cur_sum > cur_best:
                    cur_best = cur_sum
                dp_cur = max(arr[pos], dp_cur + arr[pos])
                if dp_cur > max_end:
                    max_end = dp_cur
                k = pos - lo
                best_suff[k] = cur_best
                best_inside_l[k] = max_end

            sz_r = hi - mid
            best_pref = [0] * sz_r
            best_inside_r = [0] * sz_r
            cur_sum = 0
            cur_best = -10**18
            max_end = -10**18
            dp_cur = 0
            for pos in range(mid + 1, hi + 1):
                cur_sum += arr[pos]
                if cur_sum > cur_best:
                    cur_best = cur_sum
                dp_cur = max(arr[pos], dp_cur + arr[pos])
                if dp_cur > max_end:
                    max_end = dp_cur
                k = pos - (mid + 1)
                best_pref[k] = cur_best
                best_inside_r[k] = max_end

            for l, r, idx in cross_items:
                kl = l - lo
                kr = r - (mid + 1)
                cand = max(best_inside_l[kl], best_inside_r[kr], best_suff[kl] + best_pref[kr])
                ans[idx] = cand
        solve(lo, mid, left_items)
        solve(mid + 1, hi, right_items)

    solve(0, len(arr) - 1, q_list)
    return ans


def oracle_brute(arr, queries):
    out = []
    for l, r in queries:
        best = -10**18
        for i in range(l - 1, r):
            cur = 0
            for j in range(i, r):
                cur += arr[j]
                if cur > best:
                    best = cur
        out.append(best)
    return out


assert oracle_dnc([-1, 2, 3], [(1, 2)]) == [2]
assert oracle_dnc([-5, -2, -8], [(1, 3), (2, 2)]) == [-2, -2]
assert oracle_dnc([-1, 2, 3], [(1, 3), (1, 1), (2, 3)]) == oracle_brute([-1, 2, 3], [(1, 3), (1, 1), (2, 3)])


def write_case(name, arr, queries):
    text = f"{len(arr)}\n" + " ".join(str(x) for x in arr) + f"\n{len(queries)}\n" + "".join(f"{l} {r}\n" for l, r in queries)
    ans = oracle_dnc(arr, queries)
    if len(arr) <= 100 and len(queries) <= 100:
        assert ans == oracle_brute(arr, queries)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text("".join(f"{x}\n" for x in ans))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", [-1, 2, 3], [(1, 2)])
write_case("2_edges", [-15007, -15007, -15007, 15007], [(1, 3), (1, 1), (4, 4), (1, 4)])
write_case("3_wide", [15007] * 50000, [(1, 50000), (1, 1), (50000, 50000), (100, 49900)])
rng = random.Random(1043)
arr_r = [rng.randint(-15007, 15007) for _ in range(5000)]
q_r = []
for _ in range(5000):
    a = rng.randint(1, 5000)
    b = rng.randint(a, 5000)
    q_r.append((a, b))
write_case("4_random", arr_r, q_r)
arr_max = [rng.randint(-15007, 15007) for _ in range(50000)]
q_max = []
for _ in range(100000):
    a = rng.randint(1, 50000)
    b = rng.randint(a, 50000)
    q_max.append((a, b))
write_case("5_io", arr_max, q_max)
