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
        egg_count = tokens[cursor]
        target_broken = tokens[cursor + 1]
        cursor += 2
        values = tokens[cursor:cursor + egg_count]
        cursor += egg_count
        values.sort()
        infinity = 10 ** 30
        previous = [0] * (egg_count + 1)
        for broken in range(1, target_broken + 1):
            current = [infinity] * (egg_count + 1)
            for available in range(broken, egg_count + 1):
                best = infinity
                for first_group in range(broken, available + 1):
                    group_size = available - first_group + 1
                    candidate = previous[first_group - 1] + group_size * values[first_group - 1]
                    if candidate < best:
                        best = candidate
                current[available] = best
            previous = current
        answers.append(str(previous[egg_count]))
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """3
2 1
5 8
2 1
5 58
3 2
1 2 3
"""
SAMPLE_OUT = """8
10
5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n4 3\n101 100 3 2\n") == "109\n"
assert oracle("1\n2 2\n7 9\n") == "16\n"
assert oracle("1\n5 1\n5 5 5 5 5\n") == "5\n"
assert oracle("1\n1 1\n42\n") == "42\n"


def write(name, cases):
    lines = [str(len(cases))]
    for egg_count, target_broken, values in cases:
        lines.append(f"{egg_count} {target_broken}")
        lines.append(" ".join(str(value) for value in values))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, 1, [9]),
        (2, 1, [5, 5]),
        (3, 3, [1, 2, 3]),
        (4, 1, [101, 100, 3, 2]),
    ])
    wide = [1000000, 1, 999999, 2, 750000, 3]
    for value in range(4, 140):
        wide.append((value * 5678) % 1000000 + 1)
    write("3_wide", [(len(wide), len(wide) // 2, wide)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(8):
        egg_count = rng.randint(2, 70)
        random_cases.append((
            egg_count,
            rng.randint(1, egg_count),
            [rng.randint(1, 1000000) for _ in range(egg_count)],
        ))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(500):
        egg_count = rng.randint(4, 12)
        io_cases.append((
            egg_count,
            rng.randint(1, egg_count),
            [rng.randint(1, 1000000) for _ in range(egg_count)],
        ))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    (2, 1, [5, 8]),
    (2, 1, [5, 58]),
    (3, 2, [1, 2, 3]),
])
build()
