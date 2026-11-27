#!/usr/bin/env python3
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def oracle(text):
    out = []
    for tok in text.split():
        n = int(tok)
        if n == 0:
            break
        out.append(str(sum((n - k + 1) ** 2 for k in range(1, n + 1))))
    return "\n".join(out) + ("\n" if out else "")


assert oracle("2\n1\n8\n0\n") == "5\n1\n204\n"
assert oracle("3\n0\n") == "14\n"
assert oracle("100\n0\n") == "338350\n"


def write_case(name, values):
    text = "".join(f"{v}\n" for v in values) + "0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", [2, 1, 8])
write_case("2_edges", [1, 2, 10, 99, 100])
write_case("3_wide", list(range(1, 101)))
rng = random.Random(808)
write_case("4_random", [rng.randint(1, 100) for _ in range(1000)])
write_case("5_io", [rng.randint(1, 100) for _ in range(50000)])
