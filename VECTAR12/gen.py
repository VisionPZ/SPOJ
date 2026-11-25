#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007
MEMO = {}


def brute(steps, height):
    key = (steps, height)
    if key in MEMO:
        return MEMO[key]
    if steps == 0:
        return 1 if height == 0 else 0
    total = 0
    for delta in (-1, 0, 1):
        if height + delta >= 0:
            total += brute(steps - 1, height + delta)
    MEMO[key] = total % MOD
    return MEMO[key]


def table(max_steps):
    rows = [[1]]
    for step in range(1, max_steps + 1):
        previous = rows[-1]
        current = []
        for height in range(step + 1):
            total = previous[height] if height < len(previous) else 0
            if height > 0:
                total += previous[height - 1]
            if height + 1 < len(previous):
                total += previous[height + 1]
            current.append(total % MOD)
        rows.append(current)
    return rows


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    count = tokens[cursor]; cursor += 1
    queries = []
    for _ in range(count):
        queries.append((tokens[cursor], tokens[cursor + 1]))
        cursor += 2
    rows = table(max(step for step, _ in queries)) if queries else [[1]]
    return "".join(str(rows[step][height]) + "\n" for step, height in queries)


SAMPLE = """2
1 1
2 0
"""
SAMPLE_OUT = """1
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0 0\n") == "1\n"
for steps in range(8):
    for height in range(steps + 1):
        assert oracle(f"1\n{steps} {height}\n") == str(brute(steps, height)) + "\n"
assert oracle("1\n4 0\n") == "9\n"
assert oracle("1\n5 0\n") == "21\n"
assert oracle("1\n700 700\n") == "1\n"


def write(name, queries):
    text = str(len(queries)) + "\n" + "".join(
        f"{step} {height}\n" for step, height in queries)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, 0), (1, 0), (1, 1), (2, 2), (3, 0), (700, 700)])
    write("3_wide", [(700, height) for height in range(0, 701, 50)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randrange(701), 0) for _ in range(200)] +
          [(steps, rng.randrange(steps + 1)) for steps in
           (rng.randrange(701) for _ in range(200))])
    write("5_io", [(rng.randrange(701), 0) for _ in range(99999)])
    big = []
    for _ in range(99999):
        steps = rng.randrange(7000)
        big.append((steps, rng.randrange(steps + 1)))
    Path("/tmp/VECTAR12_big.txt").write_text(
        str(len(big)) + "\n" + "".join(f"{step} {height}\n" for step, height in big))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 1), (2, 0)])
build()
