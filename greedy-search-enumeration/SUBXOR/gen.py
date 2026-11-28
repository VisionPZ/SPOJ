#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        count = tokens[cursor]
        limit = tokens[cursor + 1]
        cursor += 2
        values = tokens[cursor:cursor + count]
        cursor += count
        answer = 0
        for start in range(count):
            running = 0
            for end in range(start, count):
                running ^= values[end]
                if running < limit:
                    answer += 1
        answers.append(str(answer))
    return "\n".join(answers) + "\n"


SAMPLE = """1
5 2
4 1 3 2 7
"""
SAMPLE_OUT = """3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 2\n1\n") == "1\n"
assert oracle("1\n2 1\n1 1\n") == "1\n"
assert oracle("1\n2 5\n1 2\n") == "3\n"
assert oracle("1\n3 1000000\n1 2 3\n") == "6\n"


def write(name, cases, expected=None):
    input_text = str(len(cases)) + "\n" + "".join(
        f"{len(values)} {limit}\n" + " ".join(str(value) for value in values) + "\n"
        for values, limit in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    if expected is None:
        expected = oracle(input_text)
    (ROOT / "out" / f"{name}.out").write_text(expected)


def build():
    write("2_edges", [([1], 2), ([1, 1], 1), ([1, 2], 5), ([7], 1)])
    write("3_wide", [(list(range(1, 1001)), 1000000)])
    rng = random.Random(20261126)
    write("4_random", [([rng.randint(1, 100000) for _ in range(1200)], rng.randint(1, 1000))
                       for _ in range(3)])
    large_count = 100000
    assert large_count * (large_count + 1) // 2 == 5000050000
    assert 1000000 > 131071
    write("5_io", [([rng.randint(1, 100000) for _ in range(large_count)], 1000000)],
          "5000050000\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([4, 1, 3, 2, 7], 2)])
build()
