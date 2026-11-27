#!/usr/bin/env python3
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def oracle(text):
    vals = [int(tok) for tok in text.split()]
    t = vals[0]
    pos = 1
    out = []
    for _ in range(t):
        n = vals[pos]
        pos += 1
        men = sorted(vals[pos : pos + n])
        pos += n
        women = sorted(vals[pos : pos + n])
        pos += n
        out.append(str(sum(a * b for a, b in zip(men, women))))
    return "\n".join(out) + ("\n" if out else "")


SAMPLE = "2\n2\n1 1\n3 2\n3\n2 3 2\n3 2 1\n"
assert oracle(SAMPLE) == "5\n15\n"
assert oracle("1\n1\n10\n10\n") == "100\n"
assert oracle("1\n3\n0 5 10\n10 0 5\n") == "125\n"


def write_case(name, cases):
    parts = [f"{len(cases)}\n"]
    for men, women in cases:
        parts.append(f"{len(men)}\n")
        parts.append(" ".join(str(x) for x in men) + "\n")
        parts.append(" ".join(str(x) for x in women) + "\n")
    text = "".join(parts)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", [([1, 1], [3, 2]), ([2, 3, 2], [3, 2, 1])])
write_case("2_edges", [([0], [10]), ([10] * 1000, [10] * 1000)])
write_case("3_wide", [([i % 11 for i in range(1000)], [10 - (i % 11) for i in range(1000)])])
rng = random.Random(2006)
rand_cases = [([rng.randint(0, 10) for _ in range(1000)], [rng.randint(0, 10) for _ in range(1000)]) for _ in range(40)]
write_case("4_random", rand_cases)
write_case("5_io", rand_cases * 5)
