#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "5\n3 2 1 2 2\n3\n1 3\n2 5\n2 3\n"
SAMPLE_OUT = "Odd\nEven\nOdd\n"


def build_values(values):
    array = []
    for index, x_value in enumerate(values, start=1):
        if index % 2 == 0:
            array.append(2 * x_value + 1)
        else:
            array.append(2 * x_value)
    return array


def oracle(input_text):
    tokens = input_text.split()
    cursor = 0
    element_count = int(tokens[cursor])
    cursor += 1
    values = [int(tokens[cursor + k]) for k in range(element_count)]
    cursor += element_count
    array = build_values(values)
    prefix = [0]
    for value in array:
        prefix.append(prefix[-1] + value)
    query_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(query_count):
        left_index = int(tokens[cursor])
        right_index = int(tokens[cursor + 1])
        cursor += 2
        window_sum = prefix[right_index] - prefix[left_index - 1]
        answers.append("Even" if window_sum % 2 == 0 else "Odd")
    return "".join(answer + "\n" for answer in answers)


def write(name, element_count, values, queries):
    lines = [str(element_count), " ".join(str(v) for v in values), str(len(queries))]
    lines += ["%d %d" % (left_index, right_index) for left_index, right_index in queries]
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    values = [3, 2, 1, 2, 2]
    array = build_values(values)
    print("x values 3 2 1 2 2")
    print("array    " + " ".join(str(value) for value in array))
    print("query 2 5 sum 5+2+5+4=16 -> Even")


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("2\n1 1\n1\n1 2\n") == "Odd\n"
assert oracle("2\n1 1\n1\n1 1\n") == "Even\n"
assert oracle("4\n1 1 1 1\n2\n1 4\n2 4\n") == "Even\nEven\n"
assert oracle("3\n30 30 30\n1\n2 3\n") == "Odd\n"


def build():
    rng = random.Random(20240222)
    write("2_edges", 1, [30], [(1, 1)])
    write("3_wide", 100000, [rng.randint(1, 30) for _ in range(100000)],
          [(1, 100000)] * 100000)
    random_values = [rng.randint(1, 30) for _ in range(100000)]
    random_queries = []
    for _ in range(100000):
        left_index = rng.randint(1, 100000)
        right_index = rng.randint(left_index, 100000)
        random_queries.append((left_index, right_index))
    write("4_random", 100000, random_values, random_queries)
    io_queries = [(rng.randint(1, 100000), rng.randint(1, 100000)) for _ in range(100000)]
    io_queries = [(min(a, b), max(a, b)) for a, b in io_queries]
    write("5_io", 100000, random_values, io_queries)
    write("6_single_odd", 2, [1, 1], [(2, 2), (1, 1), (1, 2)])
    write("7_full", 6, [5, 6, 7, 8, 9, 10], [(1, 6), (1, 2), (3, 6), (2, 5)])


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
