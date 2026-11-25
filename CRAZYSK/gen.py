#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def max_exchanges(items_bought, return_cards):
    low = 0
    high = items_bought
    while low < high:
        middle = (low + high + 1) // 2
        if items_bought - middle * (return_cards - 1) >= 1:
            low = middle
        else:
            high = middle - 1
    return low


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        bought = int(tokens[cursor]); cursor += 1
        returned = int(tokens[cursor]); cursor += 1
        answers.append(str(bought + max_exchanges(bought, returned)))
    return "\n".join(answers) + "\n"


def simulate(items_bought, return_cards):
    total_items = items_bought
    cards_on_hand = items_bought
    while cards_on_hand >= return_cards:
        cards_on_hand -= return_cards
        cards_on_hand += 1
        total_items += 1
    return total_items


SAMPLE = """5
15 3
2147483647 2
34 3
231 2
5 2
"""
SAMPLE_OUT = """22
4294967293
50
461
9
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n3 2\n10 3\n4 4\n") == "5\n14\n5\n"
assert oracle("1\n18446744073709551615 2\n") == "36893488147419103229\n"
for bought in range(2, 90):
    for returned in range(2, bought + 1):
        assert simulate(bought, returned) == int(oracle(f"1\n{bought} {returned}\n").strip())


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(
        f"{bought} {returned}\n" for bought, returned in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(2, 2), (3, 3), (4, 2), (5, 5), (10, 10), (1000, 999)])
    write("3_wide", [(2**64 - 1, 2), (2**63, 3), (10**18, 10**9),
                     (2**64 - 2, 2**63), (2**64 - 3, 7)])
    rng = random.Random(20261126)
    pairs = []
    for _ in range(60):
        bought = rng.randint(2, 2**64 - 1)
        returned = rng.randint(2, bought)
        pairs.append((bought, returned))
    write("4_random", pairs)
    write("5_io", [(2**64 - 1, 2) for _ in range(99)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(15, 3), (2147483647, 2), (34, 3), (231, 2), (5, 2)])
build()
