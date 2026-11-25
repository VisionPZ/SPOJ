#!/usr/bin/env python3
import random
import sys
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "3\n1 2 3\n"
SAMPLE_OUTPUT = "2\n1\n1\n"


@lru_cache(maxsize=None)
def grundy(size):
    reachable = set()
    for split in range(1, size):
        reachable.add(grundy(split) ^ grundy(size - split))
    result = 0
    while result in reachable:
        result += 1
    return result


def oracle(text):
    parts = text.split()
    count = int(parts[0])
    even_count = 0
    answers = []
    for index in range(count):
        value = int(parts[index + 1])
        if value % 2 == 0:
            even_count += 1
        answers.append("1\n" if even_count % 2 == 1 else "2\n")
    return "".join(answers)


def write(name, values):
    input_text = str(len(values)) + "\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert [grundy(size) for size in range(1, 11)] == [0, 1, 0, 1, 0, 1, 0, 1, 0, 1]
assert oracle("5\n1 1 5 1 1\n") == "2\n2\n2\n2\n2\n"
assert oracle("1\n2\n") == "1\n"
assert oracle("2\n3 3\n") == "2\n2\n"


def build():
    write("2_edges", [1, 1, 5, 1, 1])
    write("3_wide", [1, 2, 3, 1000000000] * 25000)

    random.seed(42421)
    write("4_random", [random.randint(1, 10**9) for _ in range(5000)])

    random.seed(76767)
    write("5_io", [random.randint(1, 10**9) for _ in range(100000)])


def trace_example():
    nim_value = 0
    for size in [1, 2, 3]:
        nim_value ^= grundy(size)
        print("cycle size", size, "grundy", grundy(size), "nim", nim_value,
              "answer", "1" if nim_value != 0 else "2")


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [1, 2, 3])
    build()
