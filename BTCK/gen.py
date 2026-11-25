#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIGIT_COUNT = 10
FULL_MASK = (1 << DIGIT_COUNT) - 1
INFINITY = 10 ** 30
MASKS_BY_COUNT = [
    [mask for mask in range(1 << DIGIT_COUNT) if bin(mask).count("1") == size]
    for size in range(DIGIT_COUNT + 1)
]


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        coefficients = [int(tokens[cursor + index]) for index in range(DIGIT_COUNT)]
        cursor += DIGIT_COUNT
        limit = int(tokens[cursor]); cursor += 1
        # Subset dynamic programming: suffix_cost[pos][mask] is the least
        # cost using the digits in mask for positions pos through nine.
        suffix_cost = [[INFINITY] * (FULL_MASK + 1) for _ in range(DIGIT_COUNT + 1)]
        suffix_cost[DIGIT_COUNT][0] = 0
        for position in range(DIGIT_COUNT - 1, -1, -1):
            need = DIGIT_COUNT - position
            for mask in MASKS_BY_COUNT[need]:
                best = INFINITY
                for digit in range(DIGIT_COUNT):
                    if mask & (1 << digit):
                        candidate = (coefficients[position] * digit
                                     + suffix_cost[position + 1][mask ^ (1 << digit)])
                        if candidate < best:
                            best = candidate
                suffix_cost[position][mask] = best
        if suffix_cost[0][FULL_MASK] > limit:
            answers.append("-1")
            continue
        remaining = FULL_MASK
        chosen = []
        spent = 0
        for position in range(DIGIT_COUNT):
            for digit in range(DIGIT_COUNT):
                if not (remaining & (1 << digit)):
                    continue
                candidate = (spent + coefficients[position] * digit
                             + suffix_cost[position + 1][remaining ^ (1 << digit)])
                if candidate <= limit:
                    chosen.append(str(digit))
                    spent += coefficients[position] * digit
                    remaining ^= (1 << digit)
                    break
        answers.append(" ".join(chosen))
    return "\n".join(answers) + "\n"


SAMPLE_INPUT = (
    "2\n"
    "1 2 3 4 5 6 7 8 9 10\n200\n"
    "1 2 3 4 5 6 7 8 9 10\n100\n"
)
SAMPLE_OUTPUT = "2 6 8 9 7 5 4 3 1 0\n-1\n"
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n1 2 3 4 5 6 7 8 9 10\n165\n") == "9 8 7 6 5 4 3 2 1 0\n"
assert oracle("1\n1 1 1 1 1 1 1 1 1 1\n1000000000\n") == "0 1 2 3 4 5 6 7 8 9\n"
assert oracle("1\n1000000000 1000000000 1000000000 1000000000 1000000000 "
              "1000000000 1000000000 1000000000 1000000000 1000000000\n1\n") == "-1\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n"
    for coefficients, limit in cases:
        input_text += " ".join(str(value) for value in coefficients) + "\n"
        input_text += str(limit) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", [([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 200),
                   ([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 100)])
write("2_edges", [([1] * 10, 1000000000), ([1] * 10, 45),
                  ([10 ** 9] * 10, 1),
                  ([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 165),
                  ([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 166)])
random.seed(2026)
write("3_wide", [([random.randint(1, 10 ** 9) for _ in range(10)],
                  random.randint(1, 10 ** 9)) for _ in range(60)])
write("4_random", [([random.randint(1, 100) for _ in range(10)],
                    random.randint(1, 3000)) for _ in range(80)])
write("5_io", [([random.randint(1, 10 ** 9) for _ in range(10)],
                random.randint(1, 10 ** 9)) for _ in range(200)])
