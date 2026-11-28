#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CYCLES = {}


def advance(state, moves, max_move):
    new_outcome = any(not state[max_move - move] for move in moves)
    return state[1:] + (new_outcome,)


def cycle_data(first_move, second_move):
    key = (first_move, second_move)
    if key in CYCLES:
        return CYCLES[key]
    moves = sorted(set((1, first_move, second_move)))
    max_move = moves[-1]
    outcomes = [False] * max_move
    for pile in range(1, max_move):
        outcomes[pile] = any(not outcomes[pile - move] for move in moves
                             if move <= pile)
    initial = tuple(outcomes)
    tortoise = advance(initial, moves, max_move)
    hare = advance(advance(initial, moves, max_move), moves, max_move)
    while tortoise != hare:
        tortoise = advance(tortoise, moves, max_move)
        hare = advance(advance(hare, moves, max_move), moves, max_move)
    preperiod = 0
    tortoise = initial
    while tortoise != hare:
        tortoise = advance(tortoise, moves, max_move)
        hare = advance(hare, moves, max_move)
        preperiod += 1
    period = 1
    hare = advance(tortoise, moves, max_move)
    while tortoise != hare:
        hare = advance(hare, moves, max_move)
        period += 1
    CYCLES[key] = (initial, moves, max_move, preperiod, period)
    return CYCLES[key]


def oracle_case(first_move, second_move, pile_size):
    initial, moves, max_move, preperiod, period = cycle_data(first_move, second_move)
    index = pile_size
    if index >= preperiod:
        index = preperiod + (index - preperiod) % period
    state = initial
    for _ in range(index):
        state = advance(state, moves, max_move)
    return "Alice" if state[0] else "Bob"


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for case_index in range(case_count):
        first_move = tokens[1 + 3 * case_index]
        second_move = tokens[2 + 3 * case_index]
        pile_size = tokens[3 + 3 * case_index]
        answers.append(oracle_case(first_move, second_move, pile_size))
    return "\n".join(answers) + "\n"


SAMPLE = "5\n5 4 8\n1 3 9\n4 3 10\n1 1 5\n1 5 6\n"
SAMPLE_OUT = "Bob\nAlice\nAlice\nAlice\nBob\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1 1\n") == "Alice\n"
assert oracle("1\n1 1 1000000000\n") == "Bob\n"
assert oracle("1\n1 5 6\n") == "Bob\n"
assert oracle("1\n7 13 1000000000\n") == "Bob\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    text += "".join(f"{first} {second} {pile}\n" for first, second, pile in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1, 1), (1, 1, 2), (1, 1, 1000000000),
                      (1, 20, 1000000000), (20, 1, 1000000000),
                      (20, 20, 1)])
    rng = random.Random(20261126)
    write("3_wide", [(rng.randint(1, 20), rng.randint(1, 20), 1000000000)
                     for _ in range(100)])
    write("4_random", [(rng.randint(1, 20), rng.randint(1, 20),
                        rng.randint(1, 1000000000)) for _ in range(200)])
    write("5_io", [(rng.randint(1, 20), rng.randint(1, 20),
                    rng.randint(1, 1000000000)) for _ in range(100000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(5, 4, 8), (1, 3, 9), (4, 3, 10), (1, 1, 5), (1, 5, 6)])
build()
