#!/usr/bin/env python3
import heapq
import random
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while cursor < len(tokens):
        gift_count = int(tokens[cursor]); cursor += 1
        unfriend_limit = int(tokens[cursor]); cursor += 1
        totals = defaultdict(int)
        for _ in range(gift_count):
            friend = tokens[cursor]; cursor += 1
            expense = int(tokens[cursor]); cursor += 1
            totals[friend] += expense
        largest = heapq.nlargest(min(unfriend_limit, len(totals)), totals.values())
        answers.append(str(sum(largest)))
    return "\n".join(answers) + "\n"


SAMPLE_ONE = """6 1
uvuvwevwevweonyetenyevweugwemubwemossas 10
ryuk 11
uvuvwevwevweonyetenyevweugwemubwemossas 5
fegla 3
tenshikanade 7
fegla 2
"""
SAMPLE_TWO = """4 3
frodo 1
harrypotter 2
frodo 2
harrypotter 2
"""
assert oracle(SAMPLE_ONE) == "15\n"
assert oracle(SAMPLE_TWO) == "7\n"
assert oracle("7 2\nwaynebot 7\nlhic 4\npetr 5\numnik 9\nizrak 6\ntourist 11\nzlobobber 9\n") == "20\n"
assert oracle("6 3\ndufresne 5\ngump 11\ndufresne 3\nmcmurphy 19\nleon 10\ndufresne 1\n") == "40\n"
assert oracle("1 1\nalice 1000000001\n") == "1000000001\n"


def write(name, cases):
    lines = []
    for gift_count, unfriend_limit, entries in cases:
        lines.append(f"{gift_count} {unfriend_limit}")
        lines.extend(f"{friend} {expense}" for friend, expense in entries)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, 1, [("solo", 1000000001)]),
        (4, 9, [("a", 1), ("b", 2), ("a", 3), ("c", 4)]),
        (3, 1, [("same", 7), ("same", 8), ("same", 9)]),
    ])
    rng = random.Random(20261126)
    wide = [(100000, 1, [(f"friend{index:05d}", rng.randint(1, 1000000001)) for index in range(100000)])]
    write("3_wide", wide)
    names = [f"name{index:03d}" for index in range(100)]
    mixed = []
    for _ in range(4):
        entries = [(rng.choice(names), rng.randint(1, 1000000001)) for _ in range(2000)]
        mixed.append((2000, rng.randint(1, 30), entries))
    write("4_random", mixed)
    io_cases = []
    for _ in range(1000):
        entries = [(f"g{index}", rng.randint(1, 1000000001)) for index in range(100)]
        io_cases.append((100, 5, entries))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
sample_entries = [
    ("uvuvwevwevweonyetenyevweugwemubwemossas", 10),
    ("ryuk", 11),
    ("uvuvwevwevweonyetenyevweugwemubwemossas", 5),
    ("fegla", 3),
    ("tenshikanade", 7),
    ("fegla", 2),
]
write("1_sample", [(6, 1, sample_entries)])
build()
