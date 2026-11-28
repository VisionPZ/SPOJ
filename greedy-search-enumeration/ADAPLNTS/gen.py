#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    numbers = list(map(int, text.split()))
    pos = 0
    answers = []
    while pos < len(numbers):
        left_count = numbers[pos]
        right_count = numbers[pos + 1]
        pos += 2
        left_kinds = numbers[pos:pos + left_count]
        pos += left_count
        right_kinds = numbers[pos:pos + right_count]
        pos += right_count
        best = 0
        for keep_mask in range(1 << left_count):
            kept = 0
            blocked = [False] * right_count
            for left_index in range(left_count):
                if keep_mask & (1 << left_index):
                    kept += 1
                    for right_index in range(right_count):
                        if math_gcd(left_kinds[left_index], right_kinds[right_index]) > 1:
                            blocked[right_index] = True
            survivors = sum(1 for value in blocked if not value)
            best = max(best, kept + survivors)
        answers.append(str(best))
    return "\n".join(answers) + "\n"


def math_gcd(first, second):
    while second:
        first, second = second, first % second
    return first


SAMPLE = """3 4
3 4 5
6 30 1 7
"""
SAMPLE_OUT = """5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("4 3\n2 2 10 32\n4 16 28\n") == "4\n"
assert oracle("5 5\n2 6 12 15 18\n33 8 2 3 5\n") == "5\n"
assert oracle("3 3\n2 27 9\n3 4 8\n") == "4\n"
assert oracle("1 1\n1 1\n") == "2\n"


def write(name, cases):
    lines = []
    for left_kinds, right_kinds in cases:
        lines.append(f"{len(left_kinds)} {len(right_kinds)}")
        lines.append(" ".join(map(str, left_kinds)))
        lines.append(" ".join(map(str, right_kinds)))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([1], [1]), ([1], [2]), ([6], [2, 3]), ([2, 3], [6, 10])])
    rng = random.Random(20261126)
    write("3_wide", [([rng.randint(1, 30) for _ in range(10)],
                      [rng.randint(1, 30) for _ in range(10)]) for _ in range(30)])
    write("4_random", [([rng.randint(1, 60) for _ in range(rng.randint(1, 9))],
                        [rng.randint(1, 60) for _ in range(rng.randint(1, 9))]) for _ in range(80)])
    write("5_io", [([rng.randint(1, 20), rng.randint(1, 20), rng.randint(1, 20)],
                    [rng.randint(1, 20), rng.randint(1, 20), rng.randint(1, 20)])
                   for _ in range(30000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([3, 4, 5], [6, 30, 1, 7])])
build()
