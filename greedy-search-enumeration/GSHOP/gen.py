#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
NEG_INF = -10**15


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        element_count = tokens[cursor]
        operation_count = tokens[cursor + 1]
        cursor += 2
        values = tokens[cursor:cursor + element_count]
        cursor += element_count
        previous = [NEG_INF] * (operation_count + 1)
        previous[0] = 0
        for value in values:
            current = [NEG_INF] * (operation_count + 1)
            for used in range(operation_count + 1):
                for flips in range(used + 1):
                    if previous[used - flips] == NEG_INF:
                        continue
                    contribution = value if flips % 2 == 0 else -value
                    current[used] = max(current[used], previous[used - flips] + contribution)
            previous = current
        answers.append(str(previous[operation_count]))
    return "\n".join(answers) + "\n"


SAMPLE = "1\n3 1\n-1 -1 1\n"
SAMPLE_OUT = "1\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1\n0 5\n") == "5\n"
assert oracle("1\n2 1\n1 2\n") == "1\n"
assert oracle("1\n2 3\n-5 -1\n") == "4\n"
assert oracle("1\n3 2\n-3 -2 4\n") == "9\n"


def write(name, cases):
    lines = [str(len(cases))]
    for element_count, operation_count, values in cases:
        lines.append(f"{element_count} {operation_count}")
        lines.append(" ".join(str(value) for value in values))
        assert values == sorted(values)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edges = [
        (3, 1, [-1, -1, 1]),
        (3, 2, [-1, -1, 1]),
        (2, 3, [-5, -1]),
        (2, 1, [0, 5]),
        (3, 5, [-100000, 0, 100000]),
        (1, 100, [7]),
    ]
    write("2_edges", edges)
    rng = random.Random(20261126)
    wide = []
    for _ in range(10):
        values = sorted(rng.randint(-100000, 100000) for _ in range(100))
        wide.append((100, 100, values))
    write("3_wide", wide)
    random_cases = []
    for _ in range(10):
        element_count = rng.randint(1, 100)
        operation_count = rng.randint(1, 100)
        values = sorted(rng.randint(-100000, 100000) for _ in range(element_count))
        random_cases.append((element_count, operation_count, values))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(10):
        values = sorted(rng.randint(-100000, 100000) for _ in range(100))
        io_cases.append((100, rng.randint(1, 100), values))
    write("5_io", io_cases)


def trace():
    values = [-1, -1, 1]
    operation_count = 1
    total = sum(values)
    gain = 0
    for value in values[:operation_count]:
        if value < 0:
            gain -= value
    print(f"values: {values}  total: {total}  flips: {operation_count}")
    print(f"first negative flipped: gain {gain}, running sum {total + 2 * gain}")
    print(f"final answer: {total + 2 * gain}")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
trace()
