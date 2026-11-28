#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    numbers = list(map(int, text.split()))
    pos = 0
    answers = []
    while pos < len(numbers):
        pile_count = numbers[pos]
        pos += 1
        piles = tuple(sorted(numbers[pos:pos + pile_count]))
        pos += pile_count
        largest = piles[-1] if piles else 0
        fibonacci = [1, 2]
        while fibonacci[-1] <= largest:
            fibonacci.append(fibonacci[-1] + fibonacci[-2])
        moves = [value for value in fibonacci if value <= largest]

        @lru_cache(maxsize=None)
        def first_player_wins(state):
            for pile_index, seeds in enumerate(state):
                for take in moves:
                    if take > seeds:
                        break
                    reduced = list(state)
                    reduced[pile_index] = seeds - take
                    if not first_player_wins(tuple(sorted(reduced))):
                        return True
            return False

        answers.append("Ada" if first_player_wins(piles) else "Vinit")
    return "\n".join(answers) + "\n"


SAMPLE = """6
3 3 1 8 3 4
"""
SAMPLE_OUT = """Ada
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n10\n") == "Vinit\n"
assert oracle("1\n4\n") == "Vinit\n"
assert oracle("4\n6 1 7 3\n") == "Ada\n"
assert oracle("6\n4 6 10 9 3 8\n") == "Vinit\n"


def write(name, cases):
    lines = []
    for piles in cases:
        lines.append(str(len(piles)))
        lines.append(" ".join(str(value) for value in piles))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[0], [1], [2], [4], [10]])
    rng = random.Random(20261126)
    write("3_wide", [[rng.randint(0, 30)] for _ in range(200)])
    write("4_random", [[rng.randint(0, 12) for _ in range(rng.randint(1, 4))] for _ in range(80)])
    write("5_io", [[rng.randint(0, 20)] for _ in range(32000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[3, 3, 1, 8, 3, 4]])
build()

stress = [random.Random(99).randint(0, 3000000) for _ in range(100000)]
Path("/tmp/ADAFIMBR_big.txt").write_text("100000\n" + " ".join(map(str, stress)) + "\n")
