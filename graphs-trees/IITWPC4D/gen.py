#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def inversion_sequence(permutation):
    return [sum(1 for earlier in permutation[:index] if earlier > value)
            for index, value in enumerate(permutation)]


def brute_reconstruct(counts):
    size = len(counts)
    solutions = [perm for perm in itertools.permutations(range(1, size + 1))
                 if inversion_sequence(perm) == counts]
    return list(solutions[0]) if len(solutions) == 1 else None


def sorted_reconstruct(counts):
    size = len(counts)
    available = list(range(1, size + 1))
    heights = [0] * size
    for position in range(size, 0, -1):
        wanted = position - counts[position - 1]
        if wanted < 1 or wanted > position:
            return None
        heights[position - 1] = available.pop(wanted - 1)
    return heights


def reconstruct(counts):
    if len(counts) <= 7:
        return brute_reconstruct(counts)
    return sorted_reconstruct(counts)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    lines = []
    for case_index in range(case_count):
        size = tokens[cursor]
        cursor += 1
        counts = tokens[cursor:cursor + size]
        cursor += size
        lines.append("Test : " + str(case_index + 1))
        answer = reconstruct(counts)
        lines.append("-1" if answer is None else " ".join(str(value) for value in answer))
    return "\n".join(lines) + "\n"


SAMPLE = """2
3
0 1 1
3
0 1 0
"""
SAMPLE_OUT = """Test : 1
3 1 2
Test : 2
2 1 3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert reconstruct([0]) == [1]
assert reconstruct([0, 2, 0]) is None
assert reconstruct([1, 0, 0]) is None
assert reconstruct([0, 0]) == [1, 2]
assert reconstruct([0, 1]) == [2, 1]
for size in range(1, 5):
    for counts in itertools.product(range(size), repeat=size):
        assert brute_reconstruct(list(counts)) == sorted_reconstruct(list(counts)), (size, counts)


def write(name, cases):
    chunks = [str(len(cases))]
    for counts in cases:
        chunks.append(str(len(counts)))
        chunks.append(" ".join(str(value) for value in counts))
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[0], [0, 0], [0, 1], [0, 2, 0], [1, 0, 0], [0, 1, 2]])
    rng = random.Random(20261126)
    wide_counts = inversion_sequence(list(range(1, 100001)))
    write("3_wide", [wide_counts])
    random_cases = []
    for _ in range(60):
        size = rng.randint(1, 7)
        perm = list(range(1, size + 1))
        rng.shuffle(perm)
        counts = inversion_sequence(perm)
        if rng.random() < 0.3:
            index = rng.randrange(size)
            counts[index] = size + rng.randint(0, 2)
        random_cases.append(counts)
    write("4_random", random_cases)
    write("5_io", [list(range(100000))])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[0, 1, 1], [0, 1, 0]])
build()
