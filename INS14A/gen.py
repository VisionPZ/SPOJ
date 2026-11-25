#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_bfs(ones_needed, binary_string):
    size = len(binary_string)
    queue = deque([binary_string])
    distance = {binary_string: 0}
    while queue:
        current = queue.popleft()
        steps = distance[current]
        for start in range(size - ones_needed + 1):
            if all(current[index] == "1" for index in range(start, start + ones_needed)):
                return steps
        for index in range(size - 1):
            if current[index] != current[index + 1]:
                changed = list(current)
                changed[index], changed[index + 1] = changed[index + 1], changed[index]
                follower = "".join(changed)
                if follower not in distance:
                    distance[follower] = steps + 1
                    queue.append(follower)
    raise ValueError("no solution")


def oracle_direct(ones_needed, binary_string):
    ones = [index for index, value in enumerate(binary_string) if value == "1"]
    best = None
    for ones_start in range(len(ones) - ones_needed + 1):
        chosen = ones[ones_start:ones_start + ones_needed]
        for target_start in range(len(binary_string) - ones_needed + 1):
            cost = sum(abs(one - (target_start + offset)) for offset, one in enumerate(chosen))
            if best is None or cost < best:
                best = cost
    return best


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    results = []
    cursor = 1
    for _ in range(case_count):
        ones_needed = int(tokens[cursor])
        binary_string = tokens[cursor + 1]
        cursor += 2
        results.append(str(oracle_bfs(ones_needed, binary_string)))
    return "\n".join(results) + "\n"


def oracle_large(text):
    tokens = text.split()
    case_count = int(tokens[0])
    results = []
    cursor = 1
    for _ in range(case_count):
        ones_needed = int(tokens[cursor])
        binary_string = tokens[cursor + 1]
        cursor += 2
        results.append(str(oracle_direct(ones_needed, binary_string)))
    return "\n".join(results) + "\n"


SAMPLE = """2
3
101001
2
101001
"""
SAMPLE_OUT = """3
1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_bfs(1, "0010") == 0
assert oracle_bfs(3, "11001") == 2
assert oracle_bfs(4, "1111") == 0
assert oracle_bfs(2, "1010") == 1
assert oracle_direct(3, "101001") == 3
assert oracle_bfs(3, "101001") == 3


def write_cases(name, cases, checker):
    lines = [str(len(cases))]
    for ones_needed, binary_string in cases:
        lines.append(str(ones_needed))
        lines.append(binary_string)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(checker(text))


def build():
    write_cases("2_edges", [(1, "000100"), (4, "1111"), (2, "1010"), (2, "1100"), (1, "1")], oracle)
    rng = random.Random(20261126)
    wide = []
    for _ in range(8):
        size = 200
        ones_needed = rng.randint(15, 40)
        ones_count = rng.randint(ones_needed, ones_needed + 20)
        bits = ["1"] * ones_count + ["0"] * (size - ones_count)
        rng.shuffle(bits)
        wide.append((ones_needed, "".join(bits)))
    write_cases("3_wide", wide, oracle_large)
    random_cases = []
    for _ in range(12):
        size = rng.randint(6, 12)
        ones_count = rng.randint(2, size)
        ones_needed = rng.randint(1, ones_count)
        bits = ["1"] * ones_count + ["0"] * (size - ones_count)
        rng.shuffle(bits)
        random_cases.append((ones_needed, "".join(bits)))
    write_cases("4_random", random_cases, oracle)
    io_cases = []
    for _ in range(10):
        size = 5000
        bits = ["1"] * 3000 + ["0"] * 2000
        rng.shuffle(bits)
        io_cases.append((2, "".join(bits)))
    write_cases("5_io", io_cases, oracle_large)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
