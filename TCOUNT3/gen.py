#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(maxsize=None)
def hexagram_count(level):
    side = 3 * level
    origin_a = -level
    origin_b = -level

    def in_up(a, b):
        return a >= 0 and b >= 0 and a + b <= side

    def in_down(a, b):
        return a <= origin_a + side and b <= origin_b + side and a + b >= origin_a + origin_b + side

    cells = set()
    for a in range(-side - 2, 2 * side + 3):
        for b in range(-side - 2, 2 * side + 3):
            if in_up(a, b) and in_up(a + 1, b) and in_up(a, b + 1):
                cells.add((a, b, "u"))
            if in_up(a + 1, b) and in_up(a, b + 1) and in_up(a + 1, b + 1):
                cells.add((a, b, "d"))
            if in_down(a + 1, b) and in_down(a, b + 1) and in_down(a + 1, b + 1):
                cells.add((a, b, "d"))
            if in_down(a, b) and in_down(a + 1, b) and in_down(a, b + 1):
                cells.add((a, b, "u"))

    total = 0
    for size in range(1, side + 1):
        for a in range(-side - 2, 2 * side + 3):
            for b in range(-side - 2, 2 * side + 3):
                upward = all((a + i, b + j, "u") in cells
                             for i in range(size) for j in range(size - i))
                upward = upward and all((a + i, b + j, "d") in cells
                                        for i in range(size - 1) for j in range(size - 1 - i))
                if upward:
                    total += 1
                downward = all((a + size - 1 - i, b + size - 1 - j, "d") in cells
                               for i in range(size) for j in range(size - i))
                downward = downward and all((a + size - 1 - i, b + size - 1 - j, "u") in cells
                                            for i in range(size - 1) for j in range(size - 1 - i))
                if downward:
                    total += 1
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = [str(hexagram_count(tokens[index + 1])) for index in range(case_count)]
    return "\n".join(answers) + "\n"


SAMPLE = "1\n1\n"
SAMPLE_OUT = "20\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n") == "118\n"
assert oracle("1\n3\n") == "354\n"
assert oracle("1\n5\n") == "1480\n"
assert oracle("2\n1\n4\n") == "20\n788\n"


def write(name, levels):
    text = str(len(levels)) + "\n" + "".join(str(level) + "\n" for level in levels)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5])
    write("3_wide", [6, 6, 5])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 6) for _ in range(50)])
    write("5_io", [rng.choice([2, 3, 4]) for _ in range(2500)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1])
build()
