#!/usr/bin/env python3
import random
from bisect import bisect_right
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_case(posters):
    max_section = max(right for _, right in posters)
    covered = [False] * (max_section + 2)
    visible = 0
    for left, right in reversed(posters):
        has_gap = False
        for section in range(left, right + 1):
            if not covered[section]:
                has_gap = True
                break
        if has_gap:
            visible += 1
            for section in range(left, right + 1):
                covered[section] = True
    return visible


def oracle_case(posters):
    interval_starts = []
    interval_ends = []
    visible = 0
    for left, right in reversed(posters):
        before = bisect_right(interval_starts, left) - 1
        if before >= 0 and interval_ends[before] >= right:
            continue
        visible += 1
        merged_start, merged_end = left, right
        merge_from = before + 1
        cursor = before
        while cursor >= 0 and interval_ends[cursor] + 1 >= merged_start:
            merged_start = min(merged_start, interval_starts[cursor])
            merged_end = max(merged_end, interval_ends[cursor])
            merge_from = cursor
            cursor -= 1
        cursor = merge_from
        while cursor < len(interval_starts) and interval_starts[cursor] <= merged_end + 1:
            merged_end = max(merged_end, interval_ends[cursor])
            cursor += 1
        interval_starts[merge_from:cursor] = [merged_start]
        interval_ends[merge_from:cursor] = [merged_end]
    return visible


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        poster_count = int(tokens[cursor])
        cursor += 1
        posters = []
        for _ in range(poster_count):
            left = int(tokens[cursor])
            cursor += 1
            right = int(tokens[cursor])
            cursor += 1
            posters.append((left, right))
        answers.append(str(oracle_case(posters)))
    return "\n".join(answers) + "\n"


def write(name, cases):
    lines = [str(len(cases))]
    for posters in cases:
        lines.append(str(len(posters)))
        for left, right in posters:
            lines.append(f"{left} {right}")
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_TEXT = "1\n5\n1 4\n2 6\n8 10\n3 4\n7 10\n"
GAP_TEXT = "1\n3\n20 30\n10 20\n30 40\n"
assert oracle(SAMPLE_TEXT) == "4\n"
assert oracle(GAP_TEXT) == "3\n"
assert oracle("1\n2\n5 7\n5 7\n") == "1\n"
assert oracle("1\n2\n1 9\n2 8\n") == "2\n"
assert oracle("1\n3\n1 10\n2 9\n1 10\n") == "1\n"

random.seed(7)
for _ in range(400):
    posters = []
    for _ in range(random.randint(1, 12)):
        left = random.randint(1, 40)
        right = random.randint(left + 1, 50)
        posters.append((left, right))
    assert oracle_case(posters) == brute_case(posters), posters


def worked_example():
    posters = [(1, 4), (2, 6), (8, 10), (3, 4), (7, 10)]
    covered = [False] * 12
    visible_numbers = []
    for index in range(len(posters) - 1, -1, -1):
        left, right = posters[index]
        if any(not covered[section] for section in range(left, right + 1)):
            visible_numbers.append(index + 1)
            for section in range(left, right + 1):
                covered[section] = True
    visible_numbers.reverse()
    print("posters checked in reverse: 5 4 3 2 1")
    print("visible poster numbers: " + " ".join(str(number) for number in visible_numbers))
    print("answer: " + str(len(visible_numbers)))


def build():
    edges = [
        [(1, 10)],
        [(5, 7), (5, 7)],
        [(2, 8), (1, 9)],
        [(1, 9), (2, 8)],
        [(20, 30), (10, 20), (30, 40)],
        [(1, 2), (9999999, 10000000)],
        [(1, 100), (2, 99), (3, 98)],
        [(1, 10), (2, 9), (1, 10)],
    ]
    write("2_edges", edges)

    random.seed(20261124)
    low_wide = []
    for _ in range(40000):
        left = random.randint(1, 500000)
        right = min(10000000, left + random.randint(1, 200000))
        low_wide.append((left, right))
    high_wide = []
    for index in range(40000):
        if index % 2 == 0:
            left = random.randint(1, 1000)
            right = left + random.randint(1, 20)
        else:
            right = random.randint(9999000, 10000000)
            left = right - random.randint(1, 20)
        high_wide.append((left, right))
    write("3_wide", [low_wide, high_wide])

    random_cases = []
    for _ in range(5):
        posters = []
        for _ in range(40000):
            left = random.randint(1, 9999999)
            right = random.randint(left + 1, 10000000)
            posters.append((left, right))
        random_cases.append(posters)
    write("4_random", random_cases)

    io_cases = []
    for _ in range(20000):
        left = random.randint(1, 9999999)
        right = random.randint(left + 1, 10000000)
        io_cases.append([(left, right)])
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_TEXT)
(ROOT / "out" / "1_sample.out").write_text(oracle(SAMPLE_TEXT))
build()
worked_example()
