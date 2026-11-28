#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def direct_exact_dp(hit_prob, army_a, army_b):
    if hit_prob >= 1.0 - 1e-12:
        if army_a > army_b:
            return (1.0, 0.0, 0.0)
        if army_a < army_b:
            return (0.0, 1.0, 0.0)
        return (0.0, 0.0, 1.0)
    limit = max(army_a, army_b)
    binom = []
    for n in range(limit + 1):
        binom.append([
            math.comb(n, k) * (hit_prob ** k) * ((1.0 - hit_prob) ** (n - k))
            for k in range(n + 1)
        ])
    dp = [[(0.0, 0.0, 0.0) for _ in range(army_b + 1)] for _ in range(army_a + 1)]
    for a in range(1, army_a + 1):
        dp[a][0] = (1.0, 0.0, 0.0)
    for b in range(1, army_b + 1):
        dp[0][b] = (0.0, 1.0, 0.0)
    dp[0][0] = (0.0, 0.0, 1.0)
    for a in range(1, army_a + 1):
        ra = binom[a]
        for b in range(1, army_b + 1):
            rb = binom[b]
            wa = wb = dr = 0.0
            for ka in range(a + 1):
                pa = ra[ka]
                if pa < 1e-14:
                    continue
                nb = b - ka if b > ka else 0
                for kb in range(b + 1):
                    if ka == 0 and kb == 0:
                        continue
                    pb = rb[kb]
                    if pb < 1e-14:
                        continue
                    na = a - kb if a > kb else 0
                    p = pa * pb
                    x, y, z = dp[na][nb]
                    wa += p * x
                    wb += p * y
                    dr += p * z
            denom = 1.0 - ra[0] * rb[0]
            dp[a][b] = (wa / denom, wb / denom, dr / denom)
    return dp[army_a][army_b]


def analytical_large(hit_prob, army_a, army_b):
    if hit_prob >= 1.0 - 1e-12:
        if army_a > army_b:
            return (1.0, 0.0, 0.0)
        if army_a < army_b:
            return (0.0, 1.0, 0.0)
        return (0.0, 0.0, 1.0)
    if army_a <= 35 and army_b <= 35:
        return direct_exact_dp(hit_prob, army_a, army_b)
    total = float(army_a + army_b)
    diff = float(army_a - army_b)
    sd_inf = math.sqrt((1.0 - hit_prob) / (3.0 + hit_prob) * total)
    if abs(diff) > 8.5 * sd_inf:
        return (1.0, 0.0, 0.0) if diff > 0 else (0.0, 1.0, 0.0)
    if army_a == army_b and hit_prob <= 0.05:
        return (0.5, 0.5, 0.0)
    z = diff / sd_inf
    p_a = 0.5 * (1.0 + math.erf(z / math.sqrt(2.0)))
    return (p_a, 1.0 - p_a, 0.0)


def fmt(triple):
    return " ".join(f"{min(1.0, max(0.0, v)):.5f}" for v in triple)


def oracle(text):
    tokens = text.split()
    t = int(tokens[0])
    idx = 1
    lines = []
    for _ in range(t):
        h = float(tokens[idx])
        a = int(tokens[idx + 1])
        b = int(tokens[idx + 2])
        idx += 3
        lines.append(fmt(analytical_large(h, a, b)) + "\n")
    return "".join(lines)


SAMPLE = "2\n0.3\n2 1\n0.854\n8 8\n"
SAMPLE_OUT = "0.86839 0.09213 0.03948\n0.38532 0.38532 0.22936\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0.5\n1 1\n") == "0.33333 0.33333 0.33333\n"
assert oracle("1\n1\n5 3\n") == "1.00000 0.00000 0.00000\n"
assert oracle("1\n1.0\n4 4\n") == "0.00000 0.00000 1.00000\n"


def emit(name, cases):
    text = f"{len(cases)}\n" + "".join(f"{h}\n{a} {b}\n" for h, a, b in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edges = [
        ("1", 1, 1),
        ("1.0", 5, 4),
        ("1", 4, 5),
        ("0.5", 1, 1),
        ("0.001", 1, 1),
        ("0.99999", 2, 2),
        ("0.5", 20, 1),
        ("0.5", 1, 20),
        ("0.25", 12, 12),
    ]
    emit("2_edges", edges)

    wide = [
        ("1", 1000000, 1000000),
        ("1.0", 1000000, 999999),
        ("0.5", 1000000, 1),
        ("0.5", 1, 1000000),
        ("0.01", 1000000, 950000),
        ("0.001", 900000, 1000000),
        ("0.02", 1000000, 1000000),
        ("0.0001", 1000000, 1000000),
    ]
    emit("3_wide", wide)

    rng = random.Random(20261127)
    rand_cases = []
    for _ in range(25):
        h = round(rng.uniform(0.05, 0.95), 4)
        a = rng.randint(1, 30)
        b = rng.randint(1, 30)
        rand_cases.append((f"{h}", a, b))
    for _ in range(15):
        h = round(rng.uniform(0.001, 0.03), 4)
        a = rng.randint(200000, 1000000)
        delta = rng.randint(8000, 20000) * (1 if rng.random() < 0.5 else -1)
        b = a + delta
        rand_cases.append((f"{h}", a, b))
    emit("4_random", rand_cases)

    io_cases = []
    for idx in range(500):
        h = "1" if idx % 3 == 0 else ("0.5" if idx % 3 == 1 else "0.01")
        if idx % 3 == 0:
            io_cases.append((h, 1000000, 999999 if idx % 2 else 1000000))
        elif idx % 3 == 1:
            io_cases.append((h, 1000000, 500000))
        else:
            io_cases.append((h, 1000000, 1000000))
    emit("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
