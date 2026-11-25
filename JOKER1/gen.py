#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007
TOP_VALUE = 3000


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        knife_count = tokens[cursor]
        cursor += 1
        maxima = tokens[cursor:cursor + knife_count]
        cursor += knife_count
        per_value = [0] * (TOP_VALUE + 1)
        for maximum in maxima:
            per_value[maximum] += 1
        ways = 1
        loaded = 0
        for value in range(1, TOP_VALUE + 1):
            group_size = per_value[value]
            if group_size == 0:
                continue
            free = value - loaded
            if free < group_size:
                ways = 0
                break
            for offset in range(group_size):
                ways = ways * (free - offset) % MODULUS
            loaded += group_size
        answers.append(str(ways % MODULUS))
    return "\n".join(answers) + "\nKILL BATMAN\n"


def brute(maxima):
    count = 0
    for assignment in __import__("itertools").product(
            range(1, max(maxima) + 1), repeat=len(maxima)):
        if len(set(assignment)) == len(assignment):
            if all(assigned <= limit for assigned, limit in zip(assignment, maxima)):
                count += 1
    return count


SAMPLE = """3
1
7
2
5 8
3
2 1 2
"""
SAMPLE_OUT = """7
35
0
KILL BATMAN
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n5\n") == "5\nKILL BATMAN\n"
assert oracle("1\n3\n2 1 2\n") == "0\nKILL BATMAN\n"
assert oracle("1\n2\n3000 3000\n") == str(3000 * 2999 % MODULUS) + "\nKILL BATMAN\n"
for maxima in ([1, 2, 2], [3, 1], [2, 4], [5, 5, 5]):
    text = "1\n" + str(len(maxima)) + "\n" + " ".join(map(str, maxima)) + "\n"
    assert int(oracle(text).splitlines()[0]) == brute(maxima)


def write(name, cases):
    chunks = [str(len(cases))]
    for maxima in cases:
        chunks.append(str(len(maxima)))
        chunks.append(" ".join(str(value) for value in maxima))
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[1], [1, 1], [3000] * 66, [3000, 1], [1] * 66])
    write("3_wide", [[3000] * 66, [3000 - index for index in range(66)],
                     [66] * 66, [3000, 2999, 2998]])
    rng = random.Random(20261126)
    write("4_random", [[rng.randint(1, 3000) for _ in range(rng.randint(1, 66))]
                       for _ in range(120)])
    write("5_io", [[3000] * 66 for _ in range(666)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
