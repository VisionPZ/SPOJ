#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    lines = []
    for _ in range(case_count):
        size = tokens[cursor]
        cursor += 1
        values = tokens[cursor:cursor + size]
        cursor += size
        target = tokens[cursor]
        cursor += 1
        found = False
        for first_index in range(size - 2):
            for second_index in range(first_index + 1, size - 1):
                for third_index in range(second_index + 1, size):
                    if values[first_index] + values[second_index] + values[third_index] == target:
                        found = True
                        break
                if found:
                    break
            if found:
                break
        lines.append("YES" if found else "NO")
    return "\n".join(lines) + "\n"


SAMPLE = "1\n3\n1 2 3\n6\n"
SAMPLE_OUT = "YES\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3\n1 2 3\n7\n") == "NO\n"
assert oracle("1\n4\n5 5 5 1\n11\n") == "YES\n"
assert oracle("2\n3\n1 2 3\n6\n3\n10 20 30\n61\n") == "YES\nNO\n"
assert oracle("1\n5\n1 1 2 2 3\n6\n") == "YES\n"


def write(name, cases):
    blocks = [str(len(cases))]
    for values, target in cases:
        blocks.append(str(len(values)))
        blocks.append(" ".join(str(value) for value in values))
        blocks.append(str(target))
    text = "\n".join(blocks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([1, 2, 3], 7), ([5, 5, 5, 1], 11), ([1, 2, 3], 4)])
    write("3_wide", [([1000000000, 999999999, 1, 2], 1000000002),
                     ([1000000000, 1000000000, 1000000000], 3000000000)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(8):
        values = [rng.randint(1, 1000) for _ in range(rng.randint(3, 25))]
        target = rng.randint(3, 3000)
        random_cases.append((values, target))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(15):
        values = [rng.randint(1, 1000) for _ in range(30)]
        target = rng.choice([sum(rng.sample(values, 3)) if len(values) >= 3 else 1, rng.randint(3, 3000)])
        io_cases.append((values, target))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([1, 2, 3], 6)])
build()
