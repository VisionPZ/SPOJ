#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = iter(text.split())
    test_count = int(next(tokens))
    lines = []
    for case_index in range(test_count):
        part_count = int(next(tokens))
        balloons = int(next(tokens))
        required = [int(next(tokens)) for _ in range(part_count)]
        query_count = int(next(tokens))
        lines.append(f"Testcase {case_index}:")
        for _ in range(query_count):
            command = next(tokens)
            if command == "A":
                balloons += int(next(tokens))
            elif command == "B":
                part_index = int(next(tokens))
                new_value = int(next(tokens))
                required[part_index] = new_value
            else:
                left = int(next(tokens))
                right = int(next(tokens))
                lines.append(str(balloons - max(required[left:right + 1])))
        lines.append("")
    return "\n".join(lines) + "\n"


SAMPLE = """2
3 11
5 2 4
1
C 0 2
3 11
16 2 17
5
C 0 2
A -2
C 1 2
B 0 0
C 0 1
"""
SAMPLE_OUT = """Testcase 0:
6

Testcase 1:
-6
-8
7

"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 5\n7\n1\nC 0 0\n") == "Testcase 0:\n-2\n\n"
assert oracle("1\n2 10\n0 9\n4\nA -3\nC 0 1\nB 1 0\nC 1 1\n") == "Testcase 0:\n-2\n7\n\n"
assert oracle("1\n3 0\n0 0 0\n1\nC 2 2\n") == "Testcase 0:\n0\n\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build_case(part_count, values, queries):
    lines = [f"{part_count} {sum(values[:2]) if part_count == 2 else 1000}"]
    lines.append(" ".join(str(value) for value in values))
    lines.append(str(len(queries)))
    lines.extend(queries)
    return "\n".join(lines) + "\n"


def build():
    write("2_edges", "1\n1 5\n7\n1\nC 0 0\n")
    write("3_wide", "1\n1000 1000000000\n" + " ".join(["1000000000"] * 1000) + "\n6\n"
          + "C 0 999\nB 0 1\nC 0 999\nA -1000\nC 1 998\nC 500 500\n")
    rng = random.Random(20261126)
    lines = []
    for _ in range(500):
        choice = rng.random()
        if choice < 0.3:
            lines.append(f"A {rng.randint(-1000, 1000)}")
        elif choice < 0.5:
            lines.append(f"B {rng.randint(0, 499)} {rng.randint(0, 10**9)}")
        else:
            left = rng.randint(0, 499)
            right = rng.randint(left, 499)
            lines.append(f"C {left} {right}")
    write("4_random", "1\n500 100000\n" + " ".join(str(rng.randint(0, 10**9)) for _ in range(500))
          + "\n" + str(len(lines)) + "\n" + "\n".join(lines) + "\n")
    io_queries = []
    for _ in range(100000):
        left = rng.randint(0, 9)
        right = rng.randint(left, 9)
        io_queries.append(f"C {left} {right}")
    io_queries = ["C 0 9" if index % 3 == 0 else query for index, query in enumerate(io_queries)]
    write("5_io", "1\n10 1000\n" + " ".join(str(rng.randint(0, 10**9)) for _ in range(10))
          + "\n" + str(len(io_queries)) + "\n" + "\n".join(io_queries) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
