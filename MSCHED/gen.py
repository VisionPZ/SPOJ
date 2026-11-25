#!/usr/bin/env python3
import heapq
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    cows = [(tokens[1 + 2 * index], tokens[2 + 2 * index]) for index in range(count)]
    heap = []
    for gain, deadline in sorted(cows, key=lambda pair: pair[1]):
        if len(heap) < deadline:
            heapq.heappush(heap, gain)
        elif heap and gain > heap[0]:
            heapq.heapreplace(heap, gain)
    return str(sum(heap)) + "\n"


def brute_force(cows):
    best = 0
    count = len(cows)
    for mask in range(1 << count):
        chosen = [cows[index] for index in range(count) if (mask >> index) & 1]
        chosen.sort(key=lambda pair: pair[1])
        feasible = all(index + 1 <= deadline for index, (_, deadline) in enumerate(chosen))
        if feasible:
            best = max(best, sum(gain for gain, _ in chosen))
    return str(best) + "\n"


SAMPLE = """4
10 3
7 5
8 1
2 1
"""
SAMPLE_OUT = """25
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_force([(10, 3), (7, 5), (8, 1), (2, 1)]) == SAMPLE_OUT
assert oracle("1\n5 1\n") == "5\n"
assert oracle("2\n1 1\n1000 1\n") == "1000\n"
assert brute_force([(3, 2), (4, 1), (2, 2)]) == oracle("3\n3 2\n4 1\n2 2\n") == "7\n"
assert sum(1 for _ in itertools.combinations(range(3), 2)) == 3


def write(name, cows):
    text = str(len(cows)) + "\n" + "".join(f"{gain} {deadline}\n" for gain, deadline in cows)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1000, 1), (1, 1), (999, 3)])
    write("3_wide", [(1000, 10000) for _ in range(10000)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 1000), rng.randint(1, 10000)) for _ in range(5000)])
    write("5_io", [(rng.randint(1, 1000), rng.randint(1, 10000)) for _ in range(10000)])


def trace_example():
    cows = [(10, 3), (7, 5), (8, 1), (2, 1)]
    print("gain/deadline:", cows)
    print("sorted by deadline:", sorted(cows, key=lambda pair: pair[1]))
    print("chosen gains:", [10, 8, 7])
    print("total milk:", 25)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(10, 3), (7, 5), (8, 1), (2, 1)])
build()
trace_example()
