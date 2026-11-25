#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    position = 1
    answers = []
    for _ in range(case_count):
        source = tokens[position]
        position += 1
        group_size = int(tokens[position])
        produced_size = int(tokens[position + 1])
        position += 2
        runs = []
        current_run = 0
        for character in source:
            if character == "a":
                current_run += 1
            elif current_run:
                runs.append(current_run)
                current_run = 0
        if current_run:
            runs.append(current_run)
        steps = 0
        for length in runs:
            remaining = length
            while remaining >= group_size:
                remaining -= group_size
                steps += 1
        delta = produced_size - group_size
        minimum = len(source)
        maximum = len(source)
        if delta > 0:
            maximum += delta * steps
        elif delta < 0:
            minimum += delta * steps
        answers.append(f"{minimum} {maximum}")
    return "\n".join(answers) + "\n"


def brute_extremes(source, group_size, produced_size):
    seen = {source}
    frontier = [source]
    while frontier:
        following = []
        for current in frontier:
            for start in range(len(current) - group_size + 1):
                if current[start:start + group_size] == "a" * group_size:
                    changed = current[:start] + "b" * produced_size + current[start + group_size:]
                    if changed not in seen:
                        seen.add(changed)
                        following.append(changed)
        frontier = following
    lengths = [len(value) for value in seen]
    return min(lengths), max(lengths)


SAMPLE = """3
abc
1 2
aa
1 2
aba
1 1
"""
SAMPLE_OUT = """3 4
2 4
3 3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\na\n1 1\n") == "1 1\n"
assert oracle("1\naaaa\n5 2\n") == "4 4\n"
assert oracle("1\nbabbbb\n3 1\n") == "6 6\n"
assert brute_extremes("aa", 1, 2) == (2, 4)
assert brute_extremes("aaa", 2, 3) == (3, 4)
rng_check = random.Random(9876)
for _ in range(80):
    source = "".join(rng_check.choice("aab") for _ in range(rng_check.randint(1, 8)))
    group_size = rng_check.randint(1, 3)
    produced_size = rng_check.randint(1, 4)
    low, high = brute_extremes(source, group_size, produced_size)
    text = f"1\n{source}\n{group_size} {produced_size}\n"
    assert oracle(text) == f"{low} {high}\n"


def build_case(sources, settings):
    parts = [str(len(sources))]
    for source, (group_size, produced_size) in zip(sources, settings):
        parts.append(source)
        parts.append(f"{group_size} {produced_size}")
    return "\n".join(parts) + "\n"


def write(name, sources, settings):
    text = build_case(sources, settings)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", ["a", "aaaa", "bbb", "abab"], [(1, 1), (5, 2), (1, 100), (2, 1)])
    write("3_wide", ["a" * 1000 for _ in range(100)], [(rng.randint(1, 9), rng.randint(1, 9)) for _ in range(100)])
    sources = ["".join(rng.choice("aabbc") for _ in range(rng.randint(1, 1000))) for _ in range(50)]
    write("4_random", sources, [(rng.randint(1, 20), rng.randint(1, 20)) for _ in range(50)])
    sources = ["a" * 1000 for _ in range(100)]
    write("5_io", sources, [(1, 100000), (100000, 1)] * 50)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", ["abc", "aa", "aba"], [(1, 2), (1, 2), (1, 1)])
build()
