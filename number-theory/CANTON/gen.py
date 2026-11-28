#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def linear_term(term_index):
    total = 0
    diagonal = 0
    while total < term_index:
        diagonal += 1
        total += diagonal
    previous = total - diagonal
    offset = term_index - previous - 1
    if diagonal % 2 == 0:
        return 1 + offset, diagonal - offset
    return diagonal - offset, 1 + offset


def generated_terms(count):
    terms = []
    diagonal = 1
    while len(terms) < count:
        if diagonal % 2 == 0:
            terms.extend((position + 1, diagonal - position)
                         for position in range(diagonal))
        else:
            terms.extend((diagonal - position, position + 1)
                         for position in range(diagonal))
        diagonal += 1
    return terms[:count]


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    lines = []
    for _ in range(case_count):
        term_index = int(tokens[cursor]); cursor += 1
        numerator, denominator = linear_term(term_index)
        lines.append(f"TERM {term_index} IS {numerator}/{denominator}")
    return "".join(line + "\n" for line in lines)


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        f"{term_index}\n" for term_index in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert [linear_term(n) for n in (3, 14, 7)] == [(2, 1), (2, 4), (1, 4)]
reference = generated_terms(3000)
assert all(linear_term(index + 1) == reference[index] for index in range(3000))
assert linear_term(1) == (1, 1)
assert 4471 * 4472 // 2 < 10**7 <= 4472 * 4473 // 2


def build():
    write("2_edges", [1, 2, 3, 4, 5, 6, 7, 10, 11, 14, 15,
                      4472, 4473, 9999999, 10000000])
    write("3_wide", [1, 10000000, 4472, 4473, 9999999, 1,
                     10000000, 2, 9999998, 3, 9999997, 4])
    rng = random.Random(20261125)
    write("4_random", [rng.randint(1, 10**7) for _ in range(20)])
    write("5_io", [10000000 - index for index in range(20)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3, 14, 7])
build()
print("generated five test pairs")
