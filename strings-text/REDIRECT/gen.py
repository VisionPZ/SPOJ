#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    tile_count = int(tokens[0])
    turn_count = int(tokens[1])
    jumps = [int(value) for value in tokens[2:2 + tile_count]]
    charged = int(tokens[2 + tile_count])

    current = {1}
    step_limit = min(turn_count, 2 * tile_count + 5)
    for _ in range(step_limit):
        following = set()
        for position in current:
            first = position + jumps[position - 1]
            second = first + 1
            if 1 <= first <= tile_count:
                following.add(first)
            if 1 <= second <= tile_count:
                following.add(second)
            if position == charged:
                back = position - jumps[position - 1]
                if 1 <= back <= tile_count:
                    following.add(back)
        if not following:
            return "LOSER\n"
        current = following
    return "WINNER\n"


SAMPLE = """3 2
1 2 3
2
"""
SAMPLE_OUT = "LOSER\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 1\n1 2 3\n2\n") == "WINNER\n"
assert oracle("2 10\n1 1\n2\n") == "WINNER\n"
assert oracle("1 1\n1\n1\n") == "LOSER\n"
assert oracle("5 20\n1 1 1 1 1\n3\n") == "WINNER\n"


def write(name, turn_count, jumps, charged):
    text = f"{len(jumps)} {turn_count}\n" + " ".join(str(value) for value in jumps) + "\n"
    text += str(charged) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, [1], 1)
    write("3_wide", 1000000000, [1] * 200, 100)
    rng = random.Random(20261126)
    tile_count = 50
    write("4_random", rng.randint(1, 1000),
          [rng.randint(1, 10) for _ in range(tile_count)], rng.randint(1, tile_count))
    write("5_io", 1000000000, [rng.randint(1, 3) for _ in range(200)], 100)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 2, [1, 2, 3], 2)
build()
