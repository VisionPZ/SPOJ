#!/usr/bin/env python3
import itertools
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def factorize(value):
    factors = []
    divisor = 2
    while divisor * divisor <= value:
        count = 0
        while value % divisor == 0:
            value //= divisor
            count += 1
        if count:
            factors.append(count)
        divisor += 1
    if value > 1:
        factors.append(1)
    return tuple(factors)


def first_player_wins(value, limit):
    @lru_cache(maxsize=None)
    def winning(state):
        if all(count == 0 for count in state):
            return False
        indices = [index for index, count in enumerate(state) if count > 0]
        for take_count in range(1, min(limit, len(indices)) + 1):
            for chosen in itertools.combinations(indices, take_count):
                amounts = itertools.product(*(range(1, state[index] + 1) for index in chosen))
                for amount_tuple in amounts:
                    nxt = list(state)
                    for index, amount in zip(chosen, amount_tuple):
                        nxt[index] -= amount
                    if not winning(tuple(nxt)):
                        return True
        return False
    return winning(factorize(value))


def oracle(text):
    tokens = text.split()
    rounds = int(tokens[0])
    results = []
    starter_is_mona = True
    mona_wins = 0
    for index in range(rounds):
        value = int(tokens[1 + 2 * index])
        limit = int(tokens[2 + 2 * index])
        round_is_mona = first_player_wins(value, limit) == starter_is_mona
        results.append("Mona" if round_is_mona else "Alaa")
        if round_is_mona:
            mona_wins += 1
            starter_is_mona = True
        else:
            starter_is_mona = False
    overall = "Mona" if mona_wins * 2 >= rounds else "Alaa"
    return "\n".join(results + ["", overall]) + "\n"


SAMPLE = """5
3 4
6 2
6 1
9 1
18 2
"""
SAMPLE_OUT = """Mona
Mona
Alaa
Alaa
Alaa

Alaa
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert first_player_wins(2, 1)
assert not first_player_wins(6, 1)
assert first_player_wins(9, 2)
assert oracle("1\n2 1\n") == "Mona\n\nMona\n"
assert oracle("2\n6 1\n6 1\n") == "Alaa\nMona\n\nMona\n"


def write(name, rounds):
    text = str(len(rounds)) + "\n"
    for value, limit in rounds:
        text += f"{value} {limit}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(2, 1), (4, 1), (6, 1), (8, 2), (9, 1), (12, 2), (16, 3)])
    write("3_wide", [(997, 10), (996, 1), (960, 3), (729, 2), (1024, 4), (997, 1)])
    rng = random.Random(20261126)
    rounds = []
    for _ in range(10):
        value = rng.randint(2, 2000)
        limit = rng.randint(1, 10)
        rounds.append((value, limit))
    write("4_random", rounds)
    rounds = [(rng.choice([512, 729, 1024, 1500, 1998]), rng.randint(1, 10)) for _ in range(10)]
    write("5_io", rounds)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(3, 4), (6, 2), (6, 1), (9, 1), (18, 2)])
build()
