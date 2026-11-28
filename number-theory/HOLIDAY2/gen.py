#!/usr/bin/env python3
import itertools
import math
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
small_primes = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37)
witnesses = (2, 325, 9375, 28178, 450775, 9780504, 1795265022)


def is_prime(value):
    if value < 2:
        return False
    for prime in small_primes:
        if value % prime == 0:
            return value == prime
    odd = value - 1
    power = 0
    while odd % 2 == 0:
        odd //= 2
        power += 1
    for base in witnesses:
        x = pow(base % value, odd, value)
        if x in (1, value - 1):
            continue
        for _ in range(power - 1):
            x = x * x % value
            if x == value - 1:
                break
        else:
            return False
    return True


def rho_factor(value):
    if value % 2 == 0:
        return 2
    if value % 3 == 0:
        return 3
    while True:
        shift = random.randrange(1, value)
        walk = random.randrange(value)
        chase = walk
        divisor = 1
        while divisor == 1:
            walk = (walk * walk + shift) % value
            chase = (chase * chase + shift) % value
            chase = (chase * chase + shift) % value
            divisor = math.gcd(abs(walk - chase), value)
        if divisor != value:
            return divisor


def factorize(value, result):
    if value == 1:
        return
    if is_prime(value):
        result[value] = result.get(value, 0) + 1
        return
    divisor = rho_factor(value)
    factorize(divisor, result)
    factorize(value // divisor, result)


@lru_cache(maxsize=None)
def divisors(value):
    powers = {}
    factorize(value, powers)
    parts = [1]
    for prime, exponent in powers.items():
        parts = [part * prime ** step for part in parts
                 for step in range(exponent + 1)]
    return tuple(sorted(parts))


def solve_case(periods, remove_count):
    holiday_count = len(periods)
    keep_count = holiday_count - remove_count
    multiples = {}
    for period in periods:
        for div in divisors(period):
            multiples[div] = multiples.get(div, 0) + 1
    best = max(div for div, count in multiples.items()
               if count >= keep_count)
    removed = []
    kept = 0
    for index, period in enumerate(periods, 1):
        if period % best == 0 and kept < keep_count:
            kept += 1
        else:
            removed.append(index)
    assert len(removed) == remove_count
    return best, removed


def brute_best(periods, remove_count):
    keep_count = len(periods) - remove_count
    answer = 0
    for subset in itertools.combinations(periods, keep_count):
        common = math.gcd(*subset)
        answer = max(answer, common)
    return answer


def worked_example():
    periods = [1, 3, 4, 5, 6, 1]
    remove_count = 4
    keep_count = len(periods) - remove_count
    lines = [f"keep {keep_count} of {len(periods)} periods {periods}"]
    all_divisors = set()
    for period in periods:
        all_divisors.update(divisors(period))
    for rhythm in sorted(all_divisors, reverse=True):
        count = sum(1 for period in periods if period % rhythm == 0)
        if count >= keep_count:
            lines.append(f"rhythm {rhythm} divides {count} periods")
    best, removed = solve_case(periods, remove_count)
    lines.append(f"best rhythm {best}")
    lines.append(f"removed holidays {' '.join(map(str, removed))}")
    return "\n".join(lines)


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        holiday_count = int(tokens[cursor])
        remove_count = int(tokens[cursor + 1])
        cursor += 2
        periods = [int(tokens[cursor + offset])
                   for offset in range(holiday_count)]
        cursor += holiday_count
        _, removed = solve_case(periods, remove_count)
        answers.append(" ".join(str(index) for index in removed))
    return "\n".join(answers) + "\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        str(len(periods)) + " " + str(remove_count) + "\n"
        + " ".join(str(period) for period in periods) + "\n"
        for periods, remove_count in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


random.seed(2026)
assert is_prime(999999937)
assert divisors(999999937) == (1, 999999937)
assert solve_case([1, 3, 4, 5, 6, 1], 4) == (3, [1, 3, 4, 6])
assert solve_case([200, 125, 200, 999, 380, 500, 200, 500], 4)[0] == 100
assert solve_case([30, 42, 70, 1], 1) == (2, [4])
for trial in range(200):
    count = random.randint(2, 8)
    values = [random.randint(1, 60) for _ in range(count)]
    removed_count = random.randint(1, count - 1)
    expected = brute_best(values, removed_count)
    got = solve_case(values, removed_count)[0]
    assert got == expected, (values, removed_count, got, expected)

pool = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 18, 20, 30, 42, 60, 70,
        100, 125, 200, 380, 500, 999, 1024, 3125, 10000, 999999937,
        1000000007, 998244353, 1000000009, 999999937 * 999999929,
        999999999999999989, 2 ** 59, 3 ** 37, 2 ** 30 * 3 ** 12]
assert all(1 <= value <= 10 ** 18 for value in pool)

sample = [([1, 3, 4, 5, 6, 1], 4),
          ([200, 125, 200, 999, 380, 500, 200, 500], 4)]
write("1_sample", sample)

edges = [([2, 3], 1),
         ([30, 42, 70, 1], 1),
         ([7, 7, 7, 7, 7], 1),
         ([1, 1, 1, 1, 1], 4),
         ([999999937, 999999937 * 2, 3], 2),
         ([999999999999999989, 1], 1),
         ([10 ** 18, 10 ** 18 - 1, 10 ** 18], 1),
         ([1] * 100, 99)]
write("2_edges", edges)

wide = [([pool[(index * 7 + offset) % len(pool)] for offset in range(100)], 1)
        for index in range(4)]
wide += [([pool[(index * 11 + offset * 3) % len(pool)]
           for offset in range(100)], 99) for index in range(4)]
wide += [([pool[(index * 5 + offset * 13) % len(pool)]
           for offset in range(100)], 50) for index in range(2)]
write("3_wide", wide)

random_cases = []
for _ in range(100):
    count = random.randint(2, 100)
    removed_count = random.randint(1, count - 1)
    values = [random.choice(pool) for _ in range(count)]
    random_cases.append((values, removed_count))
write("4_random", random_cases)

io_cases = []
for index in range(100):
    values = [pool[(index + offset * 17) % len(pool)]
              for offset in range(100)]
    io_cases.append((values, 99))
write("5_io", io_cases)
print(worked_example())
