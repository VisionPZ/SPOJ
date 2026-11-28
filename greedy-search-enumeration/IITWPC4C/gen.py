#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def forms_triangle(first, second, third):
    if first[0] + second[0] != third[0] or first[1] + second[1] != third[1]:
        return False
    return first[0] * second[1] - first[1] * second[0] != 0


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    answers = []
    for _ in range(case_count):
        vector_count = tokens[position]
        position += 1
        vectors = []
        for _ in range(vector_count):
            vectors.append((tokens[position], tokens[position + 1]))
            position += 2
        found = False
        for first_index in range(vector_count):
            for second_index in range(first_index + 1, vector_count):
                for third_index in range(second_index + 1, vector_count):
                    first = vectors[first_index]
                    second = vectors[second_index]
                    third = vectors[third_index]
                    if (forms_triangle(first, second, third)
                            or forms_triangle(first, third, second)
                            or forms_triangle(second, third, first)):
                        found = True
                        break
                if found:
                    break
            if found:
                break
        answers.append("YES" if found else "NO")
    return "\n".join(answers) + "\n"


SAMPLE = """3
5
3 4 3 -4 5 0 6 0 3 5
2
4 5 -4 -5
3
1 2 3 4 -5 -6
"""
SAMPLE_OUT = """YES
NO
NO
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3\n3 4 3 -4 6 0\n") == "YES\n"
assert oracle("1\n3\n1 0 2 0 3 0\n") == "NO\n"
assert oracle("1\n3\n0 0 0 0 1 1\n") == "NO\n"
assert oracle("1\n3\n1 0 0 1 -1 -1\n") == "NO\n"
assert forms_triangle((3, 4), (3, -4), (6, 0)) is True
assert forms_triangle((1, 0), (2, 0), (3, 0)) is False


def write(name, cases):
    parts = [str(len(cases))]
    for vectors in cases:
        parts.append(str(len(vectors)))
        parts.append(" ".join(f"{x_value} {y_value}" for x_value, y_value in vectors))
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    rng_points = lambda count: [(rng.randint(-1000, 1000), rng.randint(-1000, 1000)) for _ in range(count)]
    write("2_edges", [[], [(0, 0)], [(1, 0), (2, 0)]])
    yes_case = [(3, 4), (3, -4), (6, 0)] + rng_points(60)
    write("3_wide", [yes_case, rng_points(80)])
    mixed = []
    for _ in range(12):
        base = rng_points(40)
        if rng.random() < 0.5:
            first = (rng.randint(-300, 300), rng.randint(-300, 300))
            second = (rng.randint(-300, 300), rng.randint(-300, 300))
            if first[0] * second[1] - first[1] * second[0] == 0:
                second = (second[1] + 1, second[0] - 1)
            base.extend([first, second, (first[0] + second[0], first[1] + second[1])])
        mixed.append(base)
    write("4_random", mixed)
    write("5_io", [[(3, 4), (3, -4), (6, 0)] + rng_points(57) for _ in range(20)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[(3, 4), (3, -4), (5, 0), (6, 0), (3, 5)],
                   [(4, 5), (-4, -5)],
                   [(1, 2), (3, 4), (-5, -6)]])
build()
