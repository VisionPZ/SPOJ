#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def shift_range(base, capacity):
    if capacity <= 0:
        return 0
    result = base << 1
    remaining = capacity - 1
    step = 1
    while remaining > 0:
        take = step if step < remaining else remaining
        result |= result << take
        remaining -= take
        step <<= 1
    return result


def oracle_case(q, fields, strips):
    mask = (1 << (q + 1)) - 1
    level_cap = 80 if q <= 5000 else 2
    reach = [1]
    for size in fields:
        old = reach
        new = old[:]
        for penalty in range(len(old)):
            new[penalty] |= (old[penalty] << size) & mask
            if penalty + 1 < level_cap:
                if penalty + 1 == len(new):
                    new.append(0)
                new[penalty + 1] |= shift_range(old[penalty], size - 1) & mask
        reach = [word & mask for word in new]
    for size in strips:
        old = reach
        new = old[:]
        for penalty in range(len(old)):
            if penalty + 1 < level_cap:
                if penalty + 1 == len(new):
                    new.append(0)
                new[penalty + 1] |= shift_range(old[penalty], size) & mask
        reach = [word & mask for word in new]
    for penalty, word in enumerate(reach):
        if (word >> q) & 1:
            return q - penalty
    raise AssertionError("no reachable answer")


def brute_case(q, fields, strips):
    dp = [-1] * (q + 1)
    dp[0] = 0
    for size in fields:
        nd = dp[:]
        for trees in range(q + 1):
            if dp[trees] < 0:
                continue
            for picked in range(1, size):
                if trees + picked <= q:
                    nd[trees + picked] = max(nd[trees + picked], dp[trees] + picked - 1)
            if trees + size <= q:
                nd[trees + size] = max(nd[trees + size], dp[trees] + size)
        dp = nd
    for size in strips:
        nd = dp[:]
        for trees in range(q + 1):
            if dp[trees] < 0:
                continue
            for picked in range(1, size + 1):
                if trees + picked <= q:
                    nd[trees + picked] = max(nd[trees + picked], dp[trees] + picked - 1)
        dp = nd
    return dp[q]


def oracle(cases):
    return "\n".join(str(oracle_case(*case)) for case in cases) + "\n"


def write(name, cases, raw_input=None):
    if raw_input is None:
        lines = [str(len(cases))]
        for q, fields, strips in cases:
            lines.append(f"{q} {len(fields)} {len(strips)}")
            lines.append(" ".join(str(value) for value in fields))
            lines.append(" ".join(str(value) for value in strips))
        input_text = "\n".join(lines) + "\n"
    else:
        input_text = raw_input
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


SAMPLE = [(17, [13, 4, 8], [4, 8, 6])]
SAMPLE_INPUT = "1\n17 3 3 \n13 4 8 \n4 8 6\n"

assert oracle_case(17, [13, 4, 8], [4, 8, 6]) == 17
assert oracle_case(32, [13, 4, 8], [4, 8, 6]) == 31
assert oracle_case(38, [13, 4, 8], [4, 8, 6]) == 36
assert oracle_case(150000, [150] * 1000, []) == 150000

check_rng = random.Random(31415)
for _ in range(300):
    q = check_rng.randint(0, 20)
    fields = [check_rng.randint(3, 6) for _ in range(check_rng.randint(0, 4))]
    strips = [check_rng.randint(2, 6) for _ in range(check_rng.randint(0, 4))]
    if sum(fields) + sum(strips) < q:
        continue
    assert oracle_case(q, fields, strips) == brute_case(q, fields, strips)

EDGES = [
    (0, [], []),
    (0, [3], [2]),
    (1, [3], []),
    (2, [3], []),
    (3, [3], []),
    (4, [3], [2]),
    (6, [3, 3], []),
    (7, [3, 3], [2]),
    (149, [150], []),
    (150, [150], []),
    (151, [150], [2]),
    (300, [150, 150], []),
    (301, [150, 150], [2]),
    (2, [], [2]),
    (3, [], [2, 2]),
    (32, [13, 4, 8], [4, 8, 6]),
    (38, [13, 4, 8], [4, 8, 6]),
]

WIDE = [
    (150000, [150] * 1000, []),
    (150000, [150] * 2000, []),
    (149999, [150] * 2000, []),
    (150000, [149] * 1010, []),
    (150000, [150] * 1000, [150] * 2000),
    (3000, [], [150] * 2000),
]

rng = random.Random(20261122)
RANDOM = []
for _ in range(20):
    fields = [rng.randint(3, 150) for _ in range(rng.randint(1, 2000))]
    strips = [rng.randint(2, 150) for _ in range(rng.randint(0, 2000))]
    extra = min(sum(strips), 1500)
    q = min(rng.randint(0, sum(fields) + extra), 150000)
    if q > 5000 and q > sum(fields):
        q = rng.randint(0, min(sum(fields), 150000))
    RANDOM.append((q, fields, strips))

IO = [(150000, [150] * 2000, [150] * 2000) for _ in range(20)]

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE, SAMPLE_INPUT)
write("2_edges", EDGES)
write("3_wide", WIDE)
write("4_random", RANDOM)
write("5_io", IO)
