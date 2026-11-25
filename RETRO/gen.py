#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.splitlines()
    length = int(lines[0])
    first = lines[1][:length]
    second = lines[2][:length]
    count = int(lines[3])
    answers = []
    cursor = 4
    for _ in range(count):
        x, y, span = (int(value) for value in lines[cursor].split())
        cursor += 1
        matches = 0
        for offset in range(span):
            if first[x - 1 + offset] == second[y - 1 + offset]:
                matches += 1
        answers.append(str(matches))
    return "\n".join(answers) + "\n"


SAMPLE = """7
AUGCAAG
GGAUGCG
2
1 3 4
6 1 2
"""
SAMPLE_OUT = """4
1
"""

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\nA\nA\n1\n1 1 1\n") == "1\n"
assert oracle("1\nA\nU\n1\n1 1 1\n") == "0\n"
assert oracle("4\nAAAA\nAAUA\n2\n1 1 4\n2 2 3\n") == "3\n2\n"
assert oracle("5\nAUGCA\nAUGCA\n3\n1 1 5\n2 2 4\n1 3 3\n") == "5\n4\n0\n"


def write_case(name, first, second, queries):
    text = (str(len(first)) + "\n" + first + "\n" + second + "\n" +
            str(len(queries)) + "\n" +
            "".join(f"{x} {y} {span}\n" for x, y, span in queries))
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", "A", "A", [(1, 1, 1), (1, 1, 1), (1, 1, 1)])
    write_case("3_wide", "AUGC" * 250, "AGUC" * 250,
               [(1, 1, 1000), (500, 500, 501), (1, 500, 501)])
    rng = random.Random(20261126)
    letters = "AUGC"
    first = "".join(rng.choice(letters) for _ in range(200))
    second = "".join(rng.choice(letters) for _ in range(200))
    queries = []
    for _ in range(5000):
        span = rng.randint(1, 20)
        x = rng.randint(1, 200 - span + 1)
        y = rng.randint(1, 200 - span + 1)
        queries.append((x, y, span))
    write_case("4_random", first, second, queries)
    first = "".join(rng.choice(letters) for _ in range(1000))
    second = "".join(rng.choice(letters) for _ in range(1000))
    queries = []
    for _ in range(20000):
        span = rng.randint(1, 100)
        x = rng.randint(1, 1000 - span + 1)
        y = rng.randint(1, 1000 - span + 1)
        queries.append((x, y, span))
    write_case("5_io", first, second, queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
