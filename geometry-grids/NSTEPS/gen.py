#!/usr/bin/env python3
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def build_grid_map(max_coord):
    table = {}
    val = 0
    for k in range(0, max_coord + 5, 2):
        table[(k, k)] = val
        val += 1
        table[(k + 1, k + 1)] = val
        val += 1
        table[(k + 2, k)] = val
        val += 1
        table[(k + 3, k + 1)] = val
        val += 1
    return table


GRID = build_grid_map(10005)


def oracle(text):
    vals = [int(tok) for tok in text.split()]
    n = vals[0]
    out = []
    for i in range(n):
        x, y = vals[1 + 2 * i], vals[2 + 2 * i]
        out.append(str(GRID[(x, y)]) if (x, y) in GRID else "No Number")
    return "\n".join(out) + ("\n" if out else "")


assert oracle("3\n4 2\n6 6\n3 4\n") == "6\n12\nNo Number\n"
assert oracle("4\n0 0\n1 1\n2 0\n3 1\n") == "0\n1\n2\n3\n"


def write_case(name, pts):
    text = f"{len(pts)}\n" + "".join(f"{x} {y}\n" for x, y in pts)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", [(4, 2), (6, 6), (3, 4)])
write_case("2_edges", [(0, 0), (1, 1), (2, 0), (3, 1), (10000, 10000), (10000, 9998), (9999, 10000)])
write_case("3_wide", [(i, i) for i in range(0, 10001, 50)] + [(i + 2, i) for i in range(0, 9999, 50)])
rng = random.Random(1111)
rand_pts = [(rng.randint(0, 10000), rng.randint(0, 10000)) for _ in range(1000)]
write_case("4_random", rand_pts)
io_pts = [(i % 10001, i % 10001 if i % 2 == 0 else max(0, (i % 10001) - 2)) for i in range(40000)]
write_case("5_io", io_pts)
