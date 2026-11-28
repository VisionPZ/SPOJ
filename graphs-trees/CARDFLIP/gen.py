#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    card_count = tokens[cursor]
    cursor += 1
    operation_count = tokens[cursor]
    cursor += 1
    deck = list(range(1, card_count + 1))
    answers = []
    for _ in range(operation_count):
        nephew = tokens[cursor]
        cursor += 1
        if nephew == 1:
            left = tokens[cursor]
            right = tokens[cursor + 1]
            cursor += 2
            deck[left - 1:right] = reversed(deck[left - 1:right])
        elif nephew == 2:
            position = tokens[cursor]
            cursor += 1
            answers.append(str(deck[position - 1]))
        else:
            card = tokens[cursor]
            cursor += 1
            answers.append(str(deck.index(card) + 1))
    return "\n".join(answers) + ("\n" if answers else "")


SAMPLE = """10 5
1 2 6
2 5
1 4 9
3 4
2 4
"""
SAMPLE_OUT = """3
9
9
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 1\n2 1\n") == "1\n"
assert oracle("4 2\n1 1 4\n2 1\n") == "4\n"
assert oracle("5 2\n1 2 4\n3 5\n") == "5\n"
assert oracle("5 2\n1 1 5\n2 3\n") == "3\n"


def write(name, card_count, operations):
    input_text = f"{card_count} {len(operations)}\n" + "".join(
        " ".join(str(value) for value in operation) + "\n"
        for operation in operations)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", 1, [(2, 1), (3, 1), (1, 1, 1), (2, 1)])
    write("3_wide", 1000, [(1, 1, 1000), (2, 1), (2, 1000), (3, 1), (3, 1000)])
    rng = random.Random(20261126)
    operations = []
    for _ in range(300):
        choice = rng.randint(1, 3)
        if choice == 1:
            left = rng.randint(1, 200)
            right = rng.randint(left, 200)
            operations.append((1, left, right))
        elif choice == 2:
            operations.append((2, rng.randint(1, 200)))
        else:
            operations.append((3, rng.randint(1, 200)))
    write("4_random", 200, operations)
    operations = []
    for step in range(1, 2001):
        if step % 3 == 0:
            operations.append((2, step))
        elif step % 3 == 1:
            left = rng.randint(1, 2000)
            right = rng.randint(left, 2000)
            operations.append((1, left, right))
        else:
            operations.append((3, rng.randint(1, 2000)))
    write("5_io", 2000, operations)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 10, [(1, 2, 6), (2, 5), (1, 4, 9), (3, 4), (2, 4)])
build()
