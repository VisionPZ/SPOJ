#!/usr/bin/env python3
import random
from collections import Counter
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LESSON_GAP = 30
MAX_LESSONS = 4


def oracle(text):
    tokens = [int(value) for value in text.split()]
    times = tokens[1:1 + tokens[0]]
    if not times:
        return "0\n"
    counts = Counter(times)
    keys = sorted(counts)
    key_index = {value: index for index, value in enumerate(keys)}
    chains = []
    for start in keys:
        for length in range(1, MAX_LESSONS + 1):
            chain = tuple(start + LESSON_GAP * step for step in range(length))
            if all(value in key_index for value in chain):
                chains.append(tuple(key_index[value] for value in chain))

    @lru_cache(maxsize=None)
    def cover(state):
        if not any(state):
            return 0
        first_needed = next(index for index, amount in enumerate(state) if amount)
        best = 10 ** 9
        for chain in chains:
            if first_needed not in chain:
                continue
            reduced = list(state)
            for chain_index in chain:
                if reduced[chain_index] == 0:
                    break
                reduced[chain_index] -= 1
            else:
                best = min(best, 1 + cover(tuple(reduced)))
        return best

    return str(cover(tuple(counts[value] for value in keys))) + "\n"


SAMPLE = """5
0
0
30
60
61
"""
SAMPLE_OUT = """3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0\n") == "1\n"
assert oracle("2\n0\n0\n") == "2\n"
assert oracle("2\n0\n31\n") == "2\n"
assert oracle("5\n0\n30\n60\n90\n120\n") == "2\n"
assert oracle("8\n0\n30\n60\n90\n120\n150\n180\n210\n") == "2\n"
assert oracle("8\n61\n91\n122\n91\n151\n121\n181\n122\n") == "4\n"


def write(name, times):
    text = str(len(times)) + "\n" + "".join(str(value) + "\n" for value in times)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1410])
    write("3_wide", [0, 0, 30, 61, 61, 62, 150, 180, 181, 900, 1410, 1410])
    rng = random.Random(20261126)
    write("4_random", [rng.randrange(0, 1411) for _ in range(12)])
    write("5_io", [rng.randrange(0, 48) * 30 + rng.randrange(0, 4) for _ in range(12)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [0, 0, 30, 60, 61])
build()
