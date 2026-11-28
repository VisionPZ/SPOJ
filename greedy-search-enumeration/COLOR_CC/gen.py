#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    position = 0
    case_count = int(tokens[position])
    position += 1
    answers = []
    for _ in range(case_count):
        nodes = int(tokens[position])
        position += 1
        matrix = tokens[position:position + nodes]
        position += nodes
        palettes = []
        for _ in range(nodes):
            count = int(tokens[position])
            position += 1
            palettes.append([int(value) for value in tokens[position:position + count]])
            position += count
        total = 0
        for assignment in itertools.product(*palettes):
            valid = True
            for left in range(nodes):
                for right in range(left + 1, nodes):
                    if matrix[left][right] == 'Y' and assignment[left] == assignment[right]:
                        valid = False
                        break
                if not valid:
                    break
            if valid:
                total += 1
        answers.append(str(total))
    return "\n".join(answers) + "\n"


SAMPLE = """1
4
NYNN
YNNN
NNNY
NNYN
3 1 2 3
2 4 5
3 4 5 6
3 1 2 3
"""
SAMPLE_OUT = """54
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\nNY\nYN\n1 7\n1 7\n") == "0\n"
assert oracle("1\n2\nNN\nNN\n2 7 8\n1 9\n") == "2\n"
assert oracle("1\n1\nN\n3 4 5 6\n") == "3\n"
assert oracle("1\n3\nNYN\nYNN\nNNN\n2 1 2\n1 1\n2 1 2\n") == "2\n"


def write(name, cases):
    lines = [str(len(cases))]
    for matrix, palettes in cases:
        lines.append(str(len(matrix)))
        lines.extend(matrix)
        for palette in palettes:
            lines.append(str(len(palette)) + " " + " ".join(str(color) for color in palette))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(rng, nodes, palette_size, edge_chance):
    matrix = ["N" * nodes for _ in range(nodes)]
    for left in range(nodes):
        for right in range(left + 1, nodes):
            if rng.random() < edge_chance:
                matrix[left] = matrix[left][:right] + "Y" + matrix[left][right + 1:]
                matrix[right] = matrix[right][:left] + "Y" + matrix[right][left + 1:]
    palettes = []
    for _ in range(nodes):
        colors = rng.sample(range(1, 60), palette_size)
        palettes.append(colors)
    return matrix, palettes


def build():
    write("2_edges", [
        (["NN", "NN"], [[7], [8]]),
        (["NY", "YN"], [[7, 8], [7]]),
        (["NYN", "YNN", "NNN"], [[1, 2], [1], [1, 2]]),
        (["N"], [[3, 4, 5]]),
    ])
    write("3_wide", [
        (["NYYYN", "YNNNN", "YNNNN", "NNNNY", "NNNYN"], [[1, 2], [3], [3], [4, 5], [1, 2]]),
        (["NYNNN", "YNNNN", "NNNNY", "NNYNN", "NNYNN"], [[1, 2, 3], [4], [5, 6], [7, 8], [1, 5]]),
    ])
    rng = random.Random(20261126)
    cases = []
    for _ in range(6):
        nodes = rng.randint(2, 7)
        cases.append(random_case(rng, nodes, rng.randint(1, 3), rng.choice([0.0, 0.2, 0.5])))
    write("4_random", cases)
    write("5_io", [
        (["N" * 6 for _ in range(6)], [[1, 2, 3, 4, 5, 6, 7, 8] for _ in range(6)]),
        (["NYNYNYNY", "YNYNYNYN", "NYNYNYNY", "YNYNYNYN", "NYNYNYNY", "YNYNYNYN", "NYNYNYNY", "YNYNYNYN"],
         [[1, 2], [1, 2], [1, 2], [1, 2], [1, 2], [1, 2], [1, 2], [1, 2]]),
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    (["NYNN", "YNNN", "NNNY", "NNYN"], [[1, 2, 3], [4, 5], [4, 5, 6], [1, 2, 3]]),
])
build()
