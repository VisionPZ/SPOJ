#!/usr/bin/env python3
import bisect
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute(values):
    array = list(values)
    size = len(array)
    for position in range(size):
        for earlier in range(position):
            if array[earlier] >= array[position]:
                array[earlier] += 1
    return array


def fast_oracle(values):
    used = []
    answer = [0] * len(values)
    for position in range(len(values) - 1, -1, -1):
        start = values[position]
        low = 0
        high = len(values)
        while low < high:
            middle = (low + high) // 2
            if middle >= bisect.bisect_right(used, start + middle):
                high = middle
            else:
                low = middle + 1
        value = start + low
        answer[position] = value
        bisect.insort(used, value)
    return answer


def oracle(text):
    tokens = text.split()
    size = int(tokens[0])
    values = [int(value) for value in tokens[1:1 + size]]
    result = brute(values) if size <= 400 else fast_oracle(values)
    return " ".join(str(value) for value in result) + "\n"


SAMPLE = """4
4 2 1 3
"""
SAMPLE_OUT = """7 4 1 3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5\n") == "5\n"
assert oracle("2\n1 1\n") == "2 1\n"
assert brute([4, 2, 1]) == [6, 3, 1]
assert oracle("3\n4 2 1\n") == "6 3 1\n"
for trial in range(30):
    sample = [1 + (trial * index + index * index) % 7 for index in range(trial + 1)]
    assert brute(sample) == fast_oracle(sample)


def write(name, values):
    text = str(len(values)) + "\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1])
    rng = random.Random(20261126)
    write("3_wide", [1] * 300)
    write("4_random", [rng.randint(1, 1000000000) for _ in range(120)])
    write("5_io", [rng.randint(1, 1000000000) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
def trace_example():
    array = [4, 2, 1, 3]
    print("start", array[:])
    for position in range(1, len(array)):
        for earlier in range(position):
            if array[earlier] >= array[position]:
                array[earlier] += 1
        print("i", position + 1, array[:])


trace_example()
