#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def is_prime(value):
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def factor_counts(value):
    factors = {}
    divisor = 2
    remaining = value
    while divisor * divisor <= remaining:
        while remaining % divisor == 0:
            factors[divisor] = factors.get(divisor, 0) + 1
            remaining //= divisor
        divisor += 1
    if remaining > 1:
        factors[remaining] = factors.get(remaining, 0) + 1
    return factors


def longest_run(flags):
    best = 0
    current = 0
    for flag in flags:
        current = current + 1 if flag else 0
        best = max(best, current)
    return best


def oracle(text):
    tokens = [int(token) for token in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for case_number in range(1, case_count + 1):
        card_count = tokens[cursor]
        cursor += 1
        cards = tokens[cursor:cursor + card_count]
        cursor += card_count
        prime_flags = [is_prime(card) for card in cards]
        balance = {}
        for card, prime_flag in zip(cards, prime_flags):
            if prime_flag:
                balance[card] = balance.get(card, 0) + 1
            else:
                for factor, multiplicity in factor_counts(card).items():
                    balance[factor] = balance.get(factor, 0) - multiplicity
        valid_flags = [prime_flags[index] and balance.get(card, 0) > 0
                       for index, card in enumerate(cards)]
        plain = longest_run(prime_flags)
        adapted = longest_run(valid_flags)
        answers.append(f"Scenario #{case_number}: {plain} > {adapted}")
    return "\n".join(answers) + "\n"


SAMPLE = """3
7
7 9 11 2 5 7 6
3
2 3 4
5
8 16 32 64 7
"""
SAMPLE_OUT = """Scenario #1: 4 > 2
Scenario #2: 2 > 1
Scenario #3: 1 > 1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n2\n") == "Scenario #1: 1 > 1\n"
assert oracle("1\n1\n4\n") == "Scenario #1: 0 > 0\n"
assert longest_run([True, True, False, True]) == 2
assert factor_counts(8) == {2: 3}
assert is_prime(9999991)


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        str(len(cards)) + "\n" + " ".join(str(card) for card in cards) + "\n"
        for cards in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[2], [4], [10000000], [2, 4, 3], [8, 16, 32]])
    rng = random.Random(20261126)
    write("3_wide", [[rng.randint(2, 10000000) for _ in range(1000)]
                     for _ in range(5)])
    write("4_random", [[rng.randint(2, 100000) for _ in range(300)]
                       for _ in range(5)])
    write("5_io", [[rng.randint(2, 1000) for _ in range(50)]
                   for _ in range(100)])
    big_rng = random.Random(31415)
    with open("/tmp/VPL1_AA_big.txt", "w") as handle:
        handle.write("5\n")
        for _ in range(5):
            handle.write("100000\n")
            handle.write(" ".join(str(big_rng.randint(2, 10000000))
                                  for _ in range(100000)) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[7, 9, 11, 2, 5, 7, 6], [2, 3, 4], [8, 16, 32, 64, 7]])
build()
