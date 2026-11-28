#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_dp(n, m):
    previous = [0] * (n + 2)
    previous[0] = 1
    for items in range(1, n + 1):
        current = [0] * (n + 2)
        for parts in range(1, items + 1):
            current[parts] = (parts * previous[parts] + previous[parts - 1]) & 1
        previous = current
    return previous[m]


def oracle_lucas(n, m):
    extra = n - m
    mask = (m - 1) // 2
    total = extra + mask
    bit = 0
    while (1 << bit) <= total:
        if ((mask >> bit) & 1) and not ((total >> bit) & 1):
            return 0
        bit += 1
    return 1


assert oracle_dp(4, 2) == 1
assert oracle_dp(4, 3) == 0
assert [oracle_lucas(8, parts) for parts in range(1, 9)] == [1, 1, 0, 1, 0, 0, 0, 1]
assert oracle_lucas(1000000000, 1000000000) == 1
for small_n in range(1, 121):
    for small_m in range(1, small_n + 1):
        assert oracle_dp(small_n, small_m) == oracle_lucas(small_n, small_m)


def emit(name, cases):
    input_lines = [str(len(cases))]
    output_lines = []
    for total, parts in cases:
        input_lines.append("%d %d" % (total, parts))
        output_lines.append(str(oracle_lucas(total, parts)))
    (ROOT / "in" / (name + ".txt")).write_text("\n".join(input_lines) + "\n")
    (ROOT / "out" / (name + ".out")).write_text("\n".join(output_lines) + "\n")


def random_cases(seed, count):
    rng = random.Random(seed)
    cases = []
    for _ in range(count):
        total = rng.randint(1, 1000000000)
        parts = rng.randint(1, total)
        cases.append((total, parts))
    return cases


emit("1_sample", [(4, 2)])

emit("2_edges", [
    (1, 1), (2, 1), (2, 2), (3, 2), (3, 3), (4, 2), (4, 3), (4, 4),
    (5, 2), (5, 4), (6, 3), (7, 5), (8, 6), (8, 8), (16, 8), (16, 16),
    (1000000000, 1), (1000000000, 2), (1000000000, 3),
    (999999999, 999999999), (999999999, 1), (999999937, 500000000),
    (1000000000, 999999999), (1000000000, 999999998),
    (1000000000, 1000000000),
])

emit("3_wide", [(1000000000, parts) for parts in range(1, 101)] +
                [(1000000000, 1000000000 - extra) for extra in range(100)])

emit("4_random", random_cases(20201124, 200))

rng_output = random.Random(3000)
emit("5_io", [(1000000000, rng_output.randint(1, 1000000000)) for _ in range(200)])

with open("/tmp/BINSTIRL_big.txt", "w") as stress_file:
    stress_cases = random_cases(4000, 200000)
    stress_file.write("%d\n" % len(stress_cases))
    for stress_total, stress_parts in stress_cases:
        stress_file.write("%d %d\n" % (stress_total, stress_parts))
