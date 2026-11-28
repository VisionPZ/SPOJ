#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def count_occurrences(source, pattern):
    total = 0
    start = source.find(pattern)
    while start != -1:
        total += 1
        start = source.find(pattern, start + 1)
    return total


def oracle(text):
    tokens = text.split()
    query_count = int(tokens[1])
    source = tokens[2]
    queries = tokens[3:3 + query_count]
    return "\n".join(str(count_occurrences(source, query)) for query in queries) + "\n"


SAMPLE = """7 5
acababa
a
bb
caba
aba
karp
"""
SAMPLE_OUT = """4
0
1
2
0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert count_occurrences("aaaa", "aa") == 3
assert count_occurrences("abcabc", "abc") == 2
assert oracle("4 3\nabcd\nx\nab\nbcd\n") == "0\n1\n1\n"


def write(name, source, queries):
    text = f"{len(source)} {len(queries)}\n{source}\n"
    text += "\n".join(queries) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "aaaa", ["a", "aa", "aaa", "aaaa", "aaaaa", "b"])
    rng = random.Random(20261126)
    source = "".join(rng.choice("abc") for _ in range(200))
    queries = []
    for _ in range(60):
        start = rng.randrange(200)
        length = rng.randint(1, 8)
        queries.append(source[start:start + length])
    write("3_wide", source, queries)
    source = "".join(rng.choice("abcdef") for _ in range(120))
    queries = ["".join(rng.choice("abcdef") for _ in range(rng.randint(1, 5))) for _ in range(80)]
    write("4_random", source, queries)
    source = "ab" * 60
    write("5_io", source, ["ab" * 12] * 120 + ["ba" * 12] * 120)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "acababa", ["a", "bb", "caba", "aba", "karp"])
build()
