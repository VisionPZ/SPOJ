#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def parse(text):
    tokens = text.split()
    cursor = 0
    cases = []
    while cursor < len(tokens):
        target = int(tokens[cursor]); cursor += 1
        initial_count = int(tokens[cursor]); cursor += 1
        special_count = int(tokens[cursor]); cursor += 1
        initial = [0] + [int(tokens[cursor + index]) % MOD for index in range(initial_count)]
        cursor += initial_count
        order = int(tokens[cursor]); cursor += 1
        coefficients = [0] + [int(tokens[cursor + index]) % MOD for index in range(order)]
        cursor += order
        specials = []
        for _ in range(special_count):
            index = int(tokens[cursor]); cursor += 1
            special_order = int(tokens[cursor]); cursor += 1
            special_coefficients = [0] + [int(tokens[cursor + index]) % MOD for index in range(special_order)]
            cursor += special_order
            specials.append((index, special_order, special_coefficients))
        cases.append((target, initial_count, initial, order, coefficients, specials))
    return cases


def oracle(text):
    answers = []
    for target, initial_count, initial, order, coefficients, specials in parse(text):
        values = initial[:] + [0] * max(0, target - initial_count)
        overrides = {index: (special_order, special_coefficients)
                     for index, special_order, special_coefficients in specials}
        for position in range(initial_count + 1, target + 1):
            if position in overrides:
                special_order, special_coefficients = overrides[position]
                values[position] = sum(special_coefficients[j] * values[position - j]
                                       for j in range(1, special_order + 1)) % MOD
            else:
                values[position] = sum(coefficients[j] * values[position - j]
                                       for j in range(1, order + 1)) % MOD
        answers.append(values[target])
    return "".join(f"Case {index}: {answer}\n" for index, answer in enumerate(answers, 1))


SAMPLE_IN = (
    "7 5 0\n1 1 2 3 5\n2 1 1\n"
    "10 5 1\n1 1 2 3 5\n2 1 1\n10 2 1 2\n"
)
SAMPLE_OUT = "Case 1: 13\nCase 2: 76\n"
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("10 2 0\n1 1\n2 1 1\n") == "Case 1: 55\n"
assert oracle("10 2 1\n1 1\n2 1 1\n5 1 3\n") == "Case 1: 87\n"
assert oracle("6 3 0\n1 2 4\n3 1 1 1\n") == "Case 1: 24\n"


def render(cases):
    pieces = []
    for target, initial_count, initial, order, coefficients, specials in cases:
        pieces.append(f"{target} {initial_count} {len(specials)}\n")
        pieces.append(" ".join(str(value) for value in initial[1:]) + "\n")
        pieces.append(str(order) + " " + " ".join(str(value) for value in coefficients[1:]) + "\n")
        for index, special_order, special_coefficients in specials:
            pieces.append(str(index) + " " + str(special_order) + " " +
                          " ".join(str(value) for value in special_coefficients[1:]) + "\n")
    return "".join(pieces)


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(rng, max_target):
    initial_count = rng.randint(2, 8)
    order = rng.randint(1, min(initial_count, 5))
    initial = [0] + [rng.randint(0, 9) for _ in range(initial_count)]
    coefficients = [0] + [rng.randint(0, 4) for _ in range(order)]
    if sum(coefficients) == 0:
        coefficients[1] = 1
    target = rng.randint(initial_count + 1, max_target)
    specials = []
    for index in rng.sample(range(initial_count + 1, target + 1), rng.randint(0, 4)):
        special_order = rng.randint(1, min(order, initial_count))
        special_coefficients = [0] + [rng.randint(0, 4) for _ in range(special_order)]
        if sum(special_coefficients) == 0:
            special_coefficients[1] = 1
        specials.append((index, special_order, special_coefficients))
    return target, initial_count, initial, order, coefficients, specials


def build():
    write("2_edges", [
        (6, 2, [0, 1, 1], 1, [0, 1], []),
        (7, 5, [0, 1, 1, 2, 3, 5], 2, [0, 1, 1], []),
        (20, 1, [0, 3], 1, [0, 1], [(10, 1, [0, 2])]),
    ])
    write("3_wide", [random_case(random.Random(index), 2000) for index in range(6)])
    rng = random.Random(20261126)
    write("4_random", [random_case(rng, 5000) for _ in range(12)])
    write("5_io", [random_case(rng, 50000) for _ in range(16)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
