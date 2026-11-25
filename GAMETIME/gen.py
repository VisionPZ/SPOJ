#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(conquer_times, parent_nodes):
    castle_count = len(conquer_times)
    king_castle = castle_count - 1

    @lru_cache(maxsize=None)
    def best_from(beaten_mask):
        if beaten_mask >> king_castle & 1:
            return 0
        best_score = 0
        for chosen in range(castle_count):
            if beaten_mask >> chosen & 1:
                continue
            next_mask = beaten_mask | (1 << chosen)
            score = conquer_times[chosen]
            current = chosen
            while True:
                parent = parent_nodes[current]
                if parent < 0 or next_mask >> parent & 1:
                    break
                defeated_children = 0
                for candidate in range(castle_count):
                    if parent_nodes[candidate] == parent and next_mask >> candidate & 1:
                        defeated_children += 1
                if defeated_children < 2:
                    break
                next_mask |= 1 << parent
                score += conquer_times[parent]
                current = parent
            score += best_from(next_mask)
            if score > best_score:
                best_score = score
        return best_score

    return best_from(0)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        castle_count = tokens[cursor]
        cursor += 1
        if castle_count == 0:
            break
        conquer_times = tokens[cursor:cursor + castle_count]
        cursor += castle_count
        parent_nodes = tokens[cursor:cursor + castle_count]
        cursor += castle_count
        answers.append(str(oracle_case(conquer_times, parent_nodes)))
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """5
1 2 3 4 5
4 4 4 4 -1
5
2 2 2 2 2
1 2 3 4 -1
9
1 1 1 1 1 1 1 1 1
6 6 6 7 7 7 8 8 -1
0
"""
SAMPLE_OUT = """12
10
8
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n7\n-1\n0\n") == "7\n"
assert oracle("3\n5 6 7\n2 2 -1\n0\n") == "18\n"
assert oracle("3\n5 6 7\n-1 -1 -1\n0\n") == "18\n"
assert oracle("4\n1 2 3 4\n3 3 3 -1\n0\n") == "9\n"
assert oracle_case([2, 2], [1, -1]) == 4


def case(conquer_times, parent_nodes):
    return (str(len(conquer_times)) + "\n" + " ".join(map(str, conquer_times)) + "\n" +
            " ".join(map(str, parent_nodes)) + "\n")


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(rng, castle_count):
    conquer_times = [rng.randint(1, 5) for _ in range(castle_count)]
    parent_nodes = []
    for castle_index in range(castle_count):
        if castle_index == castle_count - 1:
            parent_nodes.append(-1)
        elif rng.random() < 0.25:
            parent_nodes.append(-1)
        else:
            parent_nodes.append(rng.randint(castle_index + 1, castle_count - 1))
    return case(conquer_times, parent_nodes)


def build():
    edges = "".join([
        case([4], [-1]),
        case([1, 2], [1, -1]),
        case([3, 5, 7], [-1, 2, -1]),
        case([2, 2, 2, 2], [3, 3, 3, -1]),
        case([1, 1, 1, 1, 1], [3, 3, 3, 4, -1]),
        "0\n",
    ])
    write("2_edges", edges)
    wide = "".join([
        "10\n" + " ".join(["100"] * 10) + "\n" + " ".join(["9"] * 9 + ["-1"]) + "\n",
        "10\n" + " ".join(["1"] * 10) + "\n" + " ".join(str(index + 1) for index in range(9)) + " -1\n",
        "9\n" + " ".join(["7"] * 9) + "\n6 6 6 7 7 7 8 8 -1\n",
        "0\n",
    ])
    write("3_wide", wide)
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(120):
        random_cases.append(random_case(rng, rng.randint(1, 10)))
    random_cases.append("0\n")
    write("4_random", "".join(random_cases))
    io_cases = []
    for _ in range(45000):
        io_cases.append(random_case(rng, rng.randint(1, 4)))
    io_cases.append("0\n")
    write("5_io", "".join(io_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
