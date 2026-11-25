#!/usr/bin/env python3
import random
from itertools import product
from math import gcd
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 100000007
INVERSES = [pow(value, MODULUS - 2, MODULUS) for value in range(1010)]


def composition_count(pattern_length, run_limit):
    if run_limit >= pattern_length:
        return pow(2, pattern_length, MODULUS)
    previous = [0] * (pattern_length + 1)
    previous[0] = 1
    total = 0
    for group_count in range(1, pattern_length + 1):
        current = [0] * (pattern_length + 1)
        window = 0
        for used in range(pattern_length + 1):
            window += previous[used]
            if used - run_limit - 1 >= 0:
                window -= previous[used - run_limit - 1]
            current[used] = window % MODULUS
        remainder = pattern_length - group_count
        if remainder >= 0:
            total = (total + pattern_length * INVERSES[group_count] * current[remainder]) % MODULUS
        previous = current
    if pattern_length <= run_limit:
        total = (total + 1) % MODULUS
    return total % MODULUS


def phi(value):
    result = value
    candidate = 2
    while candidate * candidate <= value:
        if value % candidate == 0:
            while value % candidate == 0:
                value //= candidate
            result = result // candidate * (candidate - 1)
        candidate += 1
    if value > 1:
        result = result // value * (value - 1)
    return result


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    cache = {}
    for _ in range(case_count):
        people = tokens[cursor]
        run_limit = tokens[cursor + 1]
        cursor += 2
        rotation_total = 0
        for common in range(1, people + 1):
            if people % common != 0:
                continue
            cache_key = (common, run_limit)
            if cache_key not in cache:
                cache[cache_key] = composition_count(common, run_limit)
            fixed = cache[cache_key]
            if common <= run_limit and people > run_limit:
                fixed = (fixed - 1) % MODULUS
            rotation_total = (rotation_total + phi(people // common) * fixed) % MODULUS
        answers.append(str(rotation_total * INVERSES[people] % MODULUS))
    return "\n".join(answers) + "\n"


def brute_necklaces(people, run_limit):
    seen = set()
    for bits in product([0, 1], repeat=people):
        if 0 not in bits and people > run_limit:
            continue
        longest = 0
        current = 0
        for bit in bits:
            current = current + 1 if bit else 0
            longest = max(longest, current)
        prefix = 0
        for bit in bits:
            if not bit:
                break
            prefix += 1
        suffix = 0
        for bit in reversed(bits):
            if not bit:
                break
            suffix += 1
        if 0 in bits:
            longest = max(longest, prefix + suffix)
        else:
            longest = people
        if longest > run_limit:
            continue
        rotations = [bits[offset:] + bits[:offset] for offset in range(people)]
        seen.add(min(rotations))
    return len(seen)


SAMPLE = """3

3 1

3 3

4 1
"""
SAMPLE_OUT = """2
4
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 0\n") == "1\n"
assert oracle("1\n7 2\n") == "11\n"
assert composition_count(4, 1) == 7
assert composition_count(3, 3) == 8
for small_people in range(1, 9):
    for small_limit in range(0, small_people + 2):
        actual = oracle(f"1\n{small_people} {small_limit}\n")
        assert int(actual) == brute_necklaces(small_people, small_limit), (small_people, small_limit)


def write(name, cases):
    text = str(len(cases)) + "\n" + "\n\n".join(f"{people} {limit}" for people, limit in cases) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 0), (1, 3), (2, 0), (2, 1), (3, 0), (3, 1), (3, 2)])
    rng = random.Random(20261130)
    wide_cases = []
    for _ in range(8):
        people = rng.randint(200, 999)
        wide_cases.append((people, rng.randint(0, people)))
    write("3_wide", wide_cases)
    write("4_random", [(rng.randint(1, 60), rng.randint(0, 60)) for _ in range(20)])
    write("5_io", [(rng.randint(1, 6), rng.randint(0, 6)) for _ in range(950)])
    big_cases = [(999, rng.randint(0, 999)) for _ in range(950)]
    Path("/tmp/LARGE_big.txt").write_text(
        str(len(big_cases)) + "\n" + "\n\n".join(f"{people} {limit}" for people, limit in big_cases) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
