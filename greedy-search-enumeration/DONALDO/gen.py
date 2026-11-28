#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def to_seconds(text):
    parts = [int(value) for value in text.split(":")]
    return parts[0] * 3600 + parts[1] * 60 + parts[2]


def oracle(text):
    tokens = iter(text.split())
    test_count = int(next(tokens))
    answers = []
    for case_number in range(1, test_count + 1):
        text_count = int(next(tokens))
        moments = []
        for _ in range(text_count):
            moments.append(to_seconds(next(tokens)))
        interval_length = int(next(tokens))
        moments.sort()
        best = 0
        left = 0
        for right, moment in enumerate(moments):
            while moment - moments[left] >= interval_length:
                left += 1
            best = max(best, right - left + 1)
        answers.append(f"Case {case_number}: {best}")
    return "\n".join(answers) + "\n"


SAMPLE = """2
3
8:39:17
17:17:17
21:59:59
86400
3
17:17:17
21:59:59
8:39:16
48042
"""
SAMPLE_OUT = """Case 1: 3
Case 2: 2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0\n1\n") == "Case 1: 0\n"
assert oracle("1\n2\n0:0:0\n0:0:0\n1\n") == "Case 1: 2\n"
assert oracle("1\n2\n23:59:59\n0:0:0\n2\n") == "Case 1: 1\n"
assert to_seconds("8:39:17") == 31157


def dataset(text_count, interval_length, rng=None, fixed=None):
    lines = [str(text_count)]
    for _ in range(text_count):
        if fixed is not None:
            moment = fixed
        elif rng is not None:
            moment = rng.randint(0, 86399)
        else:
            moment = 0
        hour = moment // 3600
        minute = (moment // 60) % 60
        second = moment % 60
        lines.append(f"{hour}:{minute}:{second}")
    lines.append(str(interval_length))
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for case in cases:
        text += case
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        dataset(0, 1),
        dataset(1, 86400, fixed=0),
        dataset(3, 1, fixed=62237),
        dataset(2, 2, fixed=50000),
    ])
    rng = random.Random(20261126)
    write("3_wide", [dataset(20000, 86400, rng=rng)])
    write("4_random", [dataset(rng.randint(0, 200), rng.randint(1, 86400), rng=rng) for _ in range(12)])
    write("5_io", [dataset(20000, 48042, rng=rng) for _ in range(50)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
