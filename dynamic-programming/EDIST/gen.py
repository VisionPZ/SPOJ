#!/usr/bin/env python3
from pathlib import Path
import random
import string

ROOT = Path(__file__).resolve().parent


def oracle_2d(a, b):
    n, m = len(a), len(b)
    dp = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(n + 1):
        dp[i][0] = i
    for j in range(m + 1):
        dp[0][j] = j
    for i in range(1, n + 1):
        ca = a[i - 1]
        row = dp[i]
        prow = dp[i - 1]
        for j in range(1, m + 1):
            cost = prow[j - 1] + (0 if ca == b[j - 1] else 1)
            row[j] = min(cost, prow[j] + 1, row[j - 1] + 1)
    return dp[n][m]


def oracle(text):
    tokens = text.split()
    t = int(tokens[0])
    return "".join(f"{oracle_2d(tokens[1 + 2 * i], tokens[2 + 2 * i])}\n" for i in range(t))


assert oracle("1\nFOOD\nMONEY\n") == "4\n"
assert oracle("1\nABC\nABC\n") == "0\n"
assert oracle("1\nA\nBBBB\n") == "4\n"


def write_case(name, pairs):
    text = f"{len(pairs)}\n" + "".join(f"{a}\n{b}\n" for a, b in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", [("FOOD", "MONEY")])
write_case("2_edges", [("A", "A"), ("A", "B"), ("ABC", "DEF"), ("ABCDE", "ACED")])
write_case("3_wide", [("A" * 1200, "B" * 1200)])
rng = random.Random(222)
alpha = "ABCD"
rand_pairs = [
    ("".join(rng.choice(alpha) for _ in range(400)), "".join(rng.choice(alpha) for _ in range(400)))
    for _ in range(5)
]
write_case("4_random", rand_pairs)
write_case("5_io", rand_pairs * 2)
