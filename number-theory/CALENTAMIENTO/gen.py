#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "5\n1 3 3 2 1\n"
SAMPLE_OUTPUT = "Si\n"


def oracle(text):
    parts = text.split()
    count = int(parts[0])
    values = [int(item) for item in parts[1:1 + count]]
    levels = sorted(set(values))
    if len(levels) <= 2:
        return "Si\n"
    if len(levels) == 3 and levels[0] + levels[2] == 2 * levels[1]:
        return "Si\n"
    return "No\n"


def write(name, values):
    input_text = str(len(values)) + "\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n7\n") == "Si\n"
assert oracle("2\n7 9\n") == "Si\n"
assert oracle("3\n1 2 4\n") == "No\n"
assert oracle("4\n0 5 10 10\n") == "Si\n"


def build():
    write("2_edges", [0])

    step = 500000000
    write("3_wide", [(index % 3) * step for index in range(100000)])

    random.seed(7123)
    mixed = []
    for _ in range(1600):
        pattern = random.randrange(3)
        if pattern == 0:
            low = random.randint(0, 10**9 - 2)
            gap = random.randint(1, (10**9 - low) // 2)
            mixed.extend([low, low + gap, low + 2 * gap])
        elif pattern == 1:
            mixed.append(random.randint(0, 10**9))
            mixed.append(random.randint(0, 10**9))
        else:
            mixed.extend(random.randint(0, 10**9) for _ in range(4))
    write("4_random", mixed)

    random.seed(90125)
    write("5_io", [random.randint(0, 10**9) for _ in range(100000)])


def trace_example():
    values = [1, 3, 3, 2, 1]
    seen = []
    for value in values:
        if value not in seen:
            seen.append(value)
    levels = sorted(seen)
    print("values:", *values)
    print("distinct levels seen:", *seen)
    print("sorted levels:", *levels)
    print("outer plus inner:", levels[0], "+", levels[2], "=", levels[0] + levels[2])
    print("twice middle:", "2 *", levels[1], "=", 2 * levels[1])
    print("verdict:", "Si" if levels[0] + levels[2] == 2 * levels[1] else "No")


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [1, 3, 3, 2, 1])
    build()
