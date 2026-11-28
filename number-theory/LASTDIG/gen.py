#!/usr/bin/env python3
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def oracle(text):
    vals = [int(tok) for tok in text.split()]
    t = vals[0]
    return "".join(f"{pow(vals[1 + 2 * i], vals[2 + 2 * i], 10)}\n" for i in range(t))


assert oracle("2\n3 10\n6 2\n") == "9\n6\n"
assert oracle("3\n0 5\n5 0\n20 2147483000\n") == "0\n1\n0\n"


def write_case(name, pairs):
    text = f"{len(pairs)}\n" + "".join(f"{a} {b}\n" for a, b in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", [(3, 10), (6, 2)])
write_case("2_edges", [(0, 1), (1, 0), (20, 0), (20, 2147483000), (7, 2147483000), (9, 4)])
write_case("3_wide", [(a, b) for a in range(0, 21) for b in (0, 1, 2, 3, 4, 2147483000) if not (a == 0 and b == 0)][:30])
rng = random.Random(3442)
rand_pairs = [(rng.randint(0, 20), rng.randint(1, 2147483000)) for _ in range(30)]
write_case("4_random", rand_pairs)
write_case("5_io", rand_pairs)
