#!/usr/bin/env python3
import random
from bisect import bisect_left, bisect_right
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """13 5
abbacccdefgha
1 13
1 10
3 6
11 12
8 12
"""
SAMPLE_OUT = """a 3
c 3
c 2
g 1
d 1
"""


def oracle(input_text):
    tokens = input_text.split()
    cursor = 0
    text_length = int(tokens[cursor])
    cursor += 1
    query_count = int(tokens[cursor])
    cursor += 1
    text = tokens[cursor]
    cursor += 1
    positions = [[] for _ in range(26)]
    for index, character in enumerate(text, 1):
        positions[ord(character) - 97].append(index)
    answers = []
    for _ in range(query_count):
        left = int(tokens[cursor])
        cursor += 1
        right = int(tokens[cursor])
        cursor += 1
        best_letter = 0
        best_count = -1
        for letter in range(26):
            found = bisect_right(positions[letter], right) - bisect_left(positions[letter], left)
            if found > best_count:
                best_count = found
                best_letter = letter
        answers.append("%s %d" % (chr(97 + best_letter), best_count))
    return "\n".join(answers) + "\n"


def write(name, text, queries):
    input_text = "%d %d\n%s\n" % (len(text), len(queries), text)
    input_text += "".join("%d %d\n" % (left, right) for left, right in queries)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    text = "abbacccdefgha"
    input_text = "13 1\n%s\n1 13\n" % text
    print("text abbacccdefgha")
    print("query 1 13")
    print("answer %s" % oracle(input_text).strip())


SAMPLE_TEXT = "abbacccdefgha"
SAMPLE_QUERIES = [(1, 13), (1, 10), (3, 6), (11, 12), (8, 12)]

assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1 1\na\n1 1\n") == "a 1\n"
assert oracle("2 1\nba\n1 2\n") == "a 1\n"
assert oracle("3 1\nzzz\n1 3\n") == "z 3\n"


def build():
    write("2_edges", "cba", [(1, 1), (2, 2), (1, 3), (3, 3), (2, 3)])
    wide_text = ("abcdefghijklmnopqrstuvwxyz" * 3847)[:100000]
    write("3_wide", wide_text, [
        (1, 100000), (1, 1), (100000, 100000), (50000, 50001),
        (1, 26), (99990, 100000),
    ])
    rng = random.Random(7013)
    random_text = "".join(rng.choice("abcdefghijklmnopqrstuvwxyz") for _ in range(2000))
    random_queries = []
    for _ in range(2000):
        left = rng.randint(1, 2000)
        right = rng.randint(left, 2000)
        random_queries.append((left, right))
    write("4_random", random_text, random_queries)
    io_text = "".join(rng.choice("abcdefghijklmnopqrstuvwxyz") for _ in range(100000))
    io_queries = []
    for _ in range(100000):
        left = rng.randint(1, 100000)
        right = rng.randint(left, 100000)
        io_queries.append((left, right))
    write("5_io", io_text, io_queries)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", SAMPLE_TEXT, SAMPLE_QUERIES)
        build()
