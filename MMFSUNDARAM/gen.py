#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "7\n"
SAMPLE_OUT = "2 3 5 7\n"


def is_prime(value):
    if value < 2:
        return False
    if value % 2 == 0:
        return value == 2
    divisor = 3
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 2
    return True


def oracle(input_text):
    limit = int(input_text.split()[0])
    primes = []
    for candidate in range(2, limit + 1):
        if is_prime(candidate):
            primes.append(str(candidate))
    return " ".join(primes) + "\n"


def write(name, value):
    input_text = str(value) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("2\n") == "2\n"
assert oracle("3\n") == "2 3\n"
assert len(oracle("100000\n").split()) == 9592


def trace_example():
    primes = oracle("15\n").strip()
    print("limit", 15)
    print("primes", primes)
    print("count", len(primes.split()))


def build():
    write("2_edges", 2)
    write("3_wide", 100000)
    rng = random.Random(20190623)
    write("4_random", rng.randint(2, 100000))
    write("5_io", 99999)


if __name__ == "__main__":
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", 7)
        build()
