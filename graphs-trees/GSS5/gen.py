#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        count = tokens[cursor]
        cursor += 1
        values = tokens[cursor:cursor + count]
        cursor += count
        queries = tokens[cursor]
        cursor += 1
        for _ in range(queries):
            first_left = tokens[cursor] - 1
            first_right = tokens[cursor + 1] - 1
            second_left = tokens[cursor + 2] - 1
            second_right = tokens[cursor + 3] - 1
            cursor += 4
            best = None
            for start in range(first_left, first_right + 1):
                total = 0
                for end in range(start, max(first_right, second_right) + 1):
                    total += values[end]
                    if second_left <= end <= second_right and start <= end:
                        if best is None or total > best:
                            best = total
            answers.append(str(best))
    return "\n".join(answers) + "\n"


def scan_oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        count = tokens[cursor]
        cursor += 1
        values = tokens[cursor:cursor + count]
        cursor += count
        queries = tokens[cursor]
        cursor += 1
        prefix = [0]
        for value in values:
            prefix.append(prefix[-1] + value)
        for _ in range(queries):
            first_left = tokens[cursor] - 1
            first_right = tokens[cursor + 1] - 1
            second_left = tokens[cursor + 2] - 1
            second_right = tokens[cursor + 3] - 1
            cursor += 4
            best = None
            smallest = None
            added_through = first_left - 1
            for end in range(first_left, second_right + 1):
                upper = min(first_right, end)
                for start in range(added_through + 1, upper + 1):
                    if smallest is None or prefix[start] < smallest:
                        smallest = prefix[start]
                added_through = upper
                if end >= second_left and smallest is not None:
                    candidate = prefix[end + 1] - smallest
                    if best is None or candidate > best:
                        best = candidate
            answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE_IN = """2
6 3 -2 1 -4 5 2
2
1 1 2 3
1 3 2 5
1 1
1
1 1 1 1
"""
SAMPLE_OUT = """2
3
1
"""
assert brute_oracle(SAMPLE_IN) == SAMPLE_OUT
assert scan_oracle(SAMPLE_IN) == SAMPLE_OUT
assert brute_oracle("1\n1 -5\n1\n1 1 1 1\n") == "-5\n"
assert scan_oracle("1\n2 -5 7\n1\n1 2 1 2\n") == "7\n"
assert brute_oracle("1\n3 1 -2 3\n1\n1 1 2 3\n") == "2\n"


def make_case(values, queries):
    lines = [str(len(values)) + " " + " ".join(str(value) for value in values)]
    lines.append(str(len(queries)))
    lines.extend(" ".join(str(value) for value in query) for query in queries)
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(make_case(values, queries)
                                            for values, queries in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(scan_oracle(text))


def random_queries(rng, count, length):
    queries = []
    for _ in range(count):
        first_left = rng.randint(1, length)
        first_right = rng.randint(first_left, length)
        second_left = rng.randint(first_left, length)
        second_right = rng.randint(second_left, length)
        queries.append((first_left, first_right, second_left, second_right))
    return queries


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        ([1], [(1, 1, 1, 1)]),
        ([-7, -2, -9], [(1, 2, 2, 3), (1, 3, 1, 3), (2, 2, 2, 2)]),
        ([0, 0, 0, 0], [(1, 2, 3, 4), (1, 4, 1, 4)]),
        ([5, -1, 4, -2, 3], [(1, 1, 2, 5), (2, 4, 3, 5), (1, 5, 1, 5)]),
    ])
    wide_values = [rng.randint(-10000, 10000) for _ in range(3000)]
    write("3_wide", [(wide_values, random_queries(rng, 1200, 3000))])
    random_cases = []
    for _ in range(4):
        length = rng.randint(1, 70)
        random_cases.append(([rng.randint(-10000, 10000) for _ in range(length)],
                             random_queries(rng, 60, length)))
    write("4_random", random_cases)
    io_values = [rng.choice([-10000, -1, 0, 1, 10000]) for _ in range(2000)]
    write("5_io", [(io_values, random_queries(rng, 5000, 2000))])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
