#!/usr/bin/env python3
import ast
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "[3,4,2,7,3,6,12]\n"
SAMPLE_OUT = "9\n"


def oracle(input_text):
    numbers = ast.literal_eval(input_text.strip() or "[]")
    if len(numbers) >= 5:
        return str(numbers[4] * numbers[4]) + "\n"
    return "0\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    numbers = ast.literal_eval("[3,4,2,7,3,6,12]")
    print("list 3 4 2 7 3 6 12")
    print("fifth element 3")
    print("square 9")


assert oracle("[3,4,2,7,3,6,12]") == "9\n"
assert oracle("[]") == "0\n"
assert oracle("[1,2,3,4]") == "0\n"
assert oracle("[1,2,3,4,5]") == "25\n"
assert oracle("[1,2,3,4,-7]") == "49\n"
assert oracle("[10,20,30,40,50]") == "2500\n"


def build():
    write("2_edges", "[]\n")
    write("3_wide", "[" + ",".join(str(k) for k in range(100000)) + "]\n")
    rng = random.Random(3000)
    length = rng.randint(0, 2000)
    values = [rng.randint(-10**9, 10**9) for _ in range(length)]
    write("4_random", "[" + ",".join(str(v) for v in values) + "]\n")
    big_values = [rng.randint(-10**18, 10**18) for _ in range(300000)]
    write("5_io", "[" + ",".join(str(v) for v in big_values) + "]\n")
    write("6_short", "[1,2,3,4]\n")
    write("7_exact5", "[1,2,3,4,5]\n")
    write("8_negative", "[-9,-8,-7,-6,-5]\n")
    write("9_spaces", "[ 3 , 4 , 2 , 7 , 3 , 6 , 12 ]\n")


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
        (ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
        build()
