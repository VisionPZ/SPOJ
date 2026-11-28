#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007

SAMPLE_INPUT = """2
3
0
"""
SAMPLE_OUT = """2
12
"""


def brute_ways(n):
    total = 0
    for size in range(2, n + 1):
        total += math.comb(n, size) * size * (size - 1)
    return total % MOD


def oracle(input_text):
    answers = []
    for token in input_text.split():
        n = int(token)
        if n == 0:
            break
        answers.append(str(n * (n - 1) * pow(2, n - 2, MOD) % MOD))
    return "\n".join(answers) + "\n"


def write(name, numbers):
    input_text = "".join("%s\n" % number for number in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    for n in [2, 3, 4]:
        print(n, brute_ways(n))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("4\n0\n") == "%d\n" % brute_ways(4)
assert oracle("5\n6\n0\n") == "%d\n%d\n" % (brute_ways(5), brute_ways(6))
assert oracle("10\n0\n") == "%d\n" % brute_ways(10)


def build():
    huge = 10 ** 30
    write("2_edges", ["2", "3", "4", "5", "10",
                      str(huge - 1), str(huge), "0"])
    write("3_wide", [str(huge)] * 50 + [str(huge - 1), "999999999999", "2", "0"])
    rng = random.Random(770113)
    write("4_random", [str(rng.randint(2, huge)) for _ in range(200)] + ["0"])
    write("5_io", [str(rng.randint(2, huge)) for _ in range(20000)] + ["0"])


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", ["2", "3", "0"])
        build()
