#!/usr/bin/env python3
from fractions import Fraction
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(tok) for tok in text.split()]
    out = []
    pos = 0
    while pos + 2 < len(tokens):
        a1, a2, a3 = tokens[pos], tokens[pos + 1], tokens[pos + 2]
        pos += 3
        if a1 == 0 and a2 == 0 and a3 == 0:
            break
        if a2 - a1 == a3 - a2:
            step = Fraction(a3) + Fraction(a2 - a1)
            out.append(f"AP {int(step)}")
        else:
            step = Fraction(a3) * Fraction(a2, a1)
            assert step.denominator == 1
            out.append(f"GP {int(step)}")
    return "\n".join(out) + ("\n" if out else "")


SAMPLE = "4 7 10\n2 6 18\n0 0 0\n"
assert oracle(SAMPLE) == "AP 13\nGP 54\n"
assert oracle("-5 -2 1\n0 0 0\n") == "AP 4\n"
assert oracle("2 -4 8\n0 0 0\n") == "GP -16\n"
assert oracle("16 8 4\n0 0 0\n") == "GP 2\n"


def write_case(name, triples):
    text = "".join(f"{a} {b} {c}\n" for a, b, c in triples) + "0 0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", [(4, 7, 10), (2, 6, 18)])
write_case("2_edges", [(-9999, 0, 9999), (1, -2, 4), (-1, -3, -9), (9990, 3330, 1110)])
write_case("3_wide", [(9997, 9998, 9999), (-9999, -9998, -9997), (1, 99, 9801), (-1, 99, -9801)])

rng = random.Random(1010)
rand_triples = []
for idx in range(500):
    if idx % 2 == 0:
        d = rng.choice([-1, 1]) * rng.randint(1, 5000)
        a1 = rng.randint(-9999 + max(0, -2 * d), 9999 - max(0, 2 * d))
        rand_triples.append((a1, a1 + d, a1 + 2 * d))
    else:
        r = rng.choice([-3, -2, 2, 3])
        lim = 9999 // (r * r)
        a1 = rng.choice([-1, 1]) * rng.randint(1, lim)
        rand_triples.append((a1, a1 * r, a1 * r * r))
write_case("4_random", rand_triples)
write_case("5_io", rand_triples * 20)
