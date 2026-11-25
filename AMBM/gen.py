#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        target = tokens[cursor]
        day_count = tokens[cursor + 1]
        cursor += 2
        salaries = []
        running = 0
        for _ in range(day_count):
            running = 2 * running + tokens[cursor]
            cursor += 1
            salaries.append(running)
        found = None
        for mask in range(1 << day_count):
            total = 0
            for index in range(day_count):
                if mask & (1 << index):
                    total += salaries[index]
            if total == target:
                found = [index + 1 for index in range(day_count)
                         if mask & (1 << index)]
                break
        answers.append(" ".join(str(day) for day in found) if found else "-1")
    return "\n".join(answers) + "\n"


SAMPLE = """2
9 3
1 1 2
10 2
2 3
"""
SAMPLE_OUT = """1 3
-1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n1\n") == "1\n"
assert oracle("1\n3 3\n1 1 1\n") == "2\n"
assert oracle("1\n2 1\n1\n") == "-1\n"


def write(name, cases):
    lines = [str(len(cases))]
    for target, salaries in cases:
        lines.append(f"{target} {len(salaries)}")
        lines.append(" ".join(str(value) for value in salaries))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def salaries_for(values):
    running = 0
    result = []
    for value in values:
        running = 2 * running + value
        result.append(running)
    return result


def build():
    simple = [
        (1, [1]),
        (2, [1]),
        (3, [1, 1, 1]),
        (10, [1, 1, 2]),
        (7, [1, 1]),
    ]
    write("2_edges", simple)

    rng = random.Random(20261126)
    wide = []
    for _ in range(4):
        values = [rng.randint(1, 1000) for _ in range(16)]
        salaries = salaries_for(values)
        chosen = [index for index in range(16) if rng.random() < 0.5]
        if not chosen:
            chosen = [rng.randrange(16)]
        target = sum(salaries[index] for index in chosen)
        wide.append((target, values))
    wide.append((sum(salaries_for([1000] * 16)) + 1, [1000] * 16))
    write("3_wide", wide)

    random_cases = []
    for _ in range(20):
        values = [rng.randint(1, 1000) for _ in range(rng.randint(1, 12))]
        salaries = salaries_for(values)
        target = rng.randint(1, sum(salaries) + 5)
        random_cases.append((target, values))
    write("4_random", random_cases)

    io_cases = []
    for _ in range(400):
        values = [rng.randint(1, 1000) for _ in range(rng.randint(1, 10))]
        salaries = salaries_for(values)
        target = rng.randint(1, sum(salaries))
        io_cases.append((target, values))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(9, [1, 1, 2]), (10, [2, 3])])
build()
