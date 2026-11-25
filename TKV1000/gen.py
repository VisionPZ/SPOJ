#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(None)
def winning(takeover, buyout, turn):
    own, opponent = (takeover, buyout) if turn == 0 else (buyout, takeover)
    if not own:
        return False
    if not opponent:
        return True
    moves = []
    for own_index, own_value in enumerate(own):
        for opponent_index, opponent_value in enumerate(opponent):
            if own_value > opponent_value:
                reduced = list(opponent)
                del reduced[opponent_index]
                moves.append((list(own), reduced))
    for first_index in range(len(own)):
        for second_index in range(first_index + 1, len(own)):
            merged = list(own)
            combined = merged[first_index] + merged[second_index]
            merged = [merged[index] for index in range(len(merged))
                      if index not in (first_index, second_index)] + [combined]
            moves.append((merged, list(opponent)))
    if not moves:
        return False
    for new_own, new_opponent in moves:
        if turn == 0:
            next_takeover, next_buyout = tuple(sorted(new_own)), tuple(sorted(new_opponent))
        else:
            next_takeover, next_buyout = tuple(sorted(new_opponent)), tuple(sorted(new_own))
        if not winning(next_takeover, next_buyout, 1 - turn):
            return True
    return False


def subset_sums(values):
    sums = {0}
    for value in values:
        sums |= {total + value for total in sums}
    return sums


def oracle(cases):
    lines = []
    for case_number, (takeover, buyout) in enumerate(cases, 1):
        name = "Takeover Incorporated" if winning(tuple(takeover), tuple(buyout), 0) else "Buyout Limited"
        lines.append(f"Case {case_number}: {name}")
    return "\n".join(lines) + "\n"


SAMPLE = [([7, 1, 1], [5, 5]), ([3, 3, 3, 3], [5, 5])]
SAMPLE_TEXT = "3 2\n7 1 1\n5 5\n4 2\n3 3 3 3\n5 5\n"
SAMPLE_OUT = "Case 1: Takeover Incorporated\nCase 2: Buyout Limited\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert winning((2,), (1,), 0)
assert not winning((1,), (2,), 0)
assert winning((15, 9, 3), (21,), 0)
assert not winning((3, 3, 3, 3), (5, 5), 0)


def write(name, cases):
    blocks = []
    for takeover, buyout in cases:
        blocks.append(f"{len(takeover)} {len(buyout)}")
        blocks.append(" ".join(str(value) for value in takeover))
        blocks.append(" ".join(str(value) for value in buyout))
    text = "\n".join(blocks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


def random_case(rng, largest_value, maximum_size):
    while True:
        takeover_size = rng.randint(1, maximum_size)
        buyout_size = rng.randint(1, maximum_size)
        pool = rng.sample(range(1, largest_value + 1), takeover_size + buyout_size)
        takeover = sorted(pool[:takeover_size], reverse=True)
        buyout = sorted(pool[takeover_size:], reverse=True)
        if not subset_sums(takeover) & (subset_sums(buyout) - {0}):
            return takeover, buyout


def build():
    write("2_edges", [([2], [1]), ([1], [2]), ([15, 9, 3], [21]), ([26, 23], [25, 19, 18, 15])])
    write("3_wide", [([1000000000000], [999999999999]),
                     ([500000000000, 499999999999], [1000000000000])])
    rng = random.Random(20261126)
    write("4_random", [random_case(rng, 40, 4) for _ in range(15)])
    write("5_io", [random_case(rng, 60, 5) for _ in range(25)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_TEXT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
