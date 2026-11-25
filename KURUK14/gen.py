#!/usr/bin/env python3
import itertools
import random
import sys
from pathlib import Path

sys.setrecursionlimit(10000)
ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    answers = []
    for _ in range(case_count):
        length = tokens[position]
        position += 1
        values = tokens[position:position + length]
        position += length
        adjacency = [[] for _ in range(length)]
        for slot in range(length):
            allowed = {slot, length - 1 - slot}
            for value_index, value in enumerate(values):
                if value in allowed:
                    adjacency[slot].append(value_index)
        assigned_slot = [-1] * length

        def augment(slot, seen):
            for value_index in adjacency[slot]:
                if seen[value_index]:
                    continue
                seen[value_index] = True
                if assigned_slot[value_index] == -1 or augment(assigned_slot[value_index], seen):
                    assigned_slot[value_index] = slot
                    return True
            return False

        possible = True
        for slot in range(length):
            if not augment(slot, [False] * length):
                possible = False
                break
        answers.append("YES" if possible else "NO")
    return "\n".join(answers) + "\n"


def brute(values):
    length = len(values)
    for arrangement in set(itertools.permutations(values)):
        if all(value == index or value == length - 1 - index
               for index, value in enumerate(arrangement)):
            return True
    return False


SAMPLE = """1
4
1 3 3 2
"""
SAMPLE_OUT = """YES
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n0 0\n") == "YES\n"
assert oracle("1\n3\n0 0 0\n") == "NO\n"
assert oracle("1\n5\n1 1 2 3 4\n") == "NO\n"
assert brute([1, 3, 3, 2]) is True
assert brute([1, 1, 2, 3, 4]) is False
rng_check = random.Random(12345)
for _ in range(60):
    small = [rng_check.randint(0, 5) for _ in range(rng_check.randint(2, 7))]
    text = f"1\n{len(small)}\n" + " ".join(str(value) for value in small) + "\n"
    assert (oracle(text) == "YES\n") == brute(small)


def valid_values(length):
    result = []
    pair_count = length // 2
    for lower in range(pair_count):
        result.extend([lower, lower])
    if length % 2 == 1:
        result.append(pair_count)
    return result


def write(name, cases):
    parts = [str(len(cases))]
    for values in cases:
        parts.append(str(len(values)))
        parts.append(" ".join(str(value) for value in values))
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[0, 0], [1, 1], [2, 1]])
    write("3_wide", [valid_values(1000), valid_values(999)])
    rng = random.Random(20261126)
    mixed = []
    for _ in range(20):
        length = rng.randint(2, 30)
        if rng.random() < 0.5:
            mixed.append(valid_values(length))
        else:
            mixed.append([rng.randint(1, 1000) for _ in range(length)])
    write("4_random", mixed)
    write("5_io", [valid_values(1000) for _ in range(20)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[1, 3, 3, 2]])
build()
