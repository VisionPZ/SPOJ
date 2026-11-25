#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        object_count = int(tokens[cursor]); cursor += 1
        all_x = []
        all_y = []
        for _ in range(object_count):
            kind = tokens[cursor]; cursor += 1
            if kind == "p":
                pos_x = int(tokens[cursor]); pos_y = int(tokens[cursor + 1])
                cursor += 2
                all_x.append(pos_x)
                all_y.append(pos_y)
            elif kind == "c":
                centre_x = int(tokens[cursor]); centre_y = int(tokens[cursor + 1])
                radius = int(tokens[cursor + 2]); cursor += 3
                all_x.extend((centre_x - radius, centre_x + radius))
                all_y.extend((centre_y - radius, centre_y + radius))
            else:
                first_x = int(tokens[cursor]); first_y = int(tokens[cursor + 1])
                second_x = int(tokens[cursor + 2]); second_y = int(tokens[cursor + 3])
                cursor += 4
                all_x.extend((first_x, second_x))
                all_y.extend((first_y, second_y))
        answers.append("%d %d %d %d" % (min(all_x), min(all_y), max(all_x), max(all_y)))
    return "\n".join(answers) + "\n"


SAMPLE_INPUT = """3
1
p 3 3 

2
c 10 10 20
c 20 20 10

1
l 0 0 100 20

"""
SAMPLE_OUTPUT = """3 3 3 3
-10 -10 30 30
0 0 100 20
"""
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n1\np -1000 1000\n") == "-1000 1000 -1000 1000\n"
assert oracle("1\n1\nc 0 0 5\n") == "-5 -5 5 5\n"
assert oracle("1\n1\nl -4 7 9 -2\n") == "-4 -2 9 7\n"


def build_input(cases):
    lines = [str(len(cases))]
    for objects in cases:
        lines.append(str(len(objects)))
        for obj in objects:
            lines.append(" ".join(str(value) for value in obj))
        lines.append("")
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = build_input(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace():
    print("group 1: point (3, 3) -> xs [3], ys [3]")
    print("group 2: circle (10, 10, 20) -> xs [-10, 30], ys [-10, 30]")
    print("group 2: circle (20, 20, 10) -> xs [10, 30], ys [10, 30]")
    print("group 2 extremes -> min x -10, min y -10, max x 30, max y 30")
    print("group 3: segment (0, 0) to (100, 20) -> xs [0, 100], ys [0, 20]")


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace()
    else:
        (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
        (ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
        edges = [
            [("p", 0, 0)],
            [("p", -1000, -1000), ("p", 1000, 1000)],
            [("c", 0, 0, 1000)],
            [("c", -1000, 1000, 7), ("c", 1000, -1000, 3)],
            [("l", -1000, -1000, 1000, 1000)],
            [("l", 5, -9, 5, -9)],
            [("p", -7, 4), ("c", 2, 3, 6), ("l", -50, 80, 90, -40)],
        ]
        write("2_edges", edges)
        random.seed(2026)
        def random_object():
            kind = random.choice(("p", "c", "l"))
            if kind == "p":
                return (kind, random.randint(-1000, 1000), random.randint(-1000, 1000))
            if kind == "c":
                return (kind, random.randint(-1000, 1000), random.randint(-1000, 1000),
                        random.randint(0, 100))
            return (kind, random.randint(-1000, 1000), random.randint(-1000, 1000),
                    random.randint(-1000, 1000), random.randint(-1000, 1000))
        write("3_wide", [[random_object() for _ in range(99)] for _ in range(10)])
        write("4_random", [[random_object() for _ in range(random.randint(1, 20))]
                           for _ in range(40)])
        write("5_io", [[random_object() for _ in range(99)] for _ in range(99)])
