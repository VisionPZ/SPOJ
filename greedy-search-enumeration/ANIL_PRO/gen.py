#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007
FIB = [0, 1]
for index in range(2, 1000005):
    FIB.append((FIB[-1] + FIB[-2]) % MOD)


def oracle(text):
    tokens = text.split()
    cursor = 0
    array_size = int(tokens[cursor]); cursor += 1
    operation_count = int(tokens[cursor]); cursor += 1
    values = [0] * (array_size + 1)
    answers = []
    for _ in range(operation_count):
        kind = int(tokens[cursor]); cursor += 1
        left = int(tokens[cursor]); cursor += 1
        right = int(tokens[cursor]); cursor += 1
        if kind == 0:
            for position in range(left, right + 1):
                values[position] = (values[position] +
                                    FIB[position - left + 1]) % MOD
        else:
            answers.append(str(sum(values[left:right + 1]) % MOD))
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """5 6
0 1 5
0 2 4
0 1 3
1 2 4
1 1 5
1 4 5
"""
SAMPLE_OUT = """13
20
10
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 3\n0 1 1\n1 1 1\n0 1 1\n") == "1\n"
assert oracle("2 4\n0 1 2\n1 1 1\n1 2 2\n1 1 2\n") == "1\n1\n2\n"
assert oracle("3 3\n1 1 3\n0 2 3\n1 1 3\n") == "0\n2\n"
assert oracle("5 6\n0 1 5\n1 1 5\n0 3 3\n1 3 3\n1 1 2\n1 4 5\n") == "12\n3\n2\n8\n"


def write(name, array_size, operations):
    input_text = f"{array_size} {len(operations)}\n" + "".join(
        f"{kind} {left} {right}\n" for kind, left, right in operations)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def random_operations(rng, array_size, count):
    result = []
    for _ in range(count):
        left = rng.randint(1, array_size)
        right = rng.randint(left, array_size)
        result.append((rng.randint(0, 1), left, right))
    return result


def build():
    write("2_edges", 1, [(0, 1, 1), (1, 1, 1), (0, 1, 1),
                         (1, 1, 1), (1, 1, 1)])
    rng = random.Random(20261126)
    write("3_wide", 1000, random_operations(rng, 1000, 400))
    write("4_random", 500, random_operations(rng, 500, 600))
    write("5_io", 100, random_operations(rng, 100, 50000))
    big_ops = random_operations(rng, 1000000, 50000)
    Path("/tmp/ANIL_PRO_big.txt").write_text(
        f"1000000 {len(big_ops)}\n" + "".join(
            f"{kind} {left} {right}\n" for kind, left, right in big_ops))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 5, [(0, 1, 5), (0, 2, 4), (0, 1, 3),
                      (1, 2, 4), (1, 1, 5), (1, 4, 5)])
build()
