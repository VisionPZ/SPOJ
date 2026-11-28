#!/usr/bin/env python3
import random
from itertools import combinations, permutations
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CARD_COUNT = 27
HAND_SIZE = 4


def valid_hidden(shown, n=CARD_COUNT, k=HAND_SIZE):
    total = sum(shown)
    answer = []
    for hidden in range(1, n + 1):
        if hidden in shown:
            continue
        place = sum(1 for card in shown if card < hidden)
        if (total + hidden) % k == place:
            answer.append(hidden)
    return answer


def oracle(text):
    tokens = [int(value) for value in text.split()]
    mickey_count = tokens[0]
    donald_count = tokens[1]
    cursor = 2
    lines = []
    for _ in range(mickey_count):
        hand = sorted(tokens[cursor:cursor + HAND_SIZE])
        cursor += HAND_SIZE
        hidden = hand[sum(hand) % HAND_SIZE]
        shown = tuple(card for card in hand if card != hidden)
        rank = valid_hidden(shown).index(hidden)
        lines.append(" ".join(str(card) for card in sorted(permutations(shown))[rank]))
    for _ in range(donald_count):
        table = tuple(tokens[cursor:cursor + HAND_SIZE - 1])
        cursor += HAND_SIZE - 1
        shown = tuple(sorted(table))
        rank = sorted(permutations(shown)).index(table)
        lines.append(str(valid_hidden(shown)[rank]))
    return "\n".join(lines) + ("\n" if lines else "")


SAMPLE = """3 0
1 2 3 4
4 13 6 2
8 20 7 4
"""
SAMPLE_OUT = """3 2 1
13 4 6
4 20 7
"""
assert SAMPLE_OUT == "3 2 1\n13 4 6\n4 20 7\n"
assert len(valid_hidden((1, 2, 3))) == 6
assert len(valid_hidden((1, 5, 9))) == 6
assert len(valid_hidden((7, 14, 21))) == 6
assert len(oracle(SAMPLE).splitlines()) == 3

def roundtrip(hand):
    mickey_out = oracle("1 0\n" + " ".join(str(card) for card in hand) + "\n").strip()
    recovered = oracle("0 1\n" + mickey_out + "\n").strip()
    hidden = sorted(hand)[sum(hand) % HAND_SIZE]
    return recovered == str(hidden)

assert roundtrip([1, 2, 3, 4])
assert roundtrip([4, 13, 6, 2])
assert roundtrip([8, 20, 7, 4])


def write(name, mickey_hands, donald_tables, expected=None):
    lines = [f"{len(mickey_hands)} {len(donald_tables)}"]
    lines.extend(" ".join(str(card) for card in hand) for hand in mickey_hands)
    lines.extend(" ".join(str(card) for card in table) for table in donald_tables)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text) if expected is None else expected)


def build():
    write("2_edges", [(1, 2, 3, 4), (24, 25, 26, 27), (5, 5 + 1, 5 + 2, 5 + 3)],
          [(1, 2, 3), (25, 26, 27), (3, 2, 1)])
    wide = [(1, 7, 13, 27), (2, 9, 18, 26), (4, 11, 20, 25)]
    write("3_wide", wide, [(1, 7, 13), (26, 18, 9), (4, 20, 11)])
    rng = random.Random(20261126)
    random_hands = [tuple(sorted(rng.sample(range(1, CARD_COUNT + 1), HAND_SIZE)))
                    for _ in range(200)]
    random_tables = [tuple(rng.sample(range(1, CARD_COUNT + 1), HAND_SIZE - 1))
                     for _ in range(200)]
    write("4_random", random_hands, random_tables)
    io_hands = [tuple(sorted(rng.sample(range(1, CARD_COUNT + 1), HAND_SIZE)))
                for _ in range(8000)]
    io_tables = [tuple(rng.sample(range(1, CARD_COUNT + 1), HAND_SIZE - 1))
                 for _ in range(8000)]
    write("5_io", io_hands, io_tables)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 2, 3, 4), (4, 13, 6, 2), (8, 20, 7, 4)], [], SAMPLE_OUT)
build()
