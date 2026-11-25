#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 10 ** 9 + 7


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []

    @lru_cache(maxsize=None)
    def ways(height, flowers):
        if height == 1:
            return 1 % MODULUS
        smaller = flowers // 2
        larger = (flowers + 1) // 2
        if smaller == larger:
            return ways(height - 1, smaller) ** 2 % MODULUS
        return 2 * ways(height - 1, smaller) * ways(height - 1, larger) % MODULUS

    for index in range(case_count):
        height = tokens[1 + 2 * index]
        flowers = tokens[2 + 2 * index]
        answers.append(str(ways(height, flowers)))
    return "\n".join(answers) + "\n"


SAMPLE = "2\n1 1\n2 1\n"
SAMPLE_OUT = "1\n2\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 7\n") == "1\n"
assert oracle("1\n2 7\n") == "2\n"
assert oracle("1\n3 5\n") == "4\n"
assert oracle("1\n4 5\n") == "32\n"
assert oracle("1\n7 4\n") == "65536\n"


def write(name, pairs):
    text = str(len(pairs)) + "".join(f"\n{height} {flowers}" for height, flowers in pairs) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (1, 50000), (2, 1), (2, 2), (3, 1)])
    write("3_wide", [(50, 50000), (50, 49999), (40, 12345), (12, 7)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 50), rng.randint(1, 50000)) for _ in range(100)])
    write("5_io", [(rng.randint(1, 50), rng.randint(1, 50000)) for _ in range(5000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 1), (2, 1)])
build()
