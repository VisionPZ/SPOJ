#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(cards):
    @lru_cache(maxsize=None)
    def solve(left, right):
        if left > right:
            return 0
        if cards[left + 1] >= cards[right]:
            take_left = cards[left] - cards[left + 1] + solve(left + 2, right)
        else:
            take_left = cards[left] - cards[right] + solve(left + 1, right - 1)
        if cards[left] >= cards[right - 1]:
            take_right = cards[right] - cards[left] + solve(left + 1, right - 1)
        else:
            take_right = cards[right] - cards[right - 1] + solve(left, right - 2)
        return max(take_left, take_right)

    return solve(0, len(cards) - 1)


def oracle(text):
    answers = []
    for line in text.splitlines():
        tokens = [int(value) for value in line.split()]
        if not tokens or tokens[0] == 0:
            break
        answers.append(f"In game {len(answers) + 1}, the greedy strategy might lose by as many as {oracle_case(tuple(tokens[1:]))} points.")
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """4 3 2 10 4
8 1 2 3 4 5 6 7 8
8 2 2 1 5 3 8 7 3
0
"""
SAMPLE_OUT = """In game 1, the greedy strategy might lose by as many as 7 points.
In game 2, the greedy strategy might lose by as many as 4 points.
In game 3, the greedy strategy might lose by as many as 5 points.
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case((3, 2, 10, 4)) == 7
assert oracle_case((1, 2)) == 1
assert oracle_case((5, 5, 5, 5)) == 0
assert oracle_case((9, 1, 1, 9, 1, 1)) == 16


def write_case(name, games):
    text = "".join(str(len(cards)) + " " + " ".join(str(value) for value in cards) + "\n" for cards in games) + "0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [(5, 5), (1, 2), (1, 1, 1, 1), (9, 1, 1, 9, 1, 1)])
    write_case("3_wide", [tuple(1 for _ in range(200)), tuple(range(1, 101)) + tuple(range(100, 0, -1))])
    rng = random.Random(20261126)
    games = []
    for _ in range(30):
        size = 2 * rng.randint(1, 10)
        games.append(tuple(rng.randint(1, 1000) for _ in range(size)))
    write_case("4_random", games)
    rng = random.Random(667211)
    games = []
    for _ in range(500):
        size = 2 * rng.randint(1, 5)
        games.append(tuple(rng.randint(1, 20) for _ in range(size)))
    write_case("5_io", games)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
