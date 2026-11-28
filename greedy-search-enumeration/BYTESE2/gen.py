#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        visitor_count = tokens[cursor]
        cursor += 1
        deltas = {}
        for _ in range(visitor_count):
            enter = tokens[cursor]
            leave = tokens[cursor + 1]
            cursor += 2
            deltas[enter] = deltas.get(enter, 0) + 1
            deltas[leave] = deltas.get(leave, 0) - 1
        running = 0
        peak = 0
        for moment in sorted(deltas):
            running += deltas[moment]
            if running > peak:
                peak = running
        answers.append(str(peak))
    return "\n".join(answers) + "\n"


SAMPLE_IN = """1
5
1 7
2 4
6 9
3 8
5 10
"""
SAMPLE_OUT = """4
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("1\n1\n1 2\n") == "1\n"
assert oracle("1\n3\n1 10\n2 9\n3 8\n") == "3\n"
assert oracle("2\n1\n5 6\n2\n1 3\n2 4\n") == "1\n2\n"
assert oracle("1\n2\n1 10000000\n9999999 10000000\n") == "2\n"


def write(name, cases):
    lines = [str(len(cases))]
    for pairs in cases:
        lines.append(str(len(pairs)))
        for enter, leave in pairs:
            lines.append(f"{enter} {leave}")
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [[(1, 2)], [(1, 10), (2, 9), (3, 8)], [(4, 5)], [(1, 3), (2, 4), (3, 5)], [(1, 10000000), (9999999, 10000000)]])
    rng = random.Random(20261126)
    wide = []
    for _ in range(12):
        moments = sorted(rng.sample(range(1, 10000001), 200))
        pairs = []
        for index in range(0, 200, 2):
            pairs.append((moments[index], moments[index + 1]))
        wide.append(pairs)
    write("3_wide", wide)
    random_cases = []
    for _ in range(20):
        moments = sorted(rng.sample(range(1, 10000), 100))
        pairs = [(moments[index], moments[index + 1]) for index in range(0, 100, 2)]
        random_cases.append(pairs)
    write("4_random", random_cases)
    io_cases = []
    for case_index in range(100):
        base = case_index * 10001 + 1
        moments = sorted(base + index * 3 for index in range(200))
        pairs = [(moments[index], moments[index + 100]) for index in range(100)]
        io_cases.append(pairs)
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
