#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "5\n2 1 3 2 100\n"
SAMPLE_OUT = "4\n"


def oracle(input_text):
    tokens = input_text.split()
    count = int(tokens[0])
    ids = sorted(int(token) for token in tokens[1:1 + count])
    distinct = 0
    previous = -1
    for value in ids:
        if value != previous:
            distinct += 1
            previous = value
    return str(distinct) + "\n"


def write(name, ids):
    input_text = "%d\n%s\n" % (len(ids), " ".join(str(v) for v in ids))
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    ids = [2, 1, 3, 2, 100]
    print("ids 2 1 3 2 100")
    print("sorted 1 2 2 3 100")
    print("run heads 1 2 3 100")
    print("answer 4")


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n7\n") == "1\n"
assert oracle("4\n5 5 5 5\n") == "1\n"
assert oracle("3\n1 2 3\n") == "3\n"
assert oracle("2\n1 100000\n") == "2\n"


def build():
    write("2_edges", [1, 100000, 100000, 1, 50000])
    write("3_wide", [100000] * 100000)
    rng = random.Random(1902)
    full_range = list(range(1, 100001))
    rng.shuffle(full_range)
    write("4_random", full_range)
    io_cases = [rng.randint(1, 100000) for _ in range(100000)]
    write("5_io", io_cases)
    write("6_single", [42])
    write("7_same", [7] * 1000)
    write("8_lowhigh", [1] * 50000 + [100000] * 50000)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
        (ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
        build()
