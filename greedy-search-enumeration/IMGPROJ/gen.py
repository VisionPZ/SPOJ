#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    image_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(image_count):
        width = tokens[cursor]
        height = tokens[cursor + 1]
        cursor += 2
        rows = []
        for _ in range(height):
            row = []
            while len(row) < width:
                run_length = tokens[cursor]
                intensity = tokens[cursor + 1]
                cursor += 2
                row.extend([intensity] * run_length)
            rows.append(row)
        diagonal_sums = [0] * (width + height - 1)
        for row_index, row in enumerate(rows):
            for column_index, intensity in enumerate(row):
                diagonal_sums[row_index + column_index] += intensity
        runs = []
        for value in diagonal_sums:
            if runs and runs[-1][1] == value:
                runs[-1][0] += 1
            else:
                runs.append([1, value])
        answers.append(" ".join(f"{length} {value}" for length, value in runs))
    return "\n".join(answers) + "\n"


SAMPLE = """2

3 3
1 1 1 2 1 3
1 1 1 2 1 3
1 3 1 2 1 1

3 2
3 1
3 1
"""
SAMPLE_OUT = """1 1 1 3 1 8 1 5 1 1
1 1 2 2 1 1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n1 7\n") == "1 7\n"
assert oracle("1\n3 1\n3 0\n") == "3 0\n"
assert oracle("1\n2 2\n1 5 1 5\n1 5 1 5\n") == "1 5 1 10 1 5\n"
assert oracle("1\n1 3\n1 1\n1 2\n1 3\n") == "1 1 1 2 1 3\n"


def write(name, images):
    chunks = [str(len(images)), ""]
    for width, height, rows in images:
        chunks.append(f"{width} {height}")
        for row in rows:
            chunks.append(" ".join(f"{length} {value}" for length, value in row))
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_image(rng, width, height):
    rows = []
    for _ in range(height):
        row = []
        remaining = width
        while remaining > 0:
            length = min(remaining, rng.randint(1, max(1, width // 3)))
            row.append((length, rng.randint(0, 255)))
            remaining -= length
        rows.append(row)
    return width, height, rows


def build():
    write("2_edges", [(1, 1, [[(1, 0)]]), (2, 1, [[(1, 255), (1, 0)]]),
                      (1, 3, [[(1, 1)], [(1, 2)], [(1, 3)]])])
    rng = random.Random(20261126)
    write("3_wide", [random_image(rng, 80, 20)])
    write("4_random", [random_image(rng, rng.randint(1, 60), rng.randint(1, 30))
                       for _ in range(4)])
    write("5_io", [random_image(rng, 100, 20) for _ in range(10)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
