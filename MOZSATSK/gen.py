#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    sequence = text.split()[0]
    length = len(sequence)
    if length == 1:
        return "yes\n0\n"
    visited = set()
    frontier = deque()
    start_state = (0, int(sequence[0]))
    visited.add(start_state)
    frontier.append((start_state, 0))
    while frontier:
        (position, digit), minutes = frontier.popleft()
        allowed = ((digit + 9) % 10, digit, (digit + 1) % 10)
        for step in (-2, -1, 1, 2):
            candidate = position + step
            if not (0 <= candidate < length):
                continue
            next_digit = int(sequence[candidate])
            if next_digit not in allowed:
                continue
            state = (candidate, next_digit)
            if state in visited:
                continue
            visited.add(state)
            if candidate == length - 1:
                return "yes\n" + str(minutes + 1) + "\n"
            frontier.append((state, minutes + 1))
    return "no\n"


SAMPLE = """5495
"""
SAMPLE_OUT = """yes
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5\n") == "yes\n0\n"
assert oracle("12\n") == "yes\n1\n"
assert oracle("09\n") == "yes\n1\n"
assert oracle("19\n") == "no\n"
assert oracle("000\n") == "yes\n1\n"


def write(name, sequence):
    text = sequence + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "19")
    write("3_wide", "0123456789" * 10000)
    rng = random.Random(20261126)
    write("4_random", "".join(str(rng.randint(0, 9)) for _ in range(1000)))
    write("5_io", "0123456789" * 9999 + "01")
    (Path("/tmp") / "MOZSATSK_big.txt").write_text("0123456789" * 10000 + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "5495")
build()
