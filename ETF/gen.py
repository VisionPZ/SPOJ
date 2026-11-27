#!/usr/bin/env python3
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def totient_factor(n):
    res = n
    cur = n
    d = 2
    while d * d <= cur:
        if cur % d == 0:
            while cur % d == 0:
                cur //= d
            res -= res // d
        d += 1
    if cur > 1:
        res -= res // cur
    return res


def oracle(text):
    vals = [int(tok) for tok in text.split()]
    t = vals[0]
    return "".join(f"{totient_factor(vals[1 + i])}\n" for i in range(t))


assert oracle("5\n1\n2\n3\n4\n5\n") == "1\n1\n2\n2\n4\n"
assert totient_factor(999983) == 999982
assert totient_factor(1000000) == 400000


def write_case(name, queries):
    text = f"{len(queries)}\n" + "".join(f"{n}\n" for n in queries)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", [1, 2, 3, 4, 5])
write_case("2_edges", [1, 2, 6, 30, 999983, 1000000])
write_case("3_wide", list(range(999900, 1000001)))
rng = random.Random(414)
rand_q = [rng.randint(1, 1000000) for _ in range(2000)]
write_case("4_random", rand_q)
write_case("5_io", [rng.randint(900000, 1000000) for _ in range(20000)])
