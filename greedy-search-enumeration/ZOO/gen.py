#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        enclosure_count = tokens[cursor]
        child_count = tokens[cursor + 1]
        cursor += 2
        children = []
        for _ in range(child_count):
            first = tokens[cursor]
            fear_total = tokens[cursor + 1]
            love_total = tokens[cursor + 2]
            cursor += 3
            feared = tokens[cursor:cursor + fear_total]
            cursor += fear_total
            loved = tokens[cursor:cursor + love_total]
            cursor += love_total
            children.append((first, feared, loved))
        best = -1
        for removal_mask in range(1 << enclosure_count):
            happy = 0
            for first, feared, loved in children:
                fear_seen = False
                love_seen = False
                for step in range(5):
                    enclosure = (first + step - 1) % enclosure_count + 1
                    removed = bool(removal_mask & (1 << (enclosure - 1)))
                    if enclosure in feared and removed:
                        fear_seen = True
                    if enclosure in loved and not removed:
                        love_seen = True
                if fear_seen or love_seen:
                    happy += 1
            if happy > best:
                best = happy
        answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE = """2
14 5
2 1 2 4 2 6
3 1 1 6 4
6 1 2 9 6 8
8 1 1 9 12
12 3 0 12 13 2
12 7
1 1 1 1 5
5 1 1 5 7
5 0 3 5 7 9
7 1 1 7 9
9 1 1 9 11
9 3 0 9 11 1
11 1 1 11 1
"""
SAMPLE_OUT = """5
6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n10 1\n1 1 0 3\n") == "1\n"
assert oracle("1\n10 2\n1 0 1 1\n1 0 1 2\n") == "2\n"
assert oracle("1\n10 1\n1 1 1 1 2\n") == "1\n"


def write(name, cases):
    lines = [str(len(cases))]
    for enclosure_count, children in cases:
        lines.append(f"{enclosure_count} {len(children)}")
        for first, feared, loved in children:
            parts = [first, len(feared), len(loved)] + list(feared) + list(loved)
            lines.append(" ".join(str(value) for value in parts))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def case_from_children(enclosure_count, children):
    return (enclosure_count, children)


def build():
    rng = random.Random(20261126)

    def random_case(enclosure_count, max_per_start):
        children = []
        for first in range(1, enclosure_count + 1):
            for _ in range(rng.randint(0, max_per_start)):
                visible = [(first + step - 1) % enclosure_count + 1
                           for step in range(5)]
                chosen = rng.sample(visible, rng.randint(1, len(visible)))
                feared = []
                loved = []
                for enclosure in chosen:
                    if rng.random() < 0.5:
                        feared.append(enclosure)
                    else:
                        loved.append(enclosure)
                children.append((first, feared, loved))
        if not children:
            children.append((1, [1], []))
        return case_from_children(enclosure_count, children)

    write("2_edges", [
        (10, [(1, [1], []), (1, [], [1]), (10, [10, 1], [])]),
        (12, [(9, [], [9, 10, 11, 12, 1]), (12, [11, 12, 1], [])]),
        (11, [(1, [1], [2]), (1, [2], [1]), (11, [11], [1])]),
    ])
    write("3_wide", [random_case(12, 2) for _ in range(3)])
    write("4_random", [random_case(rng.randint(10, 12), 1) for _ in range(8)])
    write("5_io", [random_case(10, 2) for _ in range(12)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
sample_cases = [
    (14, [(2, [4], [2, 6]), (3, [6], [4]), (6, [9], [6, 8]),
          (8, [9], [12]), (12, [12, 13, 2], [])]),
    (12, [(1, [1], [5]), (5, [5], [7]), (5, [], [5, 7, 9]),
          (7, [7], [9]), (9, [9], [11]), (9, [9, 11, 1], []),
          (11, [11], [1])]),
]
write("1_sample", sample_cases)
build()
