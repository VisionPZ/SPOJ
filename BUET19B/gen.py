#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "5\n2 4 6 8 2\n"
SAMPLE_OUT = "2\n"

LIMIT_VALUE = 100000


def smallest_prime_factor(upper):
    spf = list(range(upper + 1))
    for candidate in range(2, int(upper ** 0.5) + 1):
        if spf[candidate] == candidate:
            for multiple in range(candidate * candidate, upper + 1, candidate):
                if spf[multiple] == multiple:
                    spf[multiple] = candidate
    return spf


def factorize(value, spf):
    result = {}
    while value > 1:
        prime = spf[value]
        exponent = 0
        while value % prime == 0:
            value //= prime
            exponent += 1
        result[prime] = exponent
    return result


def oracle(input_text):
    tokens = input_text.split()
    count = int(tokens[0])
    numbers = [int(token) for token in tokens[1:1 + count]]
    if not numbers:
        return "0\n"
    spf = smallest_prime_factor(max(numbers))
    common = factorize(numbers[0], spf)
    for value in numbers[1:]:
        parts = factorize(value, spf)
        for prime, exponent in common.items():
            if parts.get(prime, 0) < exponent:
                common[prime] = parts.get(prime, 0)
    answer = 1
    for prime, exponent in common.items():
        answer *= prime ** exponent
    return str(answer) + "\n"


def write(name, numbers):
    input_text = "%d\n%s\n" % (len(numbers), " ".join(str(v) for v in numbers))
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    numbers = [2, 4, 6, 8, 2]
    print("numbers 2 4 6 8 2")
    print("shared prime factors 2^1")
    print("answer 2")


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n97\n") == "97\n"
assert oracle("3\n12 18 30\n") == "6\n"
assert oracle("4\n7 11 13 17\n") == "1\n"
assert oracle("3\n100000 100000 100000\n") == "100000\n"


def build():
    write("2_edges", [1, 100000, 99991, 2, 4, 8, 99991])
    write("3_wide", [100000] * 100000)
    rng = random.Random(1901)
    random_cases = [rng.randint(1, 100000) for _ in range(100000)]
    write("4_random", random_cases)
    io_cases = [rng.randint(10000, 99999) for _ in range(100000)]
    write("5_io", io_cases)
    write("6_single", [99991])
    write("7_coprime", [99989, 99991])
    write("8_shared", [30030, 60060, 90090, 30030])


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
