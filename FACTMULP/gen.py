#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007
INV2 = (MOD + 1) // 2
BASE_LIST = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]
PRIME_POOL = [3, 11, 17, 23, 89, 191, 787, 809, 2617, 4889, 6823, 12097, 12289, 14051,
              462901, 753569, 779827, 3492337, 8777047, 9124301, 22252369, 25356257,
              34574011, 115696799, 622645487, 640181999, 2073003437, 9213331003,
              9884437267, 197388928631, 396550163003, 737867261099, 641596674948503,
              726488945323357, 825789614398447, 387252834149619859, 509562853727881853,
              622720795210108873]


def is_prime(number):
    if number < 2:
        return False
    for small in (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37):
        if number == small:
            return True
        if number % small == 0:
            return False
    odd_part = number - 1
    shift = 0
    while odd_part % 2 == 0:
        odd_part //= 2
        shift += 1
    for base in BASE_LIST:
        value = pow(base, odd_part, number)
        if value == 1 or value == number - 1:
            continue
        for _ in range(shift - 1):
            value = value * value % number
            if value == number - 1:
                break
        else:
            return False
    return True


def find_prime(start, rng=None):
    candidate = start if start % 2 else start + 1
    while not is_prime(candidate):
        candidate += 2
    return candidate


def brute(prime, exponent):
    limit = prime ** exponent
    total = 0
    for number in range(1, limit + 1):
        residue = number
        while residue:
            residue //= prime
            total += residue
    return total % MOD


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    results = []
    for case in range(count):
        prime = tokens[1 + 2 * case]
        exponent = tokens[2 + 2 * case]
        residue = prime % MOD
        power = 1
        series = 0
        for bit in bin(exponent)[2:]:
            series = series * (1 + power) % MOD
            power = power * power % MOD
            if bit == "1":
                series = (series + power) % MOD
                power = power * residue % MOD
        shift = (series - exponent) % MOD
        answer = (power * shift % MOD * INV2 + series) % MOD
        results.append(str(answer))
    return "\n".join(results) + "\n"


SAMPLE = """1
2 2
"""
SAMPLE_OUT = """5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(2, 2) == 5
assert brute(3, 2) == 13
assert oracle("1\n2 1\n") == "1\n"
assert oracle("1\n3 6\n") == str(brute(3, 6)) + "\n"
for small_prime in (2, 3, 5, 7):
    for small_exponent in (1, 2, 3, 4):
        assert oracle(f"1\n{small_prime} {small_exponent}\n") == str(brute(small_prime, small_exponent)) + "\n"
assert find_prime(1000000007) == 1000000007
assert is_prime(999999999999999989)


def write(name, cases):
    text = str(len(cases)) + "\n"
    for prime, exponent in cases:
        text += f"{prime} {exponent}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    tricky_prime = find_prime(2 * MOD + 1)
    edges = [(2, 1), (MOD, 1000000000000000000), (tricky_prime, 999999999999999999),
             (999999999999999989, 1), (3, 2), (2, 999999999999999999)]
    write("2_edges", edges)
    write("3_wide", [(999999999999999023, 10**18 - 7), (737867261099, 10**18 - 7),
                     (1000000007, 10**18 - 7), (2000000033, 10**18 - 7)])
    rng = random.Random(20261126)
    cases = []
    for _ in range(999):
        prime = rng.choice(PRIME_POOL)
        exponent = rng.randint(1, 10**18)
        cases.append((prime, exponent))
    write("4_random", cases)
    write("5_io", [(2, 10**18 - 1)] * 2000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
