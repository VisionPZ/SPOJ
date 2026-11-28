#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(block_count):
    doubled = 2 * block_count
    best_dead = None
    best_pair = None
    for block_side in range(1, 2001):
        prod = doubled * block_side * block_side
        root = math.isqrt(prod)
        side = root
        if side * side != prod:
            side += 1
        dead = side * side - prod
        if best_dead is None or dead < best_dead or (dead == best_dead and side < best_pair[0]):
            best_dead = dead
            best_pair = (side, block_side)
    return best_pair


def oracle_text(counts):
    lines = []
    for number, count in enumerate(counts, 1):
        side, block_side = oracle(count)
        lines.append(f"Case {number}: {side} {block_side}")
    return "\n".join(lines) + "\n"


SAMPLE_IN = "1\n2\n0\n"
SAMPLE_OUT = "Case 1: 3 2\nCase 2: 2 1\n"
assert oracle(1) == (3, 2)
assert oracle(2) == (2, 1)
assert oracle(3) == (5, 2)
assert oracle(8) == (4, 1)
assert oracle_text([1, 2]) == SAMPLE_OUT


def write(name, counts):
    text = "".join(f"{value}\n" for value in counts) + "0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(counts))


def build():
    write("2_edges", [1, 2, 4, 8, 18, 50, 100])
    write("3_wide", [124, 100, 99, 50, 20, 15, 14, 13, 12, 11, 10])
    rng = random.Random(20261126)
    pool = [3, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 20, 50, 99, 100, 124]
    write("4_random", [rng.choice(pool) for _ in range(60)])
    write("5_io", [rng.choice([1, 2, 3, 4, 8, 9, 12, 15]) for _ in range(600)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
