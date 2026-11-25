#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def max_subarray_xor(values):
    best = 0
    for start in range(len(values)):
        running = 0
        for index in range(start, len(values)):
            running ^= values[index]
            if running > best:
                best = running
    return best


def oracle(text):
    tokens = text.split()
    position = 0
    result = []
    while position < len(tokens):
        count = int(tokens[position])
        position += 1
        if count == 0:
            break
        lists = {}
        for _ in range(count):
            kind = int(tokens[position])
            first_value = int(tokens[position + 1])
            second_value = int(tokens[position + 2])
            position += 3
            if kind == 2:
                lists.setdefault(first_value, []).append(second_value)
            elif kind == 1:
                for key in [key for key in lists if first_value <= key <= second_value]:
                    del lists[key]
            else:
                best = 0
                for key in lists:
                    if first_value <= key <= second_value:
                        candidate = max_subarray_xor(lists[key])
                        if candidate > best:
                            best = candidate
                result.append(str(best))
    return "\n".join(result) + ("\n" if result else "")


SAMPLE = """14
2 2 1
2 2 2
2 2 1
2 2 1
2 2 2
2 3 1
2 3 2
2 3 7
0 1 2
0 2 3
1 3 3
0 1 3
1 1 3
0 1 3
0
"""
SAMPLE_OUT = """3
7
3
0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n2 5 7\n0 5 5\n0 5 5\n0\n") == "7\n7\n"
assert oracle("3\n2 3 9\n1 3 3\n0 3 3\n0\n") == "0\n"
assert oracle("4\n2 1 4\n2 1 6\n2 1 1\n0 1 1\n0\n") == "7\n"
assert oracle("2\n0 1 100\n0 2 3\n0\n") == "0\n0\n"


def write(name, cases):
    text = "".join(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def render(operations):
    lines = [str(len(operations))]
    for operation in operations:
        lines.append(" ".join(str(value) for value in operation))
    lines.append("0")
    return "\n".join(lines) + "\n"


def build():
    rng = random.Random(20261126)
    edges = [
        (2, 2, 1), (2, 2, 2), (2, 2, 1), (2, 2, 1), (2, 2, 2),
        (2, 3, 1), (2, 3, 2), (2, 3, 7), (0, 1, 2), (0, 2, 3),
        (1, 3, 3), (0, 1, 3), (1, 1, 3), (0, 1, 3),
    ]
    write("2_edges", [render([(2, 1, 0), (0, 1, 1), (1, 1, 1), (0, 1, 1)], )])
    wide_ops = []
    for key in range(1, 21):
        wide_ops.append((2, key, rng.randint(0, 1000000)))
        wide_ops.append((2, key, rng.randint(0, 1000000)))
    wide_ops.append((0, 1, 20))
    wide_ops.append((1, 5, 12))
    wide_ops.append((0, 1, 20))
    write("3_wide", [render(wide_ops)])
    random_ops = []
    for _ in range(80):
        kind = rng.choice([0, 1, 2])
        key = rng.randint(1, 12)
        value = rng.randint(0, 1000000)
        random_ops.append((kind, key, value))
    write("4_random", [render(random_ops), render(edges)])
    many_ops = []
    for _ in range(300):
        kind = rng.choice([0, 0, 2, 2, 2])
        key = rng.randint(1, 30)
        value = rng.randint(0, 1000000)
        many_ops.append((kind, key, value))
    write("5_io", [render(many_ops)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
