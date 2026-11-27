#!/usr/bin/env python3
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def program1_answer():
    return math.comb(300, 50)


def program2_answer():
    state = tuple(range(11))
    seen = {state}
    steps = 0
    while True:
        steps += 1
        nxt = (state[10] + state[0] // 3) % 1001
        state = state[1:] + (nxt,)
        if state in seen:
            return steps
        seen.add(state)


def program3_answer():
    total = 0
    fact = 1
    for term in range(1, 1002):
        fact = (fact * term) % 13
        total += fact
    return total


def program4_answer():
    # Minimal integer with tau(n) = 7777 = 7 * 11 * 101
    candidates = [
        (2**100) * (3**10) * (5**6),
        (2**100) * (3**76),
        (2**706) * (3**10),
        (2**1110) * (3**6),
        2**7776,
    ]
    return min(candidates)


def oracle(_text=""):
    return (
        f"{program1_answer()}\n"
        f"{program2_answer()}\n"
        f"{program3_answer()}\n"
        f"{program4_answer()}\n"
    )


def tau(value):
    return sum(1 for d in range(1, value + 1) if value % d == 0)


assert math.comb(8 - 1, 1) == 7
assert tau(36) == 9
expected_out = oracle("")
assert expected_out.splitlines() == [
    "3112732325640920190797857778854820426121534695343468558816",
    "1104928",
    "74",
    "1169585942076198717640294180847616000000",
]


def write(name, inp=""):
    (ROOT / "in" / f"{name}.txt").write_text(inp)
    (ROOT / "out" / f"{name}.out").write_text(expected_out)


def build():
    write("2_edges", "\n")
    write("3_wide", "   \n\n")
    write("4_random", "0\n")
    write("5_io", "")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text("")
(ROOT / "out" / "1_sample.out").write_text(expected_out)
build()
