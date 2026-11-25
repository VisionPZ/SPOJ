#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def brute(n):
    result = 1
    for first in range(1, n + 1):
        for second in range(1, n + 1):
            if math.gcd(first, second) == 1:
                result = result * pow(first, second, MOD) % MOD
    return result


def oracle(text):
    limit = int(text.split()[0])
    if limit == 0:
        return "1\n"
    smallest_prime = list(range(limit + 1))
    for prime in range(2, int(limit ** 0.5) + 1):
        if smallest_prime[prime] == prime:
            for multiple in range(prime * prime, limit + 1, prime):
                if smallest_prime[multiple] == multiple:
                    smallest_prime[multiple] = prime
    result = 1
    for base in range(2, limit + 1):
        factors = []
        value = base
        while value > 1:
            prime = smallest_prime[value]
            factors.append(prime)
            while value % prime == 0:
                value //= prime
        exponent = 0
        for mask in range(1 << len(factors)):
            product = 1
            bits = 0
            for index, prime in enumerate(factors):
                if mask >> index & 1:
                    product *= prime
                    bits += 1
            quotient = limit // product
            triangular = product * quotient * (quotient + 1) // 2
            exponent += triangular if bits % 2 == 0 else -triangular
        result = result * pow(base, exponent, MOD) % MOD
    return str(result) + "\n"


SAMPLE = "1\n"
SAMPLE_OUT = "1\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(1) == 1
assert brute(2) == 2
assert brute(3) == 432
assert brute(25) == 570657233
assert oracle("25\n") == str(brute(25)) + "\n"
assert oracle("60\n") == str(brute(60)) + "\n"


def write(name, limit):
    text = f"{limit}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 2)
    write("3_wide", 60)
    rng = random.Random(20261126)
    write("4_random", rng.randint(1, 200))
    write("5_io", 100000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
