#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007


def oracle(text):
    tokens = text.split()
    case_total = int(tokens[0])
    answers = []
    for case_index in range(case_total):
        upper = int(tokens[case_index + 1])
        state = {(1, 1, 0, 0): 1}
        for bit in range(59, -1, -1):
            bound_bit = (upper >> bit) & 1
            following = {}
            for (tight_x, tight_y, lower, seen_one), ways in state.items():
                for x_bit in (0, 1):
                    if tight_x and x_bit > bound_bit:
                        continue
                    for y_bit in (0, 1):
                        if tight_y and y_bit > bound_bit:
                            continue
                        if not lower and x_bit > y_bit:
                            continue
                        xor_bit = x_bit ^ y_bit
                        if xor_bit and seen_one:
                            continue
                        next_state = (tight_x and x_bit == bound_bit,
                                      tight_y and y_bit == bound_bit,
                                      lower or x_bit < y_bit,
                                      seen_one or bool(xor_bit))
                        following[next_state] = (following.get(next_state, 0) + ways) % MODULUS
            state = following
        answer = sum(ways for (_, _, lower, seen_one), ways in state.items()
                     if lower and seen_one) % MODULUS
        answers.append(str(answer))
    return "\n".join(answers) + "\n"


def brute(upper):
    answer = 0
    for first in range(upper + 1):
        for second in range(first + 1, upper + 1):
            value = first ^ second
            if value > 0 and value & (value - 1) == 0:
                answer += 1
    return answer % MODULUS


SAMPLE = """3
1
2
3
"""
SAMPLE_OUT = """1
2
4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0\n") == "0\n"
assert oracle("1\n10\n") == f"{brute(10)}\n"
assert oracle("1\n1000000000000000\n") == "227182119\n"


def write(name, bounds):
    text = str(len(bounds)) + "\n" + "\n".join(str(value) for value in bounds) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, 2, 3, 4, 7])
    write("3_wide", [10**15, 10**15 - 1, 2**50 - 1, 2**49, 999999999999999])
    rng = random.Random(20261128)
    write("4_random", [rng.randint(0, 10**15) for _ in range(30)])
    write("5_io", [rng.randint(0, 10**15) for _ in range(100)])
    big = random.Random(9283747)
    huge = [big.randint(0, 10**15) for _ in range(100)]
    Path("/tmp/LOVINGPW_big.txt").write_text(
        str(len(huge)) + "\n" + "\n".join(str(value) for value in huge) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 3])
build()
