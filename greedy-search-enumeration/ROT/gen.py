#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DEAD = "Hostage is death, destroy the bunker"


def oracle(text):
    lines = text.splitlines()
    cursor = 0
    case_count = int(lines[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        columns, rows, times = (int(value) for value in lines[cursor].split())
        cursor += 1
        grids = []
        for _ in range(times):
            grids.append([line.rstrip() for line in lines[cursor:cursor + rows]])
            cursor += rows
        answers.append(solve_case(columns, rows, times, grids))
    return "\n".join(answers) + "\n"


def solve_case(columns, rows, times, grids):
    layer_size = rows * columns
    state_count = times * layer_size
    start = -1
    target = (-1, -1)
    for layer in range(times):
        for row in range(rows):
            for column in range(columns):
                symbol = grids[layer][row][column]
                if symbol == "X" and start < 0:
                    start = layer * layer_size + row * columns + column
                if symbol == "O" and target[0] < 0:
                    target = (row, column)
    distance = [-1] * state_count
    if start >= 0:
        distance[start] = 0
    for _ in range(state_count):
        changed = False
        for state in range(state_count):
            if distance[state] < 0:
                continue
            row = (state % layer_size) // columns
            column = state % columns
            layer = state // layer_size
            if (row, column) == target:
                continue
            for neighbor_row, neighbor_column in ((row + 1, column), (row - 1, column),
                                                  (row, column + 1), (row, column - 1)):
                if not (0 <= neighbor_row < rows and 0 <= neighbor_column < columns):
                    continue
                for neighbor_layer in (layer - 1, layer, layer + 1):
                    if not (0 <= neighbor_layer < times):
                        continue
                    symbol = grids[neighbor_layer][neighbor_row][neighbor_column]
                    if symbol in "#!":
                        continue
                    neighbor = neighbor_layer * layer_size + neighbor_row * columns + neighbor_column
                    if distance[neighbor] < 0 or distance[neighbor] > distance[state] + 1:
                        distance[neighbor] = distance[state] + 1
                        changed = True
        if not changed:
            break
    best = min(distance[layer * layer_size + target[0] * columns + target[1]]
               for layer in range(times) if distance[layer * layer_size + target[0] * columns + target[1]] >= 0) \
        if any(distance[layer * layer_size + target[0] * columns + target[1]] >= 0 for layer in range(times)) else -1
    return str(best) if best >= 0 else DEAD


SAMPLE = ("2\n3 3 1\nsss\nssX\nOss\n3 3 3\nXss\xa0\xa0\xa0\xa0\xa0\xa0\n"
          "#s!\ns!O\nsss\n#!s\n!sO\nss!\n#s!\nssO\n")
SAMPLE_OUT = "3\n4\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert solve_case(3, 3, 1, [["sss", "ssX", "Oss"]]) == "3"
assert solve_case(3, 3, 3, [["Xss", "#s!", "s!O"], ["sss", "#!s", "!sO"],
                            ["ss!", "#s!", "ssO"]]) == "4"
assert solve_case(2, 2, 1, [["X#", "#O"]]) == DEAD
assert solve_case(2, 2, 1, [["Xs", "sO"]]) == "2"


def random_case(rng, columns, rows, times):
    grids = []
    for layer in range(times):
        grid = [[rng.choice("ssss!") for _ in range(columns)] for _ in range(rows)]
        if layer == 0:
            grid[0][0] = "X"
        grid[rows - 1][columns - 1] = "O"
        grids.append(["".join(row) for row in grid])
    return [f"{columns} {rows} {times}"] + [row for grid in grids for row in grid]


def write(name, cases):
    text = str(len(cases)) + "\n" + "\n".join("\n".join(case) for case in cases) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [["2 2 1", "Xs", "sO"], ["2 2 1", "Xs", "#O"],
                      ["3 3 2", "Xss", "#s!", "s!O", "sss", "#!s", "!sO"]])
    write("3_wide", [random_case(rng, 6, 6, 4) for _ in range(6)])
    write("4_random", [random_case(rng, rng.randint(2, 6), rng.randint(2, 6),
                                    rng.randint(1, 4)) for _ in range(24)])
    write("5_io", [random_case(rng, 5, 5, 3) for _ in range(200)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
