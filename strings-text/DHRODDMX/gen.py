#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "3\n1 1\n1 3\n2 3\n"
SAMPLE_OUT = "1\n2\n1\n"
LIMIT = 10**18


def solve_case(left, right):
    span = right - left + 1
    return span // 2 + (1 if span % 2 and left % 2 else 0)


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(count):
        left = int(tokens[cursor])
        right = int(tokens[cursor + 1])
        cursor += 2
        answers.append(str(solve_case(left, right)))
    return "\n".join(answers) + "\n"


def brute(left, right):
    return sum(1 for value in range(left, right + 1) if value % 2)


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n1 1\n") == "1\n"
assert oracle("1\n1 1000000000000000000\n") == "500000000000000000\n"
assert oracle("2\n999999999999999998 999999999999999999\n1 2\n") == "1\n1\n"
for left in range(1, 16):
    for right in range(left, 16):
        assert solve_case(left, right) == brute(left, right)


def write(name, pairs):
    input_text = str(len(pairs)) + "\n" + "".join(
        f"{left} {right}\n" for left, right in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", [(1, 1), (1, 3), (2, 3)])
write("2_edges", [(1, 1), (1, 2), (2, 2), (LIMIT - 1, LIMIT),
                  (1, LIMIT), (LIMIT, LIMIT)])
write("3_wide", [(1, LIMIT), (LIMIT // 2, LIMIT),
                 (LIMIT - 101, LIMIT)] * 4)
random.seed(2026)


def random_pair():
    return tuple(sorted((random.randint(1, LIMIT),
                         random.randint(1, LIMIT))))


write("4_random", [random_pair() for _ in range(10)])
write("5_io", [random_pair() for _ in range(10)])

print("trace: [1,1] span 1, odd span, odd start -> " + SAMPLE_OUT.split("\n")[0])
