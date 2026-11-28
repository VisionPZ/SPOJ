#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_VALUE = 10 ** 9


def oracle(text):
    tokens = [int(value) for value in text.split()]
    roll_count = tokens[0]
    dice_count = tokens[1]
    cell_count = tokens[2]
    cursor = 3
    dice = [1] * dice_count
    alice_position = 0
    bob_position = 0
    alice_turn = True
    answers = []
    for _ in range(roll_count):
        die_index = tokens[cursor]
        shown_value = tokens[cursor + 1]
        range_first = tokens[cursor + 2]
        range_last = tokens[cursor + 3]
        cursor += 4
        dice[die_index] = shown_value
        available = [value for value in dice[range_first:range_last + 1] if 0 <= value <= MAX_VALUE]
        move_distance = 1
        if available:
            product = 1
            for value in available:
                product *= value
            move_distance = product % cell_count
        if alice_turn:
            alice_position = (alice_position + move_distance) % cell_count
            answers.append(str(alice_position))
        else:
            bob_position = (bob_position + move_distance) % cell_count
            answers.append(str(bob_position))
        if alice_position == bob_position:
            cell = alice_position
            dice = [min(value * cell, MAX_VALUE + 1) for value in dice]
        alice_turn = not alice_turn
    return "\n".join(answers) + "\n"


SAMPLE = """6 4 4
0 1000000000 1 1
1 999999998 1 1
2 500000000 3 3
0 1 2 2
3 1 0 3
0 6 0 3
"""
SAMPLE_OUT = """1
2
2
2
0
0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1 10\n0 5 0 0\n") == "5\n"
assert oracle("2 2 4\n0 2 0 0\n1 3 0 1\n") == "2\n2\n"
assert oracle("3 3 7\n0 0 0 2\n1 4 0 2\n2 1 1 2\n") == "0\n0\n0\n"
assert MAX_VALUE + 1 > MAX_VALUE


def format_case(rolls, dice_count, cell_count):
    text = f"{len(rolls)} {dice_count} {cell_count}\n"
    for die_index, value, first, last in rolls:
        text += f"{die_index} {value} {first} {last}\n"
    return text


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", format_case([
        (0, 0, 0, 2), (1, 4, 0, 2), (2, 1, 1, 2),
        (0, 2, 0, 0), (1, 1, 0, 2), (2, MAX_VALUE, 0, 0),
    ], 3, 4))
    rng = random.Random(20261129)
    wide_rolls = []
    for _ in range(24):
        first = rng.randint(0, 5)
        wide_rolls.append((rng.randint(0, 7), rng.randint(0, MAX_VALUE), first,
                           rng.randint(first, 7)))
    write("3_wide", format_case(wide_rolls, 8, 1000000000))
    dice_count = rng.randint(3, 5)
    cell_count = rng.randint(2, 1000)
    random_rolls = []
    for _ in range(40):
        first = rng.randint(0, dice_count - 1)
        random_rolls.append((rng.randint(0, dice_count - 1), rng.randint(0, MAX_VALUE),
                             first, rng.randint(first, dice_count - 1)))
    write("4_random", format_case(random_rolls, dice_count, cell_count))
    io_rolls = []
    for _ in range(2200):
        first = rng.randint(0, 3)
        io_rolls.append((rng.randint(0, 3), rng.randint(0, MAX_VALUE), first,
                         rng.randint(first, 3)))
    write("5_io", format_case(io_rolls, 4, 1000000000))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
