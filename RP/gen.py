#!/usr/bin/env python3
from functools import lru_cache
import random
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent
MOD = 65521


def canonical(labels):
    mapping = {}
    result = []
    next_label = 0
    for label in labels:
        if label < 0:
            result.append(-1)
        else:
            if label not in mapping:
                mapping[label] = next_label
                next_label += 1
            result.append(mapping[label])
    return tuple(result)


@lru_cache(maxsize=None)
def transfer_matrix(reach):
    window = reach + 1
    initial = (-1,) * window
    states = [initial]
    indexes = {initial: 0}
    pending = [0]
    adjacency = []
    while pending:
        state_index = pending.pop(0)
        state = states[state_index]
        shifted = list(state[1:]) + [-1]
        fresh = max(shifted) + 1 if max(shifted) >= 0 else 0
        shifted[window - 1] = fresh
        neighbors = []
        for distance in range(1, window):
            slot = window - 1 - distance
            if slot < 0:
                break
            if shifted[slot] >= 0:
                neighbors.append(slot)
        targets = {}
        for mask in range(1 << len(neighbors)):
            labels = shifted[:]
            valid = True
            for position, slot in enumerate(neighbors):
                if mask >> position & 1:
                    if labels[slot] == labels[window - 1]:
                        valid = False
                        break
                    destination = labels[slot]
                    origin = labels[window - 1]
                    labels = [destination if value == origin else value for value in labels]
            if not valid:
                continue
            final = canonical(labels)
            if final[0] >= 0 and sum(1 for value in final if value == final[0]) < 2:
                continue
            targets[final] = targets.get(final, 0) + 1
        row = []
        for target, count in targets.items():
            if target not in indexes:
                indexes[target] = len(states)
                states.append(target)
                pending.append(indexes[target])
            row.append((indexes[target], count))
        adjacency.append(row)
    matrix = np.zeros((len(states), len(states)), dtype=np.int64)
    for state_index, row in enumerate(adjacency):
        for target_index, count in row:
            matrix[state_index, target_index] = count
    return states, matrix, indexes[initial]


def oracle_value(reach, nodes):
    states, matrix, initial = transfer_matrix(reach)
    vector = np.zeros(len(states), dtype=np.int64)
    vector[initial] = 1
    exponent = nodes
    while exponent:
        if exponent & 1:
            vector = (vector @ matrix) % MOD
        matrix = (matrix @ matrix) % MOD
        exponent >>= 1
    total = 0
    for value, state in zip(vector, states):
        active = [label for label in state if label >= 0]
        if active and len(set(active)) == 1:
            total = (total + int(value)) % MOD
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    cursor = 1
    for _ in range(case_count):
        reach = tokens[cursor]
        nodes = tokens[cursor + 1]
        cursor += 2
        answers.append(str(oracle_value(reach, nodes)))
    return "\n".join(answers) + "\n"


def matrix_tree_count(nodes, reach):
    if nodes == 1:
        return 1
    matrix = [[0] * nodes for _ in range(nodes)]
    for row in range(nodes):
        for column in range(nodes):
            if row != column and abs(row - column) <= reach:
                matrix[row][row] += 1
                matrix[row][column] -= 1
    minor = [row[:-1] for row in matrix[:-1]]
    size = len(minor)
    previous = 1
    sign = 1
    for pivot_row in range(size - 1):
        pivot = minor[pivot_row][pivot_row]
        if pivot == 0:
            for swap_row in range(pivot_row + 1, size):
                if minor[swap_row][pivot_row] != 0:
                    minor[pivot_row], minor[swap_row] = minor[swap_row], minor[pivot_row]
                    sign = -sign
                    pivot = minor[pivot_row][pivot_row]
                    break
        for row in range(pivot_row + 1, size):
            for column in range(pivot_row + 1, size):
                minor[row][column] = (minor[row][column] * pivot
                                      - minor[row][pivot_row] * minor[pivot_row][column]) // previous
        previous = pivot
    return sign * minor[size - 1][size - 1]


SAMPLE = """1
3 5
"""
SAMPLE_OUT = """75
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5\n1 1\n2 3\n3 5\n4 5\n5 5\n") == "1\n3\n75\n125\n125\n"
assert all(oracle_value(reach, nodes) == matrix_tree_count(nodes, reach) % MOD
           for reach in range(1, 6) for nodes in range(1, 11))


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(f"{reach} {nodes}\n" for reach, nodes in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(reach, nodes) for reach in range(1, 6)
                      for nodes in (1, 2, 3, reach + 2)])
    write("3_wide", [(reach, nodes) for reach in range(1, 6)
                     for nodes in (1, 5, 8, 18, 46, 100, 999, 100000)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 5), rng.randint(1, 10**12)) for _ in range(100)])
    write("5_io", [(reach, 10**15) for reach in range(1, 6)] * 20)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(3, 5)])
build()
