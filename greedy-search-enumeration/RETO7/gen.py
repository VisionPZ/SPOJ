#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "1 6\n3 10\n3 14\n"
SAMPLE_OUTPUT = "3\n5\n6\n"


def days_before(group_count, initial_size):
    return group_count * (2 * initial_size + group_count - 1) // 2


def solve_pair(initial_size, requested_day):
    coefficient = 2 * initial_size - 1
    discriminant = coefficient * coefficient + 8 * requested_day
    finished_groups = (math.isqrt(discriminant) - coefficient) // 2
    while days_before(finished_groups, initial_size) >= requested_day:
        finished_groups -= 1
    while days_before(finished_groups + 1, initial_size) < requested_day:
        finished_groups += 1
    return initial_size + finished_groups


def oracle(text):
    answers = []
    for line in text.splitlines():
        if not line.strip():
            continue
        initial_size, requested_day = (int(value) for value in line.split())
        answers.append(str(solve_pair(initial_size, requested_day)))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1 1\n") == "1\n"
assert oracle("10000 1\n") == "10000\n"
assert oracle("1 3\n") == "2\n"
assert oracle("10000 1000000000000000\n") == "44721361\n"
assert oracle("1 1000000000000000\n") == "44721360\n"


def write(name, pairs):
    input_text = "".join(f"{initial_size} {requested_day}\n" for initial_size, requested_day in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace():
    for line in SAMPLE_INPUT.splitlines():
        initial_size, requested_day = (int(value) for value in line.split())
        finished_groups = solve_pair(initial_size, requested_day) - initial_size
        print(f"start {initial_size}, day {requested_day}: "
              f"first {finished_groups} groups fill {days_before(finished_groups, initial_size)} days, "
              f"group {finished_groups + 1} has {initial_size + finished_groups} members")
    print("next group starts after", days_before(2, 3), "days for start size 3")


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", [(1, 6), (3, 10), (3, 14)])
        write("2_edges", [(1, 1), (10000, 1), (1, 2), (1, 3), (10000, 10**15),
                          (1, 10**15)])
        random.seed(2026)
        wide_pairs = [(random.randint(1, 10000), random.randint(1, 10**15 - 1))
                      for _ in range(200)]
        write("3_wide", wide_pairs)
        random_pairs = [(random.randint(1, 10000), random.randint(1, 10**15 - 1))
                        for _ in range(300)]
        write("4_random", random_pairs)
        io_pairs = [(random.randint(1, 10000), random.randint(1, 10**15 - 1))
                    for _ in range(10000)]
        write("5_io", io_pairs)
