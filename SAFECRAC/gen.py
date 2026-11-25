#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007
NEIGHBORS = {
    0: [7],
    1: [2, 4],
    2: [1, 3, 5],
    3: [2, 6],
    4: [1, 5, 7],
    5: [2, 4, 6, 8],
    6: [3, 5, 9],
    7: [4, 8, 0],
    8: [5, 7, 9],
    9: [6, 8],
}
ADJACENCY = [[0] * 10 for _ in range(10)]
for source in range(10):
    for target in NEIGHBORS[source]:
        ADJACENCY[source][target] = 1
MEMO = {}


def multiply(left, right):
    result = [[0] * 10 for _ in range(10)]
    for row in range(10):
        for middle in range(10):
            factor = left[row][middle]
            if factor:
                for column in range(10):
                    result[row][column] = (result[row][column] + factor * right[middle][column]) % MOD
    return result


def power_of(matrix, exponent):
    result = [[1 if row == column else 0 for column in range(10)] for row in range(10)]
    base = matrix
    while exponent:
        if exponent & 1:
            result = multiply(result, base)
        base = multiply(base, base)
        exponent >>= 1
    return result


def oracle_case(length):
    if length in MEMO:
        return MEMO[length]
    if length == 1:
        answer = 10
    else:
        powered = power_of(ADJACENCY, length - 1)
        answer = sum(powered[row][column] for row in range(10) for column in range(10)) % MOD
    MEMO[length] = answer
    return answer


def brute_case(length):
    total = 0

    def walk(digit, steps):
        nonlocal total
        if steps == length:
            total += 1
            return
        for neighbor in NEIGHBORS[digit]:
            walk(neighbor, steps + 1)

    for start in range(10):
        walk(start, 1)
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    test_count = tokens[0]
    lengths = tokens[1:1 + test_count]
    return "\n".join(str(oracle_case(length)) for length in lengths) + "\n"


SAMPLE = "2\n3\n25\n"
SAMPLE_OUT = "74\n478325846\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "10\n"
assert oracle("1\n2\n") == "26\n"
assert oracle("3\n1 2 3\n") == "10\n26\n74\n"
for length in range(1, 6):
    assert oracle_case(length) == brute_case(length)


def write(name, lengths):
    input_text = str(len(lengths)) + "\n" + "\n".join(str(length) for length in lengths) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 100000])
    write("3_wide", [100000, 99999, 100000, 1, 2])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 100000) for _ in range(500)])
    pool = [1, 2, 3, 4, 5, 10, 100, 1000, 9999, 50000, 99999, 100000]
    write("5_io", [rng.choice(pool) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3, 25])
build()
