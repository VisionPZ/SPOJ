#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def render(cases):
    lines = [str(len(cases))]
    for rows in cases:
        lines.append(str(len(rows)))
        for row in rows:
            lines.append(" ".join(str(value) for value in row))
    return "\n".join(lines) + "\n"


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        row_count = int(tokens[cursor]); cursor += 1
        sums = [0] * row_count
        for row_index in range(row_count):
            row = [int(tokens[cursor + column_index])
                   for column_index in range(row_index + 1)]
            cursor += row_index + 1
            if row_index == 0:
                sums[0] = row[0]
            else:
                updated = []
                for column_index in range(row_index + 1):
                    left = sums[column_index - 1] if column_index > 0 else -1
                    right = sums[column_index] if column_index < row_index else -1
                    updated.append(row[column_index] + max(left, right))
                sums = updated
        answers.append(str(max(sums)))
    return "\n".join(answers) + "\n"


def worked_example(rows):
    values = [value for row in rows for value in row]
    print("start", values)
    row_index = len(rows) - 2
    while row_index >= 0:
        start = row_index * (row_index + 1) // 2
        for column_index in range(row_index + 1):
            values[start + column_index] += max(
                values[start + row_index + 1 + column_index],
                values[start + row_index + 2 + column_index])
        print("k=", row_index, values)
        row_index -= 1
    print("answer:", values[0])


def brute(rows):
    best = -1

    def walk(row_index, column_index, total):
        nonlocal best
        total += rows[row_index][column_index]
        if row_index == len(rows) - 1:
            best = max(best, total)
            return
        walk(row_index + 1, column_index, total)
        walk(row_index + 1, column_index + 1, total)

    walk(0, 0, 0)
    return best


SAMPLE_CASES = [
    [[1], [2, 1], [1, 2, 3]],
    [[1], [1, 2], [4, 1, 2], [2, 3, 1, 1]],
]
SAMPLE_INPUT = render(SAMPLE_CASES)
SAMPLE_OUTPUT = "5\n9\n"
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert brute([[7]]) == 7
assert oracle(render([[[99] * (r + 1) for r in range(99)]])) == "9801\n"

random.seed(71)
for _ in range(300):
    row_count = random.randint(1, 7)
    rows = [[random.randint(0, 99) for _ in range(r + 1)]
            for r in range(row_count)]
    assert oracle(render([rows])).strip() == str(brute(rows))


def write(name, cases):
    input_text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def full(value):
    return [[value] * (r + 1) for r in range(99)]


def build():
    write("2_edges", [
        [[0]],
        [[99]],
        [[0], [0, 0]],
        [[99], [99, 99]],
        [[1], [0, 0], [0, 0, 0]],
        [[0], [99, 0], [0, 99, 0]],
        full(0),
        full(99),
    ])

    write("3_wide", [
        full(99),
        full(0),
        [[99 if (r + c) % 2 == 0 else 0 for c in range(r + 1)]
         for r in range(99)],
        [[99 - r for _ in range(r + 1)] for r in range(99)],
    ])

    random.seed(2026)
    write("4_random", [
        [[random.randint(0, 99) for _ in range(r + 1)]
         for r in range(random.randint(1, 99))]
        for _ in range(800)
    ])

    random.seed(31337)
    write("5_io", [full(99) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_CASES)
build()
worked_example(SAMPLE_CASES[0])
