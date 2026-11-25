#!/usr/bin/env python3
import itertools
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


def berlekamp_massey(sequence, modulus):
    connection = [1] + [0] * len(sequence)
    previous = [1] + [0] * len(sequence)
    current_length = 0
    shift = 1
    last_discrepancy = 1
    for position in range(len(sequence)):
        discrepancy = sequence[position]
        for offset in range(1, current_length + 1):
            discrepancy = (discrepancy + connection[offset] * sequence[position - offset]) % modulus
        if discrepancy == 0:
            shift += 1
            continue
        scale = discrepancy * pow(last_discrepancy, -1, modulus) % modulus
        saved = connection[:]
        for index in range(0, len(sequence) - shift + 1):
            connection[index + shift] = (connection[index + shift] - scale * previous[index]) % modulus
        if 2 * current_length <= position:
            current_length = position + 1 - current_length
            previous = saved
            last_discrepancy = discrepancy
            shift = 1
        else:
            shift += 1
    return [(-value) % modulus for value in connection[1:current_length + 1]]


def prime_field_answer(order, modulus, terms):
    coefficients = berlekamp_massey(terms, modulus)
    total = sum(coefficients[index - 1] * terms[2 * order - index]
                for index in range(1, len(coefficients) + 1))
    return total % modulus


def composite_answer(order, modulus, terms):
    answers = set()
    for candidate in itertools.product(range(modulus), repeat=order):
        if all(sum(candidate[index] * terms[equation - 1 - index]
                   for index in range(order)) % modulus == terms[equation] % modulus
               for equation in range(order, 2 * order)):
            answers.add(sum(candidate[index] * terms[2 * order - 1 - index]
                            for index in range(order)) % modulus)
    assert len(answers) == 1, (order, modulus, answers)
    return answers.pop()


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    answers = []
    for _ in range(case_count):
        order = tokens[position]
        modulus = tokens[position + 1]
        position += 2
        terms = tokens[position:position + 2 * order]
        position += 2 * order
        if modulus == 1:
            answers.append(0)
        elif is_prime(modulus):
            answers.append(prime_field_answer(order, modulus, terms))
        else:
            answers.append(composite_answer(order, modulus, terms))
    return "\n".join(str(value) for value in answers) + ("\n" if answers else "")


SAMPLE = ("6\n1 16\n4 8\n1 10\n4 8\n2 64\n13 21 34 55\n"
          "2 27\n13 21 7 1\n3 1000000007\n32 16 8 4 2 1\n2 64\n13 21 34 56\n")
SAMPLE_OUT = "0\n6\n25\n8\n500000004\n40\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 2\n1 1\n") == "1\n"
assert oracle("1\n2 5\n2 3 0 4\n") == "2\n"
assert oracle("1\n3 1000000007\n1 2 4 8 16 32\n") == "64\n"
assert oracle("1\n1 1\n0 0\n") == "0\n"


def make_case(order, modulus, coefficients, initial):
    sequence = list(initial)
    while len(sequence) < 2 * order + 1:
        sequence.append(sum(coefficients[index] * sequence[-index - 1]
                            for index in range(order)) % modulus)
    return order, modulus, sequence[:2 * order], sequence[2 * order]


def write(name, cases):
    lines = [str(len(cases))]
    for order, modulus, terms, _ in cases:
        lines.append(f"{order} {modulus}")
        lines.append(" ".join(str(value) for value in terms))
    text = "\n".join(lines) + "\n"
    expected = [case[3] for case in cases]
    output = "\n".join(str(value) for value in expected) + ("\n" if expected else "")
    assert oracle(text) == output
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(output)


def build():
    rng = random.Random(20261126)
    edges = [
        (1, 1, [0, 0], 0),
        (1, 2, [1, 1], 1),
        (2, 4, [1, 2, 3, 1], 0),
        (1, 16, [4, 8], 0),
        (2, 27, [13, 21, 7, 1], 8),
        (2, 64, [13, 21, 34, 56], 40),
    ]
    write("2_edges", edges)
    wide = []
    for order in [1, 2, 3, 5, 10, 20, 50]:
        coefficients = [rng.randrange(1, 1000000007) for _ in range(order)]
        initial = [rng.randrange(1000000007) for _ in range(order)]
        wide.append(make_case(order, 1000000007, coefficients, initial))
    write("3_wide", wide)
    random_cases = []
    for _ in range(80):
        if rng.randrange(2) == 0:
            order = rng.randint(1, 3)
            modulus = rng.choice([4, 8, 9, 16, 25, 27, 32, 49, 64])
            coefficients = [rng.randrange(modulus) for _ in range(order)]
        else:
            order = rng.randint(1, 12)
            modulus = rng.choice([7, 101, 1000000007, 2147483647])
            coefficients = [rng.randrange(1, modulus) for _ in range(order)]
        initial = [rng.randrange(modulus) for _ in range(order)]
        random_cases.append(make_case(order, modulus, coefficients, initial))
    write("4_random", random_cases)
    io_cases = []
    for index in range(20000):
        order = 1 + index % 2
        modulus = 1000000007
        coefficients = [rng.randrange(1, modulus) for _ in range(order)]
        initial = [rng.randrange(modulus) for _ in range(order)]
        io_cases.append(make_case(order, modulus, coefficients, initial))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
