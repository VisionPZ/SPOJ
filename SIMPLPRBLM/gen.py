#!/usr/bin/env python3
import random
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def count_pairs(values, target):
    freq = Counter(values)
    total = 0
    for value, count in freq.items():
        other = target - value
        if other not in freq:
            continue
        if other > value:
            total += count * freq[other]
        elif other == value:
            total += count * (count - 1) // 2
    return total


def oracle(text):
    tokens = text.split()
    pos = 0
    cases = int(tokens[pos]); pos += 1
    lines = []
    for case_index in range(1, cases + 1):
        size = int(tokens[pos]); pos += 1
        target = int(tokens[pos]); pos += 1
        values = [int(tokens[pos + k]) for k in range(size)]
        pos += size
        lines.append(f"Case {case_index}: {count_pairs(values, target)}")
    return "\n".join(lines) + ("\n" if lines else "")


SAMPLE = "3\n4 8\n1 2 4 9\n3 7\n3 4 4\n3 8\n4 4 4\n"
SAMPLE_OUT = "Case 1: 0\nCase 2: 2\nCase 3: 3\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert count_pairs([1, 1, 1], 2) == 3
assert count_pairs([1, 2, 3, 4, 5], 6) == 2
assert count_pairs([10, 20, 30], 100) == 0
assert count_pairs([5, 5, 5, 5], 10) == 6


def write(name, cases):
    body = [str(len(cases)) + "\n"]
    for size, target, values in cases:
        body.append(f"{size} {target}\n")
        body.append("".join(f"{value}\n" for value in values))
    text = "".join(body)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, 10, [5]),
        (2, 8, [4, 4]),
        (2, 7, [3, 4]),
        (3, 2, [1, 1, 1]),
        (4, 10**10, [10**9, 10**9, 10**9, 10**9]),
        (5, 2, [1, 2, 3, 4, 5]),
    ])
    wide = []
    for k in range(4):
        values = [(123456789 + 7 * j) % 10**9 + 1 for j in range(100000)]
        wide.append((100000, 10**10 - k, values))
    write("3_wide", wide)

    random.seed(2026)
    rnd = []
    for _ in range(50):
        size = random.randint(1, 2000)
        values = [random.randint(1, 10**9) for _ in range(size)]
        target = random.randint(1, 10**10)
        rnd.append((size, target, values))
    write("4_random", rnd)

    io_cases = []
    for k in range(50):
        values = [random.randint(1, 10**9) for _ in range(2000)]
        target = values[k] + values[k + 1]
        io_cases.append((2000, target, values))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
print("trace: Case 2 target 7 with [3,4,4] -> two pairs -> 2")
