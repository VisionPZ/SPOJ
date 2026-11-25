#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_X = 10000


def primes_up_to(limit):
    sieve = [True] * (limit + 1)
    sieve[0] = sieve[1] = False
    for candidate in range(2, int(limit ** 0.5) + 1):
        if sieve[candidate]:
            for multiple in range(candidate * candidate, limit + 1, candidate):
                sieve[multiple] = False
    return [value for value, flag in enumerate(sieve) if flag]


PRIMES = primes_up_to(MAX_X)


def divisor_counts():
    table = {}
    for factorial_index in range(1, MAX_X + 1):
        total = 1
        for prime in PRIMES:
            if prime > factorial_index:
                break
            exponent = 0
            power = prime
            while power <= factorial_index:
                exponent += factorial_index // power
                power *= prime
            total *= exponent + 1
        if total not in table:
            table[total] = factorial_index
    return table


TABLE = divisor_counts()


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = []
    for token in tokens[1:case_count + 1]:
        value = int(token)
        answers.append(str(TABLE.get(value, "nai")) + "\n")
    return "".join(answers)


def brute_divisors(value):
    count = 0
    divisor = 1
    while divisor * divisor <= value:
        if value % divisor == 0:
            count += 1
            if divisor * divisor != value:
                count += 1
        divisor += 1
    return count


def input_text(values):
    return str(len(values)) + "\n" + "\n".join(str(value) for value in values) + "\n"


SAMPLE = [1, 2, 3, 4, 5]
SAMPLE_OUT = "1\n2\nnai\n3\nnai\n"
assert oracle(input_text(SAMPLE)) == SAMPLE_OUT
assert oracle("1\n0\n") == "nai\n"
assert oracle("1\n6\n") == "nai\n"
assert oracle("1\n24\n") == "nai\n"
assert oracle("1\n8\n") == "4\n"
assert oracle("1\n1000000000000000000\n") == "nai\n"
assert TABLE[1] == 1 and TABLE[2] == 2 and TABLE[4] == 3 and TABLE[8] == 4

factorial = 1
for index in range(1, 13):
    factorial *= index
    assert TABLE[brute_divisors(factorial)] == index


def build():
    known = sorted(TABLE)
    edges = [0, 1, 2, 3, 4, 6, 24, 10**18, known[-1]]
    write("2_edges", edges)
    wide = known[:] + [10**18, 10**18 - 1, 0]
    rng = random.Random(20261126)
    rng.shuffle(wide)
    write("3_wide", wide)
    random_values = []
    for _ in range(2000):
        if rng.random() < 0.5:
            random_values.append(rng.choice(known))
        else:
            random_values.append(rng.randint(0, 10**18))
    write("4_random", random_values)
    io_values = [rng.randint(0, 20) for _ in range(100000)]
    write("5_io", io_values)


def write(name, values):
    text = input_text(values)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
