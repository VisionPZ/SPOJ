#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007


def oracle_case(board_size, dice_count):
    if board_size == 1:
        return 1
    distance = board_size - 1
    tuples = list(itertools.product(range(1, 7), repeat=dice_count))
    by_sum = {}
    for values in tuples:
        by_sum.setdefault(sum(values), []).append(values)
    largest_step = 6 * dice_count
    total = 0

    def assignments(parts, index, previous):
        nonlocal total
        if index == len(parts):
            total += 1
            return
        for values in by_sum[parts[index]]:
            if values == previous:
                continue
            assignments(parts, index + 1, values)

    def compositions(left, parts):
        if left == 0:
            assignments(parts, 0, None)
            return
        for step in range(dice_count, min(largest_step, left) + 1):
            compositions(left - step, parts + [step])

    compositions(distance, [])
    return total % MODULUS


def oracle(text):
    tokens = [int(token) for token in text.split()]
    case_count = tokens[0]
    answers = []
    for case_index in range(case_count):
        board_size = tokens[1 + 2 * case_index]
        dice_count = tokens[2 + 2 * case_index]
        answers.append(f"Scenario #{case_index + 1}: "
                       f"{oracle_case(board_size, dice_count)}")
    return "\n".join(answers) + "\n"


SAMPLE = """3
3 1
4 1
6 1
"""
SAMPLE_OUT = """Scenario #1: 1
Scenario #2: 3
Scenario #3: 7
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(1, 3) == 1
assert oracle_case(2, 1) == 1
assert oracle_case(5, 1) == 4
assert oracle_case(2, 2) == 0
assert oracle_case(3, 2) == 1
assert len(list(itertools.product(range(1, 7), repeat=3))) == 216


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        f"{board_size} {dice_count}\n" for board_size, dice_count in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (1, 3), (2, 1), (2, 3), (3, 2), (4, 2), (4, 3)])
    write("3_wide", [(7, 1)] * 30 + [(6, 2)] * 20)
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 6), rng.randint(1, 2))
                       for _ in range(30)])
    write("5_io", [(rng.randint(5, 7), 1) for _ in range(50)])
    big_rng = random.Random(16180)
    with open("/tmp/VPL1_AB_big.txt", "w") as handle:
        handle.write("50\n")
        for _ in range(50):
            handle.write(f"{big_rng.randint(80, 100)} {big_rng.randint(1, 3)}\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(3, 1), (4, 1), (6, 1)])
build()
