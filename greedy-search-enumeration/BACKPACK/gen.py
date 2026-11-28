#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        capacity = int(tokens[cursor])
        good_count = int(tokens[cursor + 1])
        cursor += 2
        volumes = []
        values = []
        parents = []
        for _good in range(good_count):
            volume = int(tokens[cursor])
            importance = int(tokens[cursor + 1])
            parent = int(tokens[cursor + 2])
            cursor += 3
            volumes.append(volume)
            values.append(volume * importance)
            parents.append(parent)
        best = 0
        for mask in range(1 << good_count):
            used = 0
            total = 0
            legal = True
            for index in range(good_count):
                if (mask >> index) & 1:
                    used += volumes[index]
                    total += values[index]
                    if parents[index] and not ((mask >> (parents[index] - 1)) & 1):
                        legal = False
                        break
            if legal and used <= capacity and total > best:
                best = total
        answers.append(str(best))
    if not answers:
        return ""
    return "\n".join(answers) + "\n"


SAMPLE_IN = """1
1000 5
800 2 0
400 5 1
300 5 1
400 3 0
500 2 0
"""
SAMPLE_OUT = """2200
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("1\n100 1\n100 5 0\n") == "500\n"
assert oracle("1\n100 2\n100 1 0\n100 5 1\n") == "100\n"
assert oracle("1\n1000 2\n500 1 0\n500 5 1\n") == "3000\n"


def case_text(capacity, goods):
    lines = [f"{capacity} {len(goods)}"]
    lines.extend(f"{volume} {importance} {parent}" for volume, importance, parent in goods)
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(case_text(*case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def random_case(rng, good_limit):
    good_count = rng.randint(1, good_limit)
    goods = []
    main_indexes = []
    attachment_counts = {}
    for index in range(good_count):
        volume = rng.randint(1, 999) * 10
        importance = rng.randint(1, 5)
        available = [main for main in main_indexes if attachment_counts[main] < 2]
        parent = rng.choice(available) if available and rng.random() < 0.4 else 0
        goods.append((volume, importance, parent))
        if parent == 0:
            main_indexes.append(index + 1)
            attachment_counts[index + 1] = 0
        else:
            attachment_counts[parent] += 1
    capacity = rng.randint(1, 3200) * 10
    return (capacity, goods)


def build():
    write("2_edges", [
        (100, [(100, 5, 0)]),
        (100, [(100, 1, 0), (100, 5, 1)]),
        (32000, [(10000, 5, 0), (9000, 5, 1), (8000, 5, 1)]),
        (10, [(10000, 5, 0)]),
    ])
    write("3_wide", [
        (32000, [(8000, 5, 0), (4000, 5, 1), (3000, 5, 1)]),
        (31990, [(9990, 5, 0), (9990, 5, 1)]),
        (10000, [(9990, 1, 0)] * 8),
    ])
    rng = random.Random(20261126)
    write("4_random", [random_case(rng, 12) for _ in range(80)])
    write("5_io", [random_case(rng, 5) for _ in range(30000)])
    (Path("/tmp") / "BACKPACK_big.txt").write_text(
        "1\n32000 60\n" + "".join(
            f"{(index % 999 + 1) * 10} {index % 5 + 1} 0\n" for index in range(60)))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1000, [(800, 2, 0), (400, 5, 1), (300, 5, 1), (400, 3, 0), (500, 2, 0)])])
build()
