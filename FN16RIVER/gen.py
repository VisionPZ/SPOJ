#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"


def encode(value):
    if value == 0:
        return "0"
    digits = []
    while value > 0:
        digits.append(ALPHABET[value % 64])
        value //= 64
    return "".join(reversed(digits))


def decode(token):
    value = 0
    for character in token:
        value = value * 64 + ALPHABET.index(character)
    return value


def parse(text):
    tokens = text.split()
    pos = 0
    cases = []
    while pos < len(tokens):
        source_count = int(tokens[pos])
        confluence_count = int(tokens[pos + 1])
        pos += 2
        records = []
        for _ in range(source_count + confluence_count):
            records.append((decode(tokens[pos]), decode(tokens[pos + 1])))
            pos += 2
        cases.append((source_count, confluence_count, records))
    return cases


def oracle_case(source_count, confluence_count, records):
    parents = []
    lengths = []
    for confluence, distance in records:
        parents.append(confluence - 1)
        lengths.append(distance)
    total_nodes = source_count + confluence_count

    def parent_of(node):
        label = parents[node]
        if label == -1:
            return -1
        return source_count + label

    children = {node: [] for node in range(total_nodes)}
    for node in range(total_nodes):
        parent = parent_of(node)
        if parent != -1:
            children[parent].append(node)
    confluences = list(range(source_count, total_nodes))
    choices = [children[node] for node in confluences]
    best = [10**9] * source_count
    for naming in itertools.product(*choices):
        chosen = dict(zip(confluences, naming))
        river_lengths = []
        for source in range(source_count):
            current = source
            total = 0
            while True:
                total += lengths[current]
                downstream = parent_of(current)
                if downstream == -1:
                    break
                if chosen[downstream] != current:
                    break
                current = downstream
            river_lengths.append(total)
        for river in range(source_count):
            rank = 1 + sum(1 for other in range(source_count)
                           if river_lengths[other] > river_lengths[river])
            if rank < best[river]:
                best[river] = rank
    return [str(rank) for rank in best]


def oracle(text):
    answers = []
    for source_count, confluence_count, records in parse(text):
        answers.extend(oracle_case(source_count, confluence_count, records))
    return "\n".join(answers) + "\n"


SAMPLE = """6 2
0 81
2 AZ
2 Ay
1 5F
1 4n
0 Bz
0 5X
0 11
6 3
1 GN
2 fQ
1 CW
3 B6
0 h/
3 CJ
2 1a
0 Qa
0 U
"""
SAMPLE_OUT = """5
2
1
3
4
1
1
1
3
6
1
4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 0\n0 10\n0 20\n") == "2\n1\n"
assert oracle("1 0\n0 10\n") == "1\n"
assert encode(0) == "0" and encode(63) == "/" and decode("Az") == 701
assert len(SAMPLE_OUT.splitlines()) == 12


def random_tree(rng, source_count, confluence_count):
    while True:
        parents = []
        for index in range(confluence_count):
            options = [-1] + list(range(index))
            parents.append(rng.choice(options))
        for _ in range(source_count):
            parents.append(rng.randrange(-1, confluence_count))
        child_counts = [0] * confluence_count
        for parent in parents:
            if parent != -1:
                child_counts[parent] += 1
        if all(count >= 2 for count in child_counts) and -1 in parents:
            break
    lengths = [rng.randint(1, 1000) for _ in range(source_count + confluence_count)]
    confluence_records = [(parent + 1, length)
                          for parent, length in zip(parents[:confluence_count],
                                                    lengths[:confluence_count])]
    source_records = [(parent + 1, length)
                      for parent, length in zip(parents[confluence_count:],
                                                lengths[confluence_count:])]
    return source_records + confluence_records


def case_text(source_count, confluence_count, records):
    lines = [f"{source_count} {confluence_count}"]
    lines.extend(f"{encode(confluence)} {encode(distance)}" for confluence, distance in records)
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = "".join(case_text(*case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(2, 0, [(0, 10), (0, 20)]), (1, 0, [(0, 10)])])
    rng = random.Random(20261126)
    write("3_wide", [(8, 3, random_tree(rng, 8, 3))])
    rng = random.Random(20261127)
    random_cases = []
    for _ in range(3):
        confluence_count = rng.randint(1, 3)
        source_count = rng.randint(2 * confluence_count, 8) if confluence_count else rng.randint(2, 8)
        random_cases.append((source_count, confluence_count,
                             random_tree(rng, source_count, confluence_count)))
    write("4_random", random_cases)
    rng = random.Random(20261128)
    io_cases = []
    for _ in range(6):
        io_cases.append((10, 4, random_tree(rng, 10, 4)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
