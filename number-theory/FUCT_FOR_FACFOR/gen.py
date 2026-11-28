#!/usr/bin/env python3
import random
from math import factorial
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_IN = """5
0
5
9
-3
1
"""
SAMPLE_OUT = """0!=1
5!=1*2*3*4*5=120
9!=1*2*3*4*5*6*7*8*9=362880
accept positive integer only!
1!=1
"""


def fmt(n):
    if n < 0:
        return "accept positive integer only!"
    if n <= 1:
        return "%d!=1" % n
    terms = "*".join(str(k) for k in range(1, n + 1))
    return "%d!=%s=%d" % (n, terms, factorial(n))


def oracle(input_text):
    tokens = input_text.split()
    count = int(tokens[0])
    return "\n".join(fmt(int(x)) for x in tokens[1:1 + count]) + "\n"


assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert fmt(2) == "2!=1*2=2"
assert fmt(3) == "3!=1*2*3=6"
assert fmt(20) == "20!=1*2*3*4*5*6*7*8*9*10*11*12*13*14*15*16*17*18*19*20=2432902008176640000"
assert fmt(25) == ("25!=" + "*".join(map(str, range(1, 26))) +
                  "=15511210043330985984000000")


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join("%d\n" % c for c in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        print("n = 5")
        print("terms:", "*".join(str(k) for k in range(1, 6)))
        print("value:", factorial(5))
        print("line:", fmt(5))
        raise SystemExit
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [0, 5, 9, -3, 1])
    write("2_edges", [0, 1, 2, 20, 21, -1, -100000, 100])
    write("3_wide", [100] * 1000)
    rng = random.Random(77)
    write("4_random", [rng.randint(-50, 150) for _ in range(1000)])
    write("5_io", [1000] * 1000)
