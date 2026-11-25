#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        floor_count = tokens[cursor]
        cursor += 1
        values_a = tokens[cursor:cursor + floor_count + 1]
        cursor += floor_count + 1
        values_b = tokens[cursor:cursor + floor_count + 1]
        cursor += floor_count + 1
        people = tokens[cursor:cursor + floor_count]
        cursor += floor_count

        @lru_cache(maxsize=None)
        def search(floor_index, load_a, load_b, active_a, active_b):
            if floor_index == floor_count:
                return 0
            available = load_a + load_b + people[floor_index]
            step_a = values_a[floor_index] ^ values_a[floor_index + 1]
            step_b = values_b[floor_index] ^ values_b[floor_index + 1]
            best = INF
            for riders_a in range(available + 1):
                riders_b = available - riders_a
                for keep_a in (0, 1):
                    if keep_a and not active_a:
                        continue
                    if not keep_a and riders_a:
                        continue
                    for keep_b in (0, 1):
                        if keep_b and not active_b:
                            continue
                        if not keep_b and riders_b:
                            continue
                        if not keep_a and not keep_b:
                            continue
                        cost_a = step_a ^ riders_a if keep_a else 0
                        cost_b = step_b ^ riders_b if keep_b else 0
                        rest = search(floor_index + 1,
                                      riders_a if keep_a else 0,
                                      riders_b if keep_b else 0,
                                      keep_a, keep_b)
                        total = cost_a + cost_b + rest
                        if total < best:
                            best = total
            return best

        answers.append(str(search(0, 0, 0, 1, 1)))
    return "\n".join(answers) + "\n"


SAMPLE = """2
2
0 1 3
0 1 5
2 1
4
1 3 5 7 9
2 4 6 8 10
1 2 3 4
"""
SAMPLE_OUT = """1
16
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n0 1\n0 1\n1\n") == "0\n"
assert oracle("1\n1\n5 5\n7 7\n1\n") == "1\n"
assert oracle("1\n2\n0 0 0\n0 0 0\n1 1\n") == "3\n"
assert oracle("1\n1\n0 1\n1 0\n3\n") == "2\n"


def write(name, cases):
    chunks = [str(len(cases))]
    for floor_count, values_a, values_b, people in cases:
        chunks.append(str(floor_count))
        chunks.append(" ".join(map(str, values_a)))
        chunks.append(" ".join(map(str, values_b)))
        chunks.append(" ".join(map(str, people)))
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, [0, 1], [0, 1], [1]),
        (1, [5, 5], [7, 7], [1]),
        (2, [0, 0, 0], [0, 0, 0], [1, 1]),
        (3, [1000, 0, 1000, 0], [0, 1000, 0, 1000], [1, 1, 1]),
    ])
    write("3_wide", [
        (6, [1000] * 7, [1000] * 7, [1] * 6),
        (6, list(range(7)), list(range(6, -1, -1)), [1, 2, 1, 2, 1, 2]),
    ])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(30):
        floor_count = rng.randint(1, 6)
        values_a = [rng.randint(0, 1000) for _ in range(floor_count + 1)]
        values_b = [rng.randint(0, 1000) for _ in range(floor_count + 1)]
        people = [1] * floor_count
        for _ in range(rng.randint(0, 4)):
            people[rng.randrange(floor_count)] += 1
        random_cases.append((floor_count, values_a, values_b, people))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(300):
        floor_count = rng.randint(1, 3)
        values_a = [rng.randint(0, 1000) for _ in range(floor_count + 1)]
        values_b = [rng.randint(0, 1000) for _ in range(floor_count + 1)]
        people = [1] * floor_count
        io_cases.append((floor_count, values_a, values_b, people))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
