#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STRESS_PATH = Path("/tmp/RLCAT_big.txt")


def oracle_case(values, threshold):
    student_count = len(values)

    @lru_cache(None)
    def best_from(index):
        if index >= student_count:
            return 0
        answer = 10**9
        position = index
        while position < student_count and abs(values[position] - values[index]) <= threshold:
            answer = min(answer, 1 + best_from(position + 1))
            position += 1
        return answer

    return best_from(0)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        student_count = tokens[cursor]
        threshold = tokens[cursor + 1]
        cursor += 2
        values = tokens[cursor:cursor + student_count]
        cursor += student_count
        answers.append(str(oracle_case(values, threshold)))
    return "\n".join(answers) + "\n"


SAMPLE = "2\n5 2\n3 1 2 4 5\n5 3\n1 4 7 1 5\n"
SAMPLE_OUT = "1\n2\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n7\n") == "1\n"
assert oracle("1\n5 1\n3 3 3 3 3\n") == "1\n"
assert oracle_case([2, 4, 9, 2, 1, 1, 9], 5) == 2
assert oracle_case([1, 4, 7, 1, 5], 3) == 2
assert oracle_case([1, 100, 1, 100], 1) == 4


def write(name, cases):
    lines = [str(len(cases))]
    for threshold, values in cases:
        lines.append(f"{len(values)} {threshold}")
        lines.append(" ".join(str(value) for value in values))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, [7]),
        (1, [3, 3, 3, 3, 3]),
        (1, [1, 100, 1, 100]),
        (1000000000, [1, 1000000000, 500000000, 1]),
        (2, [3, 1, 2, 4, 5]),
    ])
    rng = random.Random(20261126)
    wide = []
    for _ in range(6):
        threshold = rng.randint(1, 1000000000)
        values = [rng.randint(1, 1000000000) for _ in range(20)]
        wide.append((threshold, values))
    write("3_wide", wide)
    random_cases = []
    for _ in range(12):
        threshold = rng.randint(1, 20)
        values = [rng.randint(1, 40) for _ in range(rng.randint(5, 20))]
        random_cases.append((threshold, values))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(1000):
        threshold = rng.randint(1, 12)
        values = [rng.randint(1, 30) for _ in range(rng.randint(1, 12))]
        io_cases.append((threshold, values))
    write("5_io", io_cases)
    stress_values = [rng.randint(1, 1000000000) for _ in range(300000)]
    STRESS_PATH.write_text("1\n300000 1000000000\n" +
                           " ".join(str(value) for value in stress_values) + "\n")


def trace():
    values = [2, 4, 9, 2, 1, 1, 9]
    threshold = 5
    print(f"values: {values}  threshold: {threshold}")
    for start in range(len(values)):
        end = start
        while end < len(values) and abs(values[end] - values[start]) <= threshold:
            end += 1
        print(f"start {start}: owner {values[start]}, covers through {end - 1}")
    print(f"minimum pens: {oracle_case(values, threshold)}")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
trace()
