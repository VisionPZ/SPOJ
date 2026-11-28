#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        length = tokens[cursor]
        tolerance = tokens[cursor + 1]
        cursor += 2
        keep = tolerance
        states = {"": 1}
        for _step in range(length):
            following = {}
            for suffix, count in states.items():
                for bit in "01":
                    candidate = suffix + bit
                    blocked = False
                    for size in range(tolerance, min(len(candidate), tolerance + 1) + 1):
                        piece = candidate[-size:]
                        if piece == piece[::-1]:
                            blocked = True
                            break
                    if blocked:
                        continue
                    next_suffix = candidate[-keep:] if keep > 0 else ""
                    following[next_suffix] = (following.get(next_suffix, 0) + count) % MOD
            states = following
        answers.append(str(sum(states.values()) % MOD))
    return "\n".join(answers) + "\n"


def brute(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        length = tokens[cursor]
        tolerance = tokens[cursor + 1]
        cursor += 2
        total = 0
        for number in range(1 << length):
            word = "".join("1" if number & (1 << shift) else "0" for shift in range(length))
            bad = False
            for start in range(length):
                for size in range(tolerance, length - start + 1):
                    piece = word[start:start + size]
                    if piece == piece[::-1]:
                        bad = True
                        break
                if bad:
                    break
            if not bad:
                total += 1
        answers.append(str(total))
    return "\n".join(answers) + "\n"


SAMPLE = """3
2 2
3 3
3 4
"""
SAMPLE_OUT = """2
4
8
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n") == "0\n"
assert oracle("1\n1 2\n") == "2\n"
assert oracle("1\n3 2\n") == "0\n"
for tiny in ["1\n4 2\n", "1\n5 3\n", "1\n6 4\n", "1\n7 2\n"]:
    assert oracle(tiny) == brute(tiny)


def write(name, cases):
    text = str(len(cases)) + "\n" + "\n".join(f"{length} {tolerance}" for length, tolerance in cases) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (1, 2), (2, 2), (3, 2), (3, 3), (3, 4),
                      (4, 3), (10, 2), (12, 10)])
    write("3_wide", [(400, 10), (400, 9), (400, 2), (399, 1)])
    rng = random.Random(20261126)
    random_cases = [(rng.randint(1, 400), rng.randint(1, 10)) for _ in range(20)]
    write("4_random", random_cases)
    write("5_io", [(400, 2) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
