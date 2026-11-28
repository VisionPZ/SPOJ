#!/usr/bin/env python3
import random
import sys
from functools import lru_cache
from pathlib import Path

sys.setrecursionlimit(10000)
ROOT = Path(__file__).resolve().parent


def oracle_case(type_count, eaten_count, ratios, eaten):
    total = sum(ratios)
    counts = [0] * type_count
    for sweet in eaten:
        counts[sweet - 1] += 1
    if sum(counts) % total == 0:
        return "forever"
    target = (sum(counts) // total + 1) * total
    start = sum(counts)

    @lru_cache(maxsize=None)
    def search(count_tuple):
        current = sum(count_tuple)
        best = current
        for index, ratio in enumerate(ratios):
            updated = list(count_tuple)
            updated[index] += 1
            newer = current + 1
            if newer % total == 0:
                return target
            okay = True
            for pos, weight in enumerate(ratios):
                if abs(newer * weight - updated[pos] * total) >= total:
                    okay = False
                    break
            if not okay:
                continue
            reached = search(tuple(updated))
            if reached > best:
                best = reached
            if best == target:
                break
        return best

    reached = search(tuple(counts))
    if reached >= target:
        return "forever"
    return str(reached - start)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    pos = 0
    answers = []
    while pos < len(tokens):
        type_count = tokens[pos]
        eaten_count = tokens[pos + 1]
        pos += 2
        ratios = tokens[pos:pos + type_count]
        pos += type_count
        eaten = tokens[pos:pos + eaten_count]
        pos += eaten_count
        answers.append(oracle_case(type_count, eaten_count, ratios, eaten))
    return "\n".join(answers) + "\n"


SAMPLE = """6 5
2 1 6 3 5 3
1 2 5 3 5
6 4
2 1 6 3 5 3
1 2 5 3
"""
SAMPLE_OUT = """1
forever
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 0\n1\n\n") == "forever\n"
assert oracle("2 0\n1 1\n\n") == "forever\n"
assert oracle("4 0\n3 1 1 1\n\n") == "forever\n"
assert oracle("2 1\n1 2\n2\n") == "forever\n"


def random_history(rng, ratios, count):
    total = sum(ratios)
    counts = [0] * len(ratios)
    history = []
    for _ in range(count):
        choices = []
        current = sum(counts)
        for index, ratio in enumerate(ratios):
            updated = list(counts)
            updated[index] += 1
            newer = current + 1
            if all(abs(newer * weight - updated[pos] * total) < total
                   for pos, weight in enumerate(ratios)):
                choices.append(index)
        if not choices:
            break
        chosen = rng.choice(choices)
        counts[chosen] += 1
        history.append(chosen + 1)
    return history


def case_text(ratios, history):
    lines = [f"{len(ratios)} {len(history)}", " ".join(str(x) for x in ratios)]
    if history:
        lines.append(" ".join(str(x) for x in history))
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = "".join(case_text(ratios, history) for ratios, history in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([1], []), ([1, 1], []), ([3, 1, 1, 1], []), ([2, 1], [1])])
    rng = random.Random(20261126)
    wide = []
    for _ in range(6):
        ratios = [rng.randint(1, 5) for _ in range(rng.randint(2, 6))]
        wide.append((ratios, random_history(rng, ratios, rng.randint(0, 8))))
    write("3_wide", wide)
    rng = random.Random(20261127)
    random_cases = []
    for _ in range(10):
        ratios = [rng.randint(1, 4) for _ in range(rng.randint(1, 5))]
        random_cases.append((ratios, random_history(rng, ratios, rng.randint(0, 7))))
    write("4_random", random_cases)
    rng = random.Random(20261128)
    io_cases = []
    for _ in range(40):
        ratios = [rng.randint(1, 6) for _ in range(rng.randint(1, 5))]
        io_cases.append((ratios, random_history(rng, ratios, rng.randint(0, 6))))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([2, 1, 6, 3, 5, 3], [1, 2, 5, 3, 5]),
                   ([2, 1, 6, 3, 5, 3], [1, 2, 5, 3])])
build()
