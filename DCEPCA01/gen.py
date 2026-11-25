#!/usr/bin/env python3
import random
from itertools import product
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def harmonic_sum(digits):
    prefix = [0]
    for digit in digits:
        prefix.append(prefix[-1] + (1 if digit == '4' else 0))
    length = len(digits)
    return sum(abs(prefix[index + 1] - prefix[index + 2] - prefix[index + 3] + prefix[index + 4])
               for index in range(length - 3))


def oracle_case(length):
    candidates = []
    for first_digit, odd_digit, even_digit in product('47', repeat=3):
        digits = [first_digit, odd_digit, even_digit]
        for position in range(3, length):
            if position % 2:
                added = '7' if odd_digit == '4' else '4'
                digits.append(added)
                odd_digit = added
            else:
                added = '7' if even_digit == '4' else '4'
                digits.append(added)
                even_digit = added
        if len(digits) != length:
            continue
        candidates.append((''.join(digits), harmonic_sum(digits)))
    best = max(score for _, score in candidates)
    winners = sorted(text for text, score in candidates if score == best)
    return str(int(winners[0]) + int(winners[1]))


def oracle(text):
    tokens = [int(token) for token in text.split()]
    case_count = tokens[0]
    answers = []
    position = 1
    for _ in range(case_count):
        answers.append(oracle_case(tokens[position]))
        position += 1
    return "\n".join(answers) + "\n"


SAMPLE = """1
4
"""
SAMPLE_OUT = """8924
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5\n") == "89251\n"
assert oracle("1\n6\n") == "892518\n"
assert oracle("1\n7\n") == "8925191\n"
assert oracle("2\n4\n5\n") == "8924\n89251\n"
for length in range(4, 9):
    all_numbers = [''.join(bits) for bits in product('47', repeat=length)]
    highest = max(harmonic_sum(number) for number in all_numbers)
    best_two = sorted(number for number in all_numbers if harmonic_sum(number) == highest)[:2]
    assert oracle_case(length) == str(int(best_two[0]) + int(best_two[1]))


def write(name, lengths):
    text = f"{len(lengths)}\n" + "\n".join(str(length) for length in lengths) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [4, 5, 6, 7, 8, 9, 10, 11])
    write("3_wide", [1000, 999, 998, 997])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(4, 300) for _ in range(12)])
    write("5_io", [1000] * 150)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [4])
build()
