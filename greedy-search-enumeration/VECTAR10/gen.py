#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    answers = []
    for card_count in tokens:
        if card_count == 0:
            break
        deck = deque(range(1, card_count + 1))
        while len(deck) >= 2:
            deck.popleft()
            deck.append(deck.popleft())
        answers.append(str(deck[0]))
    return "\n".join(answers) + "\n"


SAMPLE = """2
3
4
0
"""
SAMPLE_OUT = """2
2
4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0\n") == "1\n"
assert oracle("5\n0\n") == "2\n"
assert oracle("8\n0\n") == "8\n"
assert oracle("1000000\n0\n") == "951424\n"


def write(name, counts):
    text = "".join(str(value) + "\n" for value in counts)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 16, 31, 32, 33, 0])
    write("3_wide", [1000000, 999999, 524288, 524289, 65536, 0])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 2000) for _ in range(120)] + [0])
    write("5_io", [rng.randint(1, 300) for _ in range(20000)] + [0])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
