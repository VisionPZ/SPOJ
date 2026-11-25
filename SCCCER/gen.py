#!/usr/bin/env python3
import random
from functools import lru_cache
from itertools import permutations
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_force(text):
    values = text.split()
    if not values:
        return []
    case_count = int(values[0])
    position = 1
    answers = []
    for _ in range(case_count):
        size = int(values[position])
        seating = values[position + 1]
        position += 2
        best = None
        for arrangement in set(permutations(seating)):
            if any(arrangement[index] == arrangement[index + 1] == arrangement[index + 2]
                   for index in range(size - 2)):
                continue
            changes = sum(1 for index in range(size) if arrangement[index] != seating[index])
            if best is None or changes < best:
                best = changes
        answers.append(-1 if best is None else best)
    return answers


def oracle(text):
    values = text.split()
    if not values:
        return []
    case_count = int(values[0])
    position = 1
    answers = []
    for _ in range(case_count):
        size = int(values[position])
        seating = values[position + 1]
        position += 2
        totals = tuple(seating.count(letter) for letter in "CPNS")

        @lru_cache(maxsize=None)
        def search(used, last, run, place):
            if place == size:
                return 0
            best = -1000
            for kind in range(4):
                if used[kind] == totals[kind]:
                    continue
                next_run = run + 1 if kind == last else 1
                if next_run > 2:
                    continue
                nxt = list(used)
                nxt[kind] += 1
                kept = 1 if "CPNS"[kind] == seating[place] else 0
                score = kept + search(tuple(nxt), kind, next_run, place + 1)
                if score > best:
                    best = score
            return best

        kept = search((0, 0, 0, 0), 4, 0, 0)
        answers.append(-1 if kept < 0 else size - kept)
    return answers


SAMPLE = """2
8
CCCCCCPN

3
CCC

"""
SAMPLE_OUT = """4
-1
"""
assert brute_force(SAMPLE) == [4, -1]
assert oracle(SAMPLE) == [4, -1]
assert oracle("1\n1\nC\n") == [0]
assert oracle("1\n2\nCC\n") == [0]
assert oracle("1\n3\nCCC\n") == [-1]
assert oracle("1\n6\nCCPPCC\n") == [0]
assert oracle("1\n6\nCCCPPP\n") == [2]


def render(cases):
    blocks = [str(len(cases))]
    for size, seating in cases:
        blocks.append(str(size))
        blocks.append(seating)
    return "\n".join(blocks) + "\n"


def output_for(cases):
    answers = oracle(render(cases))
    return "".join(str(answer) + "\n" for answer in answers)


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(output_for(cases))


def build():
    write("2_edges", [(1, "C"), (2, "CC"), (3, "CCC"), (3, "CPN"), (4, "CCCC")])
    write("3_wide", [(20, "C" * 20), (20, ("CCP" * 7)[:20]), (20, "CCCCCCCCCCCCPNPNPNPP")])
    rng = random.Random(20261126)
    cases = []
    for _ in range(12):
        size = rng.randint(3, 14)
        seating = "".join(rng.choice("CPNS") for _ in range(size))
        cases.append((size, seating))
    write("4_random", cases)
    io_cases = []
    for _ in range(40):
        size = 20
        seating = "".join(rng.choice("CPNS") for _ in range(size))
        io_cases.append((size, seating))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
