#!/usr/bin/env python3
import random
from fractions import Fraction
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 10**9 + 7


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    lines = []
    for _ in range(case_count):
        pile_count = tokens[cursor]
        minus_weight, same_weight, plus_weight = tokens[cursor + 1:cursor + 4]
        alice_mood, bob_mood = tokens[cursor + 4:cursor + 6]
        cursor += 6

        @lru_cache(maxsize=None)
        def solve(remaining, turn):
            if remaining == 0:
                return Fraction(1) if turn == 0 else Fraction(0)
            chosen = None
            for decided in (1, 4, 9, 16):
                if decided > remaining:
                    break
                options = []
                if decided - 1 >= 1:
                    options.append((decided - 1, minus_weight))
                options.append((decided, same_weight))
                if decided + 1 <= remaining:
                    options.append((decided + 1, plus_weight))
                weight_sum = sum(weight for _, weight in options)
                value = sum(
                    Fraction(weight, weight_sum) * solve(remaining - taken, 1 - turn)
                    for taken, weight in options
                )
                if chosen is None:
                    chosen = value
                elif turn == 0:
                    chosen = min(chosen, value) if alice_mood == 1 else max(chosen, value)
                else:
                    chosen = max(chosen, value) if bob_mood == 1 else min(chosen, value)
            return chosen

        chance = solve(pile_count, 0)
        answer = chance if bob_mood == 1 else 1 - chance
        lines.append(f"{float(answer):.4f}")
    return "\n".join(lines) + "\n"


SAMPLE = """2
1
1 2 3
0 0
5
1 2 3
0 1
"""
SAMPLE_OUT = """1.0000
0.4333
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n1 1 1\n1 1\n") == "0.0000\n"
assert oracle("1\n1\n1 1 1\n0 0\n") == "1.0000\n"
assert oracle("1\n4\n1 2 3\n0 1\n") == "0.4240\n"
assert oracle("1\n2\n5 1 1\n1 1\n") == "0.5000\n"


def write(name, cases):
    parts = [str(len(cases))]
    for pile_count, weights, moods in cases:
        parts.append(str(pile_count))
        parts.append(" ".join(str(weight) for weight in weights))
        parts.append(" ".join(str(mood) for mood in moods))
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, (1, 1, 1), (1, 1)), (2, (100000, 1, 1), (0, 1)),
                      (3, (1, 100000, 1), (1, 0)), (4, (1, 1, 100000), (0, 0))])
    write("3_wide", [(40, (100000, 100000, 100000), (1, 1)),
                     (40, (1, 1, 1), (0, 0)),
                     (39, (7, 11, 13), (1, 0)),
                     (39, (7, 11, 13), (0, 1))])
    rng = random.Random(20261126)
    cases = []
    for _ in range(10):
        pile_count = rng.randint(1, 45)
        weights = tuple(rng.randint(1, 100000) for _ in range(3))
        moods = (rng.randint(0, 1), rng.randint(0, 1))
        cases.append((pile_count, weights, moods))
    write("4_random", cases)
    write("5_io", [(43, (rng.randint(1, 100000), rng.randint(1, 100000),
                         rng.randint(1, 100000)), (rng.randint(0, 1), rng.randint(0, 1)))
                   for _ in range(10)])

    big_parts = ["10"]
    for _ in range(10):
        big_parts.append("1000000")
        big_parts.append("99991 50021 70001")
        big_parts.append("0 1")
    Path("/tmp/DRUNK_big.txt").write_text("\n".join(big_parts) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, (1, 2, 3), (0, 0)), (5, (1, 2, 3), (0, 1))])
build()
