#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """8
19523
233332
859
11
819918000
10100
5252
23432
"""
SAMPLE_OUT = """NO
YES
NO
YES
YES
YES
NO
YES
"""


def oracle(input_text):
    tokens = input_text.split()
    count = int(tokens[0])
    answers = []
    for index in range(1, count + 1):
        digits = tokens[index].rstrip("0")
        if digits == digits[::-1]:
            answers.append("YES")
        else:
            answers.append("NO")
    return "\n".join(answers) + "\n"


def write(name, numbers):
    input_text = str(len(numbers)) + "\n"
    input_text += "".join("%d\n" % number for number in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    for number in [819918000, 10100, 5252]:
        digits = str(number).rstrip("0")
        print(number, digits, digits == digits[::-1])


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n0\n") == "YES\n"
assert oracle("2\n7\n707\n") == "YES\nYES\n"
assert oracle("1\n1230\n") == "NO\n"


def build():
    write("2_edges", [0, 1, 9, 10, 11, 100, 101, 1000, 1001,
                      10100, 5252, 999999999])
    write("3_wide", [999999999, 999999990, 100000000, 123400000,
                     987654321, 100000001])
    rng = random.Random(601417)
    write("4_random", [rng.randint(0, 10 ** 9 - 1) for _ in range(1000)])
    write("5_io", [rng.randint(0, 10 ** 9 - 1) for _ in range(20000)])


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", [19523, 233332, 859, 11, 819918000,
                           10100, 5252, 23432])
        build()
