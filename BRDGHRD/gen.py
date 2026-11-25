#!/usr/bin/env python3
import bisect
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_chain(pairs):
    ordered = sorted(pairs)
    lengths = []
    best = 0
    for index, (_, second) in enumerate(ordered):
        value = 1
        for prior in range(index):
            if ordered[prior][1] <= second:
                value = max(value, lengths[prior] + 1)
        lengths.append(value)
        best = max(best, value)
    return best


def oracle(text):
    tokens = text.split()
    cursor = 0
    cases = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(cases):
        count = int(tokens[cursor]); cursor += 1
        first = [int(value) for value in tokens[cursor:cursor + count]]; cursor += count
        second = [int(value) for value in tokens[cursor:cursor + count]]; cursor += count
        pairs = sorted(zip(first, second))
        coords = sorted({value for _, value in pairs})
        tree = [0] * (len(coords) + 1)
        best = 0
        for _, value in pairs:
            position = bisect.bisect_left(coords, value) + 1
            probe = position
            candidates = 0
            while probe > 0:
                candidates = max(candidates, tree[probe])
                probe -= probe & -probe
            length = candidates + 1
            probe = position
            while probe < len(tree):
                tree[probe] = max(tree[probe], length)
                probe += probe & -probe
            best = max(best, length)
        answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE = """3
4
2 5 8 10
6 4 1 2
3
5 3 10
6 4 1
6
1 2 3 4 5 6
3 4 5 6 1 2
"""
SAMPLE_OUT = """2
2
4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n1 4\n2 2\n") == "2\n"
assert oracle("1\n2\n-5 3\n-2 -1\n") == "2\n"
assert oracle("1\n3\n1 2 3\n3 2 1\n") == "1\n"
samplePairs = [(2, 6), (5, 4), (8, 1), (10, 2)]
assert brute_chain(samplePairs) == 2
assert oracle("1\n4\n2 5 8 10\n6 4 1 2\n") == "2\n"


def write(name, cases):
    lines = [str(len(cases))]
    for first, second in cases:
        lines.append(str(len(first)))
        lines.append(" ".join(str(value) for value in first))
        lines.append(" ".join(str(value) for value in second))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ([1], [1]),
        ([-1000000, -1], [1000000, 5]),
        ([3, 3, 3], [7, 2, 2]),
        ([2, 1], [5, 5]),
    ])
    rng = random.Random(20261126)
    wide = [rng.randint(-1000000, 1000000) for _ in range(300)]
    shuffled = wide[:]
    rng.shuffle(shuffled)
    write("3_wide", [(wide, shuffled)])
    cases = []
    for _ in range(5):
        size = rng.randint(1, 120)
        first = [rng.randint(-1000, 1000) for _ in range(size)]
        second = [rng.randint(-1000, 1000) for _ in range(size)]
        cases.append((first, second))
    write("4_random", cases)
    outputCases = []
    for _ in range(12):
        size = 2000
        first = sorted(rng.randint(-100000, 100000) for _ in range(size))
        second = [rng.randint(-100000, 100000) for _ in range(size)]
        outputCases.append((first, second))
    write("5_io", outputCases)


def trace_example():
    ordered = sorted([(2, 6), (5, 4), (8, 1), (10, 2)])
    tails = []
    for _, value in ordered:
        position = bisect.bisect_right(tails, value)
        if position == len(tails):
            tails.append(value)
        else:
            tails[position] = value
        print(value, tails[:])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
trace_example()
