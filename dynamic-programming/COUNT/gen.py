#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1988


@lru_cache(maxsize=None)
def enumerate_partitions(total, parts, largest):
    if parts == 0:
        return 1 if total == 0 else 0
    if total < parts or largest < 1:
        return 0
    answer = 0
    for first in range(min(total, largest), 0, -1):
        answer += enumerate_partitions(total - first, parts - 1, first)
    return answer


def oracle(text):
    tokens = text.split()
    answers = []
    cursor = 0
    while cursor + 1 < len(tokens):
        computers = int(tokens[cursor])
        trucks = int(tokens[cursor + 1])
        cursor += 2
        if computers == 0 and trucks == 0:
            break
        answers.append(str(enumerate_partitions(computers, trucks, computers) % MODULUS))
    if not answers:
        return ""
    return "\n".join(answers) + "\n"


SAMPLE_IN = "1 1\n7 3\n0 0\n"
SAMPLE_OUT = "1\n4\n"
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert enumerate_partitions(1, 1, 1) == 1
assert enumerate_partitions(7, 3, 7) == 4
assert enumerate_partitions(17, 3, 17) == 24
assert enumerate_partitions(10, 5, 10) == 7


def write(name, pairs):
    input_text = "".join(f"{computers} {trucks}\n" for computers, trucks in pairs)
    input_text += "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(1, 1), (2, 1), (2, 2), (3, 2), (500, 1)])
    write("3_wide", [(30, 15), (25, 5), (40, 20), (36, 6)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 35), rng.randint(1, 35)) for _ in range(120)])
    wide_io = []
    for index in range(20000):
        computers = rng.randint(1, 30)
        wide_io.append((computers, rng.randint(1, computers)))
    write("5_io", wide_io)
    (Path("/tmp") / "COUNT_big.txt").write_text("5000 2500\n5000 5000\n4999 1250\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 1), (7, 3)])
build()
