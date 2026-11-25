#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def common_prefix_length(first, second):
    length = 0
    limit = min(len(first), len(second))
    while length < limit and first[length] == second[length]:
        length += 1
    return length


def pair_cost(stolen, magical, remove_cost, add_cost):
    shared = common_prefix_length(stolen, magical)
    return ((len(stolen) - shared) * remove_cost +
            (len(magical) - shared) * add_cost)


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        remove_cost, add_cost, need, magic_count, stolen_count = map(
            int, tokens[cursor:cursor + 5]); cursor += 5
        magical = tokens[cursor:cursor + magic_count]; cursor += magic_count
        stolen = tokens[cursor:cursor + stolen_count]; cursor += stolen_count
        costs = sorted(min(pair_cost(word, target, remove_cost, add_cost)
                           for target in magical) for word in stolen)
        answers.append(str(sum(costs[:need])))
    return "\n".join(answers) + "\n"


SAMPLE_ONE = """2
2 3 1 1 1
abc
bca
2 3 2 5 4
harry
potter
abcde
qqwweerr
ab
abc
abcd
qqwwweer
putter
"""
SAMPLE_ONE_OUT = """15
5
"""
assert oracle(SAMPLE_ONE) == SAMPLE_ONE_OUT
assert pair_cost("abc", "abcde", 2, 3) == 6
assert pair_cost("abcd", "ab", 2, 3) == 4
assert pair_cost("bca", "abc", 2, 3) == 15


def random_word(rng, length):
    return "".join(rng.choice("abcdefghijklmnopqrstuvwxyz")
                   for _ in range(length))


def write(name, cases):
    parts = [str(len(cases))]
    for remove_cost, add_cost, need, magical, stolen in cases:
        parts.append(f"{remove_cost} {add_cost} {need} {len(magical)} {len(stolen)}")
        parts.extend(magical)
        parts.extend(stolen)
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, 1, 1, ["a"], ["b"]),
        (1000, 1000, 2, ["a", "abc"], ["ab", "abcd", "z"]),
        (2, 3, 3, ["abcde"], ["abc", "abcd", "ab", "xyz"]),
        (1, 500, 1, ["zzzzzzzzzz"], ["zzzz"]),
    ])
    rng = random.Random(20261126)
    wide_magic = [random_word(rng, 100) for _ in range(40)]
    wide_stolen = [word[:rng.randint(1, 100)] for word in wide_magic]
    write("3_wide", [(1000, 1000, 10, wide_magic, wide_stolen)])
    random_cases = []
    for _ in range(4):
        magical = [random_word(rng, rng.randint(1, 20)) for _ in range(30)]
        stolen = [random_word(rng, rng.randint(1, 20)) for _ in range(40)]
        random_cases.append((rng.randint(1, 1000), rng.randint(1, 1000),
                             rng.randint(1, 10), magical, stolen))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20):
        magical = [random_word(rng, rng.randint(1, 30)) for _ in range(20)]
        stolen = [random_word(rng, rng.randint(1, 30)) for _ in range(2000)]
        io_cases.append((rng.randint(1, 1000), rng.randint(1, 1000),
                         rng.randint(1, 200), magical, stolen))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_ONE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_ONE_OUT)
build()
