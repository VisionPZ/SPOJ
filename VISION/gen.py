#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    building_count = tokens[cursor]
    cursor += 1
    heights = tokens[cursor:cursor + building_count]
    cursor += building_count
    query_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(query_count):
        eye_height = tokens[cursor]
        cursor += 1
        best_numerator = None
        best_denominator = 1
        visible = 0
        for position, height in enumerate(heights, 1):
            numerator = height - eye_height
            if best_numerator is None or numerator * best_denominator > best_numerator * position:
                visible += 1
                best_numerator = numerator
                best_denominator = position
        answers.append(str(visible))
    return "\n".join(answers) + "\n"


SAMPLE = """5
2 3 3 3 4
3
3
2
4
"""
SAMPLE_OUT = """3
2
5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n3\n1\n2\n1000000000\n") == "1\n1\n1\n"
assert oracle("3\n5 5 5\n2\n5\n6\n") == "1\n3\n"
assert oracle("4\n1 2 3 4\n3\n1\n100\n1000000000\n") == "4\n4\n4\n"
assert oracle("2\n1000000000 1\n2\n1\n1000000000\n") == "1\n1\n"


def write(name, heights, queries):
    text = str(len(heights)) + "\n" + " ".join(str(value) for value in heights) + "\n"
    text += str(len(queries)) + "\n"
    text += "".join(str(value) + "\n" for value in queries)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1], [1, 2, 1000000000])
    write("3_wide", [1000000000, 999999999, 1000000000, 1, 2, 1000000000],
          [1, 2, 999999999, 1000000000])
    rng = random.Random(20261126)
    write("4_random", [rng.randrange(1, 1000000001) for _ in range(25)],
          [rng.randrange(1, 1000000001) for _ in range(40)])
    write("5_io", [rng.randrange(1, 1000000001) for _ in range(30)],
          [rng.randrange(1, 1000000001) for _ in range(50000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [2, 3, 3, 3, 4], [3, 2, 4])
build()
