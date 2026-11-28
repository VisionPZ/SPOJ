#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1 << 32


def set_bit_count(low, high, bit_position):
    period = 1 << (bit_position + 1)
    half = 1 << bit_position

    def up_to(exclusive):
        if exclusive <= 0:
            return 0
        whole, rest = divmod(exclusive, period)
        return whole * half + max(0, rest - half)

    return up_to(high + 1) - up_to(low)


def oracle_case(left, right):
    total = 0
    for bit_position in range(64):
        appearances = set_bit_count(left, right, bit_position)
        if appearances:
            total += (3 ** bit_position) * appearances
    return str(total % MODULUS)


def tree_number(index):
    return int(bin(index)[2:], 3)


def brute_case(left, right):
    return str(sum(tree_number(index) for index in range(left, right + 1)) % MODULUS)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        left = tokens[cursor]
        right = tokens[cursor + 1]
        cursor += 2
        answers.append(oracle_case(left, right))
    return "\n".join(answers) + "\n"


SAMPLE = "5\n1 3\n3 3\n4 5\n6 7\n2 5\n"
SAMPLE_OUT = "8\n4\n19\n25\n26\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(1, 1) == "1"
assert oracle_case(10**18, 10**18) == str(tree_number(10**18) % MODULUS)
assert oracle_case(4, 5) == "19"
assert oracle_case(1, 31) == brute_case(1, 31)
for start in range(1, 40):
    for stop in range(start, min(start + 12, 60)):
        assert oracle_case(start, stop) == brute_case(start, stop)


def write(name, pairs):
    text = str(len(pairs)) + "".join(f"\n{left} {right}" for left, right in pairs) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (1, 2), (10**18, 10**18), (10**18 - 1, 10**18)])
    write("3_wide", [(1, 10**18), (10**18 - 100000, 10**18), (10**18 - 1000, 10**18)])
    rng = random.Random(20261126)
    pairs = []
    for _ in range(100200):
        left = rng.randint(1, 10**18)
        right = min(10**18, left + rng.randint(0, 10**15))
        pairs.append((left, right))
    write("4_random", pairs[:200])
    write("5_io", pairs[200:])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 3), (3, 3), (4, 5), (6, 7), (2, 5)])
build()
