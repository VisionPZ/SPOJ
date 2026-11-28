#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "3\n5 6\n8 9\n10 3\n"
SAMPLE_OUTPUT = "3\n"


def oracle(text):
    parts = text.split()
    count = int(parts[0])
    cursor = 1
    left = []
    right = []
    for _ in range(count):
        left.append(int(parts[cursor]))
        cursor += 1
        right.append(int(parts[cursor]))
        cursor += 1
    prefix_left = [0] * (count + 1)
    prefix_right = [0] * (count + 1)
    for index in range(count):
        prefix_left[index + 1] = prefix_left[index] + left[index]
        prefix_right[index + 1] = prefix_right[index] + right[index]
    total_left = prefix_left[count]
    total_right = prefix_right[count]
    best = abs(total_left - total_right)
    answer = 0
    for index in range(count):
        swapped_left = prefix_left[index] + right[index] + total_left - prefix_left[index + 1]
        swapped_right = prefix_right[index] + left[index] + total_right - prefix_right[index + 1]
        beauty = abs(swapped_left - swapped_right)
        if beauty > best:
            best = beauty
            answer = index + 1
    return str(answer) + "\n"


def write(name, pairs):
    lines = [str(len(pairs))]
    lines.extend(f"{left} {right}" for left, right in pairs)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("2\n6 5\n5 6\n") == "1\n"
assert oracle("6\n5 9\n1 3\n4 8\n4 5\n23 54\n12 32\n") == "0\n"
assert oracle("1\n1 2\n") == "0\n"
assert oracle("1\n500 1\n") == "0\n"


def build():
    write("2_edges", [(1, 1), (500, 1), (1, 500)])
    write("3_wide", [(1, 500)] * 100000)

    random.seed(33441)
    write("4_random", [(random.randint(1, 500), random.randint(1, 500))
                       for _ in range(2000)])

    random.seed(88991)
    write("5_io", [(random.randint(1, 500), random.randint(1, 500))
                   for _ in range(100000)])


def trace_example():
    pairs = [(5, 6), (8, 9), (10, 3)]
    total_left = sum(pair[0] for pair in pairs)
    total_right = sum(pair[1] for pair in pairs)
    difference = total_left - total_right
    print("columns:", " ".join(f"({left},{right})" for left, right in pairs))
    print("left total", total_left, "right total", total_right)
    print("current difference", difference, "beauty", abs(difference))
    best = abs(difference)
    answer = 0
    for index, pair in enumerate(pairs):
        change = pair[0] - pair[1]
        swapped = abs(difference - 2 * change)
        print("column", index + 1, "change", change, "swapped beauty", swapped)
        if swapped > best:
            best = swapped
            answer = index + 1
    print("best column", answer)


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [(5, 6), (8, 9), (10, 3)])
    build()
