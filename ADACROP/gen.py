#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    field_length, harvest_count = tokens[0], tokens[1]
    plants = tokens[2:2 + field_length]
    cursor = 2 + field_length
    answers = []
    for _ in range(harvest_count):
        position, planted_kind = tokens[cursor], tokens[cursor + 1]
        cursor += 2
        before = 0
        for prior in range(position):
            if plants[prior] == planted_kind:
                before += 1
        plants[position] = planted_kind
        answers.append(str(before))
    return "\n".join(answers) + "\n"


SAMPLE_ONE = """5 5
1 2 1 2 1
2 2
4 2
2 3
3 3
4 3
"""
SAMPLE_ONE_OUT = """1
3
0
1
2
"""
SAMPLE_TWO = """10 10
2 3 5 3 9 3 5 2 9 9
7 2
0 5
0 2
1 2
9 2
4 3
8 2
4 2
2 5
3 5
"""
SAMPLE_TWO_OUT = """1
0
0
1
3
1
3
2
0
1
"""
assert oracle(SAMPLE_ONE) == SAMPLE_ONE_OUT
assert oracle(SAMPLE_TWO) == SAMPLE_TWO_OUT
assert oracle("1 1\n5\n0 5\n") == "0\n"
assert oracle("3 2\n7 7 7\n2 1\n0 1\n") == "0\n0\n"


def write(name, plants, queries):
    lines = [f"{len(plants)} {len(queries)}", " ".join(map(str, plants))]
    lines.extend(f"{position} {kind}" for position, kind in queries)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 1, 1, 1, 1],
          [(0, 1), (4, 1), (2, 2), (2, 1), (0, 2)])
    rng = random.Random(20261126)
    wide_plants = [rng.randint(0, 10 ** 9) for _ in range(1000)]
    wide_queries = [(rng.randrange(1000), rng.randint(0, 10 ** 9))
                    for _ in range(1000)]
    write("3_wide", wide_plants, wide_queries)
    random_plants = [rng.randint(0, 40) for _ in range(2000)]
    random_queries = [(rng.randrange(2000), rng.randint(0, 40))
                      for _ in range(2000)]
    write("4_random", random_plants, random_queries)
    io_plants = [rng.randint(0, 1000) for _ in range(3000)]
    io_queries = [(rng.randrange(3000), rng.randint(0, 1000))
                  for _ in range(3000)]
    write("5_io", io_plants, io_queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_ONE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_ONE_OUT)
build()
