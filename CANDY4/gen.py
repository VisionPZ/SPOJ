#!/usr/bin/env python3
import math
import random
from decimal import Decimal, getcontext
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent
getcontext().prec = 50


def oracle_case(box_size, probability):
    if probability <= 0.0 or probability >= 1.0:
        return Decimal(box_size)
    first = Decimal(probability)
    second = 1 - first
    first_power = first ** (box_size + 1)
    second_power = second ** (box_size + 1)
    total = Decimal(box_size) * (first_power + second_power)
    for eaten in range(box_size):
        ratio = Decimal(box_size + eaten + 1) / Decimal(eaten + 1)
        first_power = first_power * ratio * second
        second_power = second_power * ratio * first
        remaining = box_size - eaten - 1
        total += Decimal(remaining) * (first_power + second_power)
    return total


def math_comb(total_count, chosen_count):
    result = 1
    for index in range(1, chosen_count + 1):
        result = result * (total_count - chosen_count + index) // index
    return result


def exact_case(box_size, probability):
    scale = 1000000
    first = Fraction(int(round(probability * scale)), scale)
    second = 1 - first
    total = Fraction(0)
    for eaten in range(box_size + 1):
        combinations = math_comb(box_size + eaten, eaten)
        remaining = box_size - eaten
        total += remaining * combinations * (first ** (box_size + 1) * second ** eaten +
                                             second ** (box_size + 1) * first ** eaten)
    return float(total)


def oracle(text):
    lines = [line for line in text.splitlines() if line.strip()]
    answers = []
    for case_index, line in enumerate(lines, 1):
        box_size, probability_text = line.split()
        answer = oracle_case(int(box_size), float(probability_text))
        answers.append(f"Case {case_index}: {answer:.6f}")
    return "\n".join(answers) + "\n"


SAMPLE = """10 0.400000
100 0.500000
124 0.432650
325 0.325100
532 0.487520
2276 0.720000
"""
SAMPLE_OUT = """Case 1: 3.528175
Case 2: 10.326044
Case 3: 28.861945
Case 4: 167.965476
Case 5: 32.601816
Case 6: 1390.500000
"""
assert oracle(SAMPLE) == SAMPLE_OUT
for size, prob in [(1, 0.5), (2, 0.25), (5, 0.7), (8, 0.4)]:
    assert abs(float(oracle_case(size, prob)) - exact_case(size, prob)) < 1e-9
assert exact_case(4, 1.0) == 4
assert exact_case(4, 0.0) == 4


MAXIMUM_BOX_SIZE = 20000
FLOAT_LOGS = [0.0] * (2 * MAXIMUM_BOX_SIZE + 1)
FLOAT_COMPENSATION = 0.0
for value_index in range(1, 2 * MAXIMUM_BOX_SIZE + 1):
    term = math.log(value_index) - FLOAT_COMPENSATION
    updated = FLOAT_LOGS[value_index - 1] + term
    FLOAT_COMPENSATION = (updated - FLOAT_LOGS[value_index - 1]) - term
    FLOAT_LOGS[value_index] = updated


def float_render(box_size, probability):
    complement = 1.0 - probability
    if probability <= 0.0 or probability >= 1.0:
        return f"{float(box_size):.6f}"
    total = 0.0
    log_first = math.log(probability)
    log_second = math.log(complement)
    for eaten in range(box_size + 1):
        combination = (FLOAT_LOGS[box_size + eaten] -
                       FLOAT_LOGS[box_size] - FLOAT_LOGS[eaten])
        first = math.exp(combination + (box_size + 1) * log_first + eaten * log_second)
        second = math.exp(combination + (box_size + 1) * log_second + eaten * log_first)
        total += (box_size - eaten) * (first + second)
    return f"{total:.6f}"


def stable_probability(box_size, probability):
    scale = 1000000
    units = int(round(probability * scale))
    for offset in range(2000):
        candidate = ((units + offset) % scale) / scale
        exact = f"{oracle_case(box_size, Decimal(candidate)):.6f}"
        if exact == float_render(box_size, candidate):
            return candidate
    return probability


def write(name, cases, stabilize=False):
    if stabilize:
        cases = [(size, stable_probability(size, prob))
                 for size, prob in cases]
    input_text = "".join(f"{size} {prob:.6f}\n" for size, prob in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(1, 0.0), (1, 1.0), (2, 0.0), (2, 1.0),
                      (3, 0.5), (20000, 1.0), (20000, 0.0)])
    write("3_wide", [(20000, 0.3), (20000, 0.5), (20000, 0.7),
                     (20000, 0.999999), (20000, 0.000001)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 20000), rng.random())
                       for _ in range(40)], stabilize=True)
    write("5_io", [(rng.randint(1, 20000), rng.random())
                   for _ in range(300)], stabilize=True)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
