#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

LEFT, RIGHT, TOP, BOTTOM = 1, 2, 4, 8
ORIENTS = {
    0: [0],
    1: [LEFT | RIGHT, TOP | BOTTOM],
    2: [LEFT | TOP, TOP | RIGHT, RIGHT | BOTTOM, BOTTOM | LEFT],
}


def oracle(columns):
    top = mid = bot = True
    snake = False
    for a, b, c in columns:
        next_top = ((top and a == 1) or (mid and a == 2 and b == 2) or
                    (bot and a == 2 and b == 1 and c == 2) or
                    (snake and a == 1 and b == 2 and c == 2))
        next_mid = ((top and a == 2 and b == 2) or (mid and b == 1) or
                    (bot and b == 2 and c == 2))
        next_bot = ((top and a == 2 and b == 1 and c == 2) or
                    (mid and b == 2 and c == 2) or (bot and c == 1) or
                    (snake and a == 2 and b == 2 and c == 1))
        next_snake = ((top and a == 1 and b == 2 and c == 2) or
                      (bot and a == 2 and b == 2 and c == 1) or
                      (snake and a == 1 and b == 1 and c == 1))
        top, mid, bot, snake = next_top, next_mid, next_bot, next_snake
    return top or mid or bot


def brute(columns):
    count = len(columns)
    choices = [ORIENTS[block_type] for column in columns for block_type in column]
    for combo in itertools.product(*choices):
        parent = list(range(3 * count))

        def find(x):
            while parent[x] != x:
                parent[x] = parent[parent[x]]
                x = parent[x]
            return x

        def union(a, b):
            ra, rb = find(a), find(b)
            if ra != rb:
                parent[ra] = rb

        for col in range(count):
            for row in range(3):
                sides = combo[col * 3 + row]
                cell = col * 3 + row
                if sides & RIGHT and col + 1 < count and combo[(col + 1) * 3 + row] & LEFT:
                    union(cell, (col + 1) * 3 + row)
                if sides & BOTTOM and row + 1 < 3 and combo[col * 3 + row + 1] & TOP:
                    union(cell, col * 3 + row + 1)
        entries = {find(row) for row in range(3) if combo[row] & LEFT}
        for row in range(3):
            if combo[(count - 1) * 3 + row] & RIGHT and find((count - 1) * 3 + row) in entries:
                return True
    return False


def write_case(name, cases):
    lines = [str(len(cases))]
    for columns in cases:
        lines.append(str(len(columns)))
        for column in columns:
            lines.append(f"{column[0]} {column[1]} {column[2]}")
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    answers = ["yes" if oracle(columns) else "no" for columns in cases]
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")


SAMPLE = [[[1, 0, 1], [1, 2, 2], [2, 2, 1], [2, 2, 1], [2, 2, 1], [1, 2, 2]]]

assert oracle(SAMPLE[0]) is True
assert brute(SAMPLE[0][:2]) == oracle(SAMPLE[0][:2])
assert oracle([[0, 0, 0]]) is False
assert oracle([[1, 1, 1]]) is True
assert oracle([[2, 2, 0]]) is True
assert oracle([[2, 0, 0]]) is False
assert oracle([[0, 0, 0], [1, 1, 1]]) is False
assert oracle([[1, 1, 1], [0, 0, 0]]) is False

random.seed(139)
for _ in range(80):
    small = [[random.randint(0, 2) for _ in range(3)] for _ in range(random.randint(1, 2))]
    assert oracle(small) == brute(small), small

def state_trace(columns):
    top = mid = bot = True
    snake = False
    trace = [(int(top), int(mid), int(bot), int(snake))]
    for a, b, c in columns:
        next_top = ((top and a == 1) or (mid and a == 2 and b == 2) or
                    (bot and a == 2 and b == 1 and c == 2) or
                    (snake and a == 1 and b == 2 and c == 2))
        next_mid = ((top and a == 2 and b == 2) or (mid and b == 1) or
                    (bot and b == 2 and c == 2))
        next_bot = ((top and a == 2 and b == 1 and c == 2) or
                    (mid and b == 2 and c == 2) or (bot and c == 1) or
                    (snake and a == 2 and b == 2 and c == 1))
        next_snake = ((top and a == 1 and b == 2 and c == 2) or
                      (bot and a == 2 and b == 2 and c == 1) or
                      (snake and a == 1 and b == 1 and c == 1))
        top, mid, bot, snake = next_top, next_mid, next_bot, next_snake
        trace.append((int(top), int(mid), int(bot), int(snake)))
    return trace


print("worked example state trace:",
      " ".join("".join(str(bit) for bit in state) for state in state_trace(SAMPLE[0])))


def build():
    edge_columns = [
        [[0, 0, 0]],
        [[1, 1, 1]],
        [[2, 2, 0]],
        [[2, 0, 0]],
        [[0, 0, 0], [0, 0, 0]],
        [[1, 0, 0], [0, 0, 0]],
        [[2, 2, 2]],
        [[2, 2, 2], [2, 2, 2]],
        [[1, 1, 1], [1, 1, 1], [1, 1, 1]],
        [[0, 1, 0], [0, 1, 0], [0, 1, 0]],
        [[2, 1, 2], [2, 1, 2]],
        [[1, 2, 2], [2, 2, 1], [1, 2, 2]],
        [[1, 2, 2], [1, 1, 1], [1, 1, 1], [2, 2, 1]],
        [[2, 2, 1], [1, 1, 1], [1, 1, 1], [1, 2, 2]],
    ]
    write_case("2_edges", edge_columns)

    full = 200000
    write_case("3_wide", [
        [[1, 1, 1] for _ in range(full)],
        [[0, 0, 0] for _ in range(full)],
        [[2, 2, 2] for _ in range(full)],
        [[2, 2, 1] if i % 2 == 0 else [1, 1, 1] for i in range(full)],
    ])

    random.seed(2026)
    random_cases = []
    for _ in range(60):
        length = random.randint(1, 3000)
        random_cases.append([[random.randint(0, 2) for _ in range(3)] for _ in range(length)])
    write_case("4_random", random_cases)

    random.seed(90210)
    io_cases = [[[random.randint(0, 2) for _ in range(3)]] for _ in range(700000)]
    write_case("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", SAMPLE)
build()
