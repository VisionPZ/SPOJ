#!/usr/bin/env python3
import bisect
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "2 7 10\n5 6\n"
SAMPLE_OUTPUT = "1\n"
SECOND_INPUT = "1 5 10\n7\n"
SECOND_OUTPUT = "0\n"


def parse_case(text):
    tokens = text.split()
    orange_count = int(tokens[0])
    largest_fitting_size = int(tokens[1])
    waste_capacity = int(tokens[2])
    sizes = [int(token) for token in tokens[3:3 + orange_count]]
    return orange_count, largest_fitting_size, waste_capacity, sizes


def oracle(text):
    orange_count, largest_fitting_size, waste_capacity, sizes = parse_case(text)
    accepted = [size for size in sizes if size <= largest_fitting_size]
    prefix = [0]
    for size in accepted:
        prefix.append(prefix[-1] + size)
    position = 0
    empty_count = 0
    while position < len(accepted):
        threshold = prefix[position] + waste_capacity
        overflow = bisect.bisect_right(prefix, threshold, position + 1)
        if overflow == len(prefix):
            break
        empty_count += 1
        position = overflow
    if position < len(accepted):
        empty_count += 1
    return str(empty_count) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle(SECOND_INPUT) == SECOND_OUTPUT
assert oracle("3 10 10\n10 10 10\n") == "2\n"
assert oracle("3 5 10\n6 6 6\n") == "0\n"
assert oracle("1 1 1\n1\n") == "1\n"
assert oracle("4 7 10\n5 6 3 2\n") == "2\n"


def write(name, orange_count, largest_fitting_size, waste_capacity, sizes):
    input_text = (f"{orange_count} {largest_fitting_size} {waste_capacity}\n"
                  + " ".join(str(size) for size in sizes) + "\n")
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace():
    orange_count, largest_fitting_size, waste_capacity, sizes = parse_case("4 7 10\n5 6 3 2\n")
    accepted = [size for size in sizes if size <= largest_fitting_size]
    prefix = [0]
    for size in accepted:
        prefix.append(prefix[-1] + size)
    print(f"accepted sizes {accepted}, capacity {waste_capacity}")
    print("prefix sums", prefix)
    position = 0
    while position < len(accepted):
        threshold = prefix[position] + waste_capacity
        overflow = bisect.bisect_right(prefix, threshold, position + 1)
        print(f"block starts at {position}, threshold {threshold}, overflow at {overflow}")
        if overflow == len(prefix):
            break
        position = overflow
    if position < len(accepted):
        print(f"final block from {position} emptied once")
    print("answer", oracle("4 7 10\n5 6 3 2\n").strip())


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", 2, 7, 10, [5, 6])
        write("2_edges", 1, 5, 10, [7])
        write("3_wide", 100000, 1000000, 1000000, [1] * 100000)
        random.seed(2026)
        largest_fitting_size = random.randint(1, 1000000)
        waste_capacity = random.randint(largest_fitting_size, 1000000)
        random_sizes = [random.randint(1, 1000000) for _ in range(100000)]
        write("4_random", 100000, largest_fitting_size, waste_capacity, random_sizes)
        write("5_io", 100000, 1, 1, [1] * 100000)
