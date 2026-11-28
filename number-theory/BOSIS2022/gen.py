#!/usr/bin/env python3
import random
from pathlib import Path
import heapq

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    if not tokens:
        return ""
    case_count = tokens[0]
    ranks = tokens[1:1 + case_count]
    limit = max(ranks) if ranks else 0
    sequence = []
    heap = [1]
    seen = {1}
    while len(sequence) < limit:
        current = heapq.heappop(heap)
        sequence.append(current)
        for factor in (2, 3, 5):
            candidate = current * factor
            if candidate not in seen:
                seen.add(candidate)
                heapq.heappush(heap, candidate)
    lines = [str(sequence[rank - 1]) for rank in ranks if rank >= 1]
    return "\n".join(lines) + ("\n" if lines else "")


SAMPLE = """5
6
1
4
8
20
"""
SAMPLE_OUT = """6
1
4
9
36
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "1\n"
assert oracle("2\n11\n1500\n") == "15\n859963392\n"
assert oracle("3\n2\n3\n7\n") == "2\n3\n8\n"
assert 2 * 2 * 3 * 5 == 60


def write(name, ranks):
    text = str(len(ranks)) + "\n" + "".join(str(rank) + "\n" for rank in ranks)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4])
    write("3_wide", [200, 199, 200, 198, 197])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 200) for _ in range(50)])
    write("5_io", [rng.randint(1, 200) for _ in range(200)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [6, 1, 4, 8, 20])
build()
