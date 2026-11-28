#!/usr/bin/env python3
import itertools
import random
from collections import deque
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(maxsize=None)
def distance_table(disc_count):
    states = list(itertools.product((1, 2, 3), repeat=disc_count))
    positions = {state: index for index, state in enumerate(states)}
    table = []
    for source in states:
        distances = [-1] * len(states)
        distances[positions[source]] = 0
        queue = deque([source])
        while queue:
            state = queue.popleft()
            pegs = [[], [], []]
            for disc_index, peg in enumerate(state):
                pegs[peg - 1].append(disc_index + 1)
            for peg in pegs:
                peg.reverse()
            for from_peg in range(3):
                if not pegs[from_peg]:
                    continue
                disc = pegs[from_peg][-1]
                for to_peg in range(3):
                    if to_peg == from_peg:
                        continue
                    if pegs[to_peg] and pegs[to_peg][-1] < disc:
                        continue
                    successor = list(state)
                    successor[disc - 1] = to_peg + 1
                    successor = tuple(successor)
                    if distances[positions[successor]] < 0:
                        distances[positions[successor]] = distances[positions[state]] + 1
                        queue.append(successor)
        table.append(distances)
    return positions, table


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        disc_count = tokens[cursor]
        cursor += 1
        if disc_count == 0:
            break
        start = tuple(tokens[cursor:cursor + disc_count])
        cursor += disc_count
        finish = tuple(tokens[cursor:cursor + disc_count])
        cursor += disc_count
        positions, table = distance_table(disc_count)
        answers.append(str(table[positions[start]][positions[finish]]))
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """4
1 1 1 1
2 2 2 2
3
1 3 3
2 1 1
5
1 3 2 2 2
2 3 2 1 2
0
"""
SAMPLE_OUT = """15
6
14
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n1\n0\n") == "0\n"
assert oracle("1\n1\n2\n0\n") == "1\n"
assert oracle("2\n1 1\n3 3\n0\n") == "3\n"
assert oracle("3\n1 2 3\n3 2 1\n0\n") == "3\n"
assert len(distance_table(4)[1]) == 81


def case(start, finish):
    return f"{len(start)}\n" + " ".join(map(str, start)) + "\n" + " ".join(map(str, finish)) + "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edges = "".join([
        case((1,), (1,)),
        case((1,), (2,)),
        case((1, 1), (2, 2)),
        case((1, 2, 3), (3, 2, 1)),
        case((3, 3, 3, 3), (1, 1, 1, 1)),
        case((1, 2, 1, 2, 1), (2, 1, 2, 1, 2)),
        "0\n",
    ])
    write("2_edges", edges)
    wide = "".join([
        case((3,) * 7, (1,) * 7),
        case((1,) * 7, (3,) * 7),
        case((1, 2, 3, 1, 2, 3, 1), (1, 3, 2, 1, 3, 2, 1)),
        case((1, 3, 1, 3, 1, 3, 1), (3, 1, 3, 1, 3, 1, 3)),
        "0\n",
    ])
    write("3_wide", wide)
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(60):
        disc_count = rng.randint(1, 7)
        random_cases.append(case(tuple(rng.randint(1, 3) for _ in range(disc_count)),
                                 tuple(rng.randint(1, 3) for _ in range(disc_count))))
    random_cases.append("0\n")
    write("4_random", "".join(random_cases))
    io_cases = []
    for _ in range(60000):
        io_cases.append(case((rng.randint(1, 3), rng.randint(1, 3), rng.randint(1, 3), rng.randint(1, 3)),
                             (rng.randint(1, 3), rng.randint(1, 3), rng.randint(1, 3), rng.randint(1, 3))))
    io_cases.append("0\n")
    write("5_io", "".join(io_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
