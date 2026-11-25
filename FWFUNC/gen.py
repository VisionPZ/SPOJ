#!/usr/bin/env python3
import itertools
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SMALL_PRIMES = []


def build_primes(limit):
    composite = [False] * (limit + 1)
    for value in range(2, limit + 1):
        if not composite[value]:
            SMALL_PRIMES.append(value)
            if value * value <= limit:
                for multiple in range(value * value, limit + 1, value):
                    composite[multiple] = True


build_primes(1000)


@lru_cache(maxsize=None)
def factorize(value):
    factors = []
    remaining = value
    for prime in SMALL_PRIMES:
        if remaining == 1:
            break
        if remaining % prime == 0:
            exponent = 0
            while remaining % prime == 0:
                remaining //= prime
                exponent += 1
            factors.append((prime, exponent))
    if remaining > 1:
        factors.append((remaining, 1))
    return tuple(factors)


def parse_cases(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    cases = []
    for _ in range(case_count):
        pair_count = int(tokens[cursor])
        cursor += 1
        pairs = []
        for _ in range(pair_count):
            pairs.append((int(tokens[cursor]), int(tokens[cursor + 1])))
            cursor += 2
        query_count = int(tokens[cursor])
        cursor += 1
        queries = [int(tokens[cursor + index]) for index in range(query_count)]
        cursor += query_count
        cases.append((pairs, queries))
    return cases


def brute_oracle(text):
    answers = []
    for pairs, queries in parse_cases(text):
        domain_primes = set()
        real_codomain = set()
        pair_factors = []
        for value, image in pairs:
            x_factors = factorize(value)
            y_factors = factorize(image)
            pair_factors.append((x_factors, y_factors, image))
            for prime, _ in x_factors:
                domain_primes.add(prime)
            for prime, _ in y_factors:
                real_codomain.add(prime)
        query_factors = []
        for value in queries:
            factors = factorize(value)
            query_factors.append(factors)
            for prime, _ in factors:
                domain_primes.add(prime)
        domain_primes = sorted(domain_primes)
        codomain_primes = sorted(real_codomain | {101})
        max_exponent = max([1] + [exponent for _, y_factors, _ in pair_factors
                                 for prime, exponent in y_factors])
        choices = [(None, 0)] + [(prime, exponent) for prime in domain_primes
                                for exponent in range(1, max_exponent + 1)]
        solutions = set()
        for assignment in itertools.product(choices, repeat=len(codomain_primes)):
            images = {prime: 1 for prime in domain_primes}
            for prime, (owner, exponent) in zip(codomain_primes, assignment):
                if owner is not None:
                    images[owner] *= prime ** exponent
            valid = True
            for x_factors, _, expected in pair_factors:
                computed = 1
                for prime, exponent in x_factors:
                    computed *= images[prime] ** exponent
                if computed != expected:
                    valid = False
                    break
            if not valid:
                continue
            query_values = []
            for factors in query_factors:
                computed = 1
                for prime, exponent in factors:
                    computed *= images[prime] ** exponent
                query_values.append(computed)
            solutions.add(tuple(query_values))
        if not solutions:
            answers.extend(["NO"] * len(queries))
            continue
        for query_index in range(len(queries)):
            values = {solution[query_index] for solution in solutions}
            if len(values) == 1:
                answers.append(f"YES {values.pop()}")
            else:
                answers.append("NO")
    return "\n".join(answers) + "\n"


SAMPLE = """3
3
2 2
3 2
7 19
1
7
1
6 6
1
6
2
2 2
3 3
1
12
"""
SAMPLE_OUT = """NO
YES 6
YES 12
"""
assert brute_oracle(SAMPLE) == SAMPLE_OUT
assert brute_oracle("1\n1\n2 2\n1\n3\n") == "NO\n"
assert brute_oracle("1\n2\n2 2\n3 3\n2\n6\n12\n") == "YES 6\nYES 12\n"
assert brute_oracle("1\n1\n2 4\n1\n8\n") == "YES 64\n"
LARGE = f"1\n1\n{pow(2, 166)} {pow(3, 166)}\n1\n{pow(2, 50)}\n"
assert brute_oracle(LARGE) == f"YES {pow(3, 50)}\n"


def render(cases):
    lines = [str(len(cases))]
    for pairs, queries in cases:
        lines.append(str(len(pairs)))
        for value, image in pairs:
            lines.append(f"{value} {image}")
        lines.append(str(len(queries)))
        for value in queries:
            lines.append(str(value))
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(brute_oracle(text))


def product_of(pairs):
    result = 1
    for prime, exponent in pairs:
        result *= prime ** exponent
    return result


def random_case(rng):
    domain = [2, 3, 5]
    codomain = [2, 3, 5, 7]
    images = {prime: 1 for prime in domain}
    for prime in codomain:
        if rng.random() < 0.7:
            owner = rng.choice(domain)
            images[owner] *= prime ** rng.randint(1, 2)
    pairs = []
    for _ in range(rng.randint(1, 3)):
        x_factors = [(prime, rng.randint(0, 2)) for prime in domain]
        value = product_of(x_factors)
        image = 1
        for base, exponent in factorize(value):
            image *= images[base] ** exponent
        pairs.append((value, image))
    queries = []
    for _ in range(3):
        primes = domain + [11]
        q_factors = [(prime, rng.randint(0, 2)) for prime in primes]
        queries.append(product_of(q_factors))
    return (pairs, queries)


def build():
    write("2_edges", [
        ([(1, 1)], [1]),
        ([(2, 1)], [2, 4]),
        ([(2, 2), (3, 2), (7, 19)], [7, 6]),
        ([(6, 6)], [6, 12, 18]),
    ])
    write("3_wide", [
        ([(2, 2), (3, 3), (5, 5), (7, 7)], [2, 3, 6, 12, 30, 210]),
        ([(4, 8), (9, 27)], [6, 12, 36]),
    ])
    rng = random.Random(20261126)
    write("4_random", [random_case(rng) for _ in range(8)])
    write("5_io", [random_case(rng) for _ in range(40)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
