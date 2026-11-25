#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ROW_COUNT = 1234
COLUMN_COUNT = 5678
CELL_COUNT = ROW_COUNT * COLUMN_COUNT

SAMPLE_COMMANDS = [
    "R 1 2",
    "Q 1 1",
    "Q 2 1",
    "W 1",
    "W 5679",
    "C 1 2",
    "Q 1 1",
    "Q 2 1",
    "W 1",
    "W 5679",
]
SAMPLE_INPUT = "\n".join(SAMPLE_COMMANDS) + "\n"
SAMPLE_OUTPUT = "5679\n1\n2 1\n1 1\n5680\n2\n2 2\n1 2\n"


def oracle(text, rows=ROW_COUNT, cols=COLUMN_COUNT):
    row_at = list(range(rows + 1))
    column_at = list(range(cols + 1))
    answers = []
    for line in text.splitlines():
        parts = line.split()
        if not parts:
            continue
        command = parts[0]
        if command == "R":
            left, right = int(parts[1]), int(parts[2])
            row_at[left], row_at[right] = row_at[right], row_at[left]
        elif command == "C":
            left, right = int(parts[1]), int(parts[2])
            column_at[left], column_at[right] = column_at[right], column_at[left]
        elif command == "Q":
            row, col = int(parts[1]), int(parts[2])
            answers.append(str((row_at[row] - 1) * cols + column_at[col]))
        elif command == "W":
            value = int(parts[1])
            wanted_row = (value - 1) // cols + 1
            wanted_col = (value - 1) % cols + 1
            answers.append(f"{row_at.index(wanted_row)} {column_at.index(wanted_col)}")
    return "".join(answer + "\n" for answer in answers)


def brute(text, rows, cols):
    matrix = [
        [(row - 1) * cols + col for col in range(1, cols + 1)]
        for row in range(1, rows + 1)
    ]
    answers = []
    for line in text.splitlines():
        parts = line.split()
        if not parts:
            continue
        command = parts[0]
        if command == "R":
            left, right = int(parts[1]), int(parts[2])
            matrix[left - 1], matrix[right - 1] = matrix[right - 1], matrix[left - 1]
        elif command == "C":
            left, right = int(parts[1]), int(parts[2])
            for row_values in matrix:
                row_values[left - 1], row_values[right - 1] = (
                    row_values[right - 1],
                    row_values[left - 1],
                )
        elif command == "Q":
            row, col = int(parts[1]), int(parts[2])
            answers.append(str(matrix[row - 1][col - 1]))
        elif command == "W":
            target = int(parts[1])
            for row_index, row_values in enumerate(matrix, 1):
                for col_index, cell_value in enumerate(row_values, 1):
                    if cell_value == target:
                        answers.append(f"{row_index} {col_index}")
                        break
                else:
                    continue
                break
    return "".join(answer + "\n" for answer in answers)


def small_stream(seed, count, rows, cols):
    rng = random.Random(seed)
    lines = []
    for _ in range(count):
        command = rng.choice(("R", "C", "Q", "W"))
        if command == "R":
            lines.append(f"R {rng.randint(1, rows)} {rng.randint(1, rows)}")
        elif command == "C":
            lines.append(f"C {rng.randint(1, cols)} {rng.randint(1, cols)}")
        elif command == "Q":
            lines.append(f"Q {rng.randint(1, rows)} {rng.randint(1, cols)}")
        else:
            lines.append(f"W {rng.randint(1, rows * cols)}")
    return "\n".join(lines) + "\n"


assert CELL_COUNT == 7006652
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("W 7006652\n") == f"{ROW_COUNT} {COLUMN_COUNT}\n"
check_text = small_stream(731, 120, 4, 5)
assert oracle(check_text, 4, 5) == brute(check_text, 4, 5)


def write(name, commands):
    input_text = "".join(command + "\n" for command in commands)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build_edges():
    middle_row = 617
    middle_column = 2839
    middle_value = (middle_row - 1) * COLUMN_COUNT + middle_column
    return [
        "R 1 1",
        "C 1 1",
        "Q 1 1",
        "Q 1234 5678",
        "W 1",
        "W 7006652",
        "R 1234 1",
        "Q 1 1",
        "Q 1234 5678",
        "W 1",
        "W 7006652",
        "C 5678 1",
        "Q 1 1",
        "Q 1234 5678",
        "W 1",
        "W 7006652",
        "R 617 617",
        "C 2839 2839",
        f"Q {middle_row} {middle_column}",
        f"W {middle_value}",
        "Q 1 5678",
        "Q 1234 1",
        "W 5678",
        "W 7006652",
    ]


def build_wide():
    commands = [
        "Q 1 1",
        "Q 1234 5678",
        "W 1",
        "W 7006652",
        "R 1 1234",
        "Q 1 1",
        "Q 1234 5678",
        "W 1",
        "W 7006652",
        "C 1 5678",
        "Q 1 1",
        "Q 1234 5678",
        "W 1",
        "W 7006652",
        "R 1 1234",
        "C 1 5678",
        "Q 1 1",
        "Q 1234 5678",
        "W 1",
        "W 7006652",
    ]
    for step in range(1, 61):
        row = 1 if step % 2 else ROW_COUNT
        column = 1 if step % 3 else COLUMN_COUNT
        commands.append(f"R {row} {ROW_COUNT - row + 1}")
        commands.append(f"C {column} {COLUMN_COUNT - column + 1}")
        commands.append(f"Q {row} {column}")
        commands.append(f"W {(row - 1) * COLUMN_COUNT + column}")
    return commands


def build_random():
    rng = random.Random(20261125)
    commands = []
    for _ in range(20000):
        command = rng.choice(("R", "C", "Q", "W"))
        if command == "R":
            commands.append(
                f"R {rng.randint(1, ROW_COUNT)} {rng.randint(1, ROW_COUNT)}"
            )
        elif command == "C":
            commands.append(
                f"C {rng.randint(1, COLUMN_COUNT)} {rng.randint(1, COLUMN_COUNT)}"
            )
        elif command == "Q":
            commands.append(
                f"Q {rng.randint(1, ROW_COUNT)} {rng.randint(1, COLUMN_COUNT)}"
            )
        else:
            commands.append(f"W {rng.randint(1, CELL_COUNT)}")
    return commands


def build_io():
    rng = random.Random(31415926)
    commands = []
    for _ in range(150000):
        command = rng.choice(("Q", "Q", "W", "W", "R", "C"))
        if command == "Q":
            row = ROW_COUNT - rng.randint(0, 99)
            column = COLUMN_COUNT - rng.randint(0, 99)
            commands.append(f"Q {row} {column}")
        elif command == "W":
            commands.append(f"W {CELL_COUNT - rng.randint(0, 999)}")
        elif command == "R":
            commands.append(
                f"R {rng.randint(1, ROW_COUNT)} {rng.randint(1, ROW_COUNT)}"
            )
        else:
            commands.append(
                f"C {rng.randint(1, COLUMN_COUNT)} {rng.randint(1, COLUMN_COUNT)}"
            )
    return commands


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_COMMANDS)
write("2_edges", build_edges())
write("3_wide", build_wide())
write("4_random", build_random())
write("5_io", build_io())
