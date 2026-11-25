#!/usr/bin/env python3
import math
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


class Fenwick:
    def __init__(self, size):
        self.size = size
        self.tree = [0] * (size + 1)

    def add(self, index, delta):
        idx = index + 1
        while idx <= self.size:
            self.tree[idx] += delta
            idx += idx & -idx

    def prefix(self, index):
        idx = index + 1
        total = 0
        while idx > 0:
            total += self.tree[idx]
            idx -= idx & -idx
        return total

    def kth(self, rank):
        idx = 0
        step = 1 << (self.size.bit_length() - 1)
        while step:
            nxt = idx + step
            if nxt <= self.size and self.tree[nxt] < rank:
                idx = nxt
                rank -= self.tree[nxt]
            step >>= 1
        return idx


def naive_assign(location_count, empty_location, multiplier, addend, modulus, step):
    excluded = empty_location % location_count
    used = {excluded}
    current = 0
    destinations = []
    for _ in range(1, location_count):
        current = (current * multiplier + addend) % modulus
        chosen = None
        for offset_y in range(location_count):
            for offset_x in range(location_count):
                slot = (current + step * offset_x + offset_y) % location_count
                if slot not in used:
                    chosen = slot
                    break
            if chosen is not None:
                break
        used.add(chosen)
        destinations.append(chosen)
    return destinations


def naive_moves(location_count, empty_location, destinations):
    excluded = empty_location % location_count
    target = [0] * location_count
    for box_number, slot in enumerate(destinations, start=1):
        target[slot] = box_number
    target[excluded] = 0
    start = tuple([0] + list(range(1, location_count)))
    goal = tuple(target)
    queue = deque([(start, 0)])
    seen = {start}
    while queue:
        state, distance = queue.popleft()
        if state == goal:
            return distance
        hole = state.index(0)
        for slot in range(location_count):
            if slot == hole:
                continue
            changed = list(state)
            changed[hole] = changed[slot]
            changed[slot] = 0
            candidate = tuple(changed)
            if candidate not in seen:
                seen.add(candidate)
                queue.append((candidate, distance + 1))
    return -1


def fenwick_assign(location_count, empty_location, multiplier, addend, modulus, step):
    excluded = empty_location % location_count
    class_count = math.gcd(step, location_count)
    slots_per_class = location_count // class_count
    step_per_class = step // class_count
    step_inverse = pow(step_per_class, -1, slots_per_class) if slots_per_class > 1 else 0
    columns = Fenwick(location_count)
    for slot in range(location_count):
        columns.add(slot, 1)
    rows = Fenwick(class_count)
    for class_index in range(class_count):
        rows.add(class_index, slots_per_class)
    excluded_index = (excluded % class_count) * slots_per_class
    excluded_index += (step_inverse * (excluded // class_count)) % slots_per_class
    columns.add(excluded_index, -1)
    rows.add(excluded % class_count, -1)
    destinations = []
    current = 0
    for _ in range(1, location_count):
        current = (current * multiplier + addend) % modulus
        class_of_current = current % class_count
        column_of_current = current // class_count
        before = rows.prefix(class_of_current - 1)
        total = rows.prefix(class_count - 1)
        if before == total:
            free_row = rows.kth(1)
        else:
            free_row = rows.kth(before + 1)
        shift_y = (free_row - class_of_current) % class_count
        carry = (class_of_current + shift_y) // class_count
        start_column = (column_of_current + carry) % slots_per_class
        start_unit = (step_inverse * start_column) % slots_per_class
        row_start = free_row * slots_per_class
        row_end = row_start + slots_per_class
        first_index = row_start + start_unit
        free_before = columns.prefix(first_index - 1)
        free_until_end = columns.prefix(row_end - 1)
        if free_before == free_until_end:
            target_rank = columns.prefix(row_start - 1) + 1
            found_index = columns.kth(target_rank)
        else:
            found_index = columns.kth(free_before + 1)
        unit_index = found_index - row_start
        column_index = (step_per_class * unit_index) % slots_per_class
        destinations.append(free_row + class_count * column_index)
        columns.add(found_index, -1)
        rows.add(free_row, -1)
    return destinations


def solve_case(location_count, empty_location, multiplier, addend, modulus, step):
    destinations = fenwick_assign(location_count, empty_location, multiplier, addend, modulus, step)
    successor = [0] * location_count
    successor[0] = empty_location % location_count
    for box_number, slot in enumerate(destinations, start=1):
        successor[box_number] = slot
    seen = [False] * location_count
    total_moves = 0
    for start in range(location_count):
        if seen[start]:
            continue
        current = start
        length = 0
        holds_initial_empty = False
        while not seen[current]:
            seen[current] = True
            if current == 0:
                holds_initial_empty = True
            length += 1
            current = successor[current]
        if length > 1:
            total_moves += length - 1 if holds_initial_empty else length + 1
    return total_moves


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        values = [int(tokens[cursor + offset]) for offset in range(6)]
        cursor += 6
        answers.append(str(solve_case(*values)))
    return "\n".join(answers) + "\n"


def cross_check():
    rng = random.Random(20261125)
    for _ in range(400):
        location_count = rng.randint(1, 9)
        values = (location_count, rng.randint(0, 2 * location_count),
                  rng.randint(0, 7), rng.randint(0, 7),
                  rng.randint(1, 7), rng.randint(0, 2 * location_count))
        direct = naive_assign(*values)
        tree_based = fenwick_assign(*values)
        if direct != tree_based:
            raise AssertionError(("assignment", values, direct, tree_based))
        if location_count <= 7 and naive_moves(location_count, values[1], direct) != solve_case(*values):
            raise AssertionError(("moves", values, direct))


assert oracle("1\n8 3 5 2 7 4\n") == "6\n"
assert solve_case(8, 3, 5, 2, 7, 4) == 6
assert solve_case(1, 0, 0, 1, 1, 0) == 0
assert naive_assign(8, 3, 5, 2, 7, 4) == [2, 5, 6, 4, 1, 0, 7]
cross_check()


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        "%d %d %d %d %d %d\n" % case for case in cases)
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(input_text))


def build():
    write("1_sample", [(8, 3, 5, 2, 7, 4)])
    write("2_edges", [
        (1, 0, 0, 1, 1, 0),
        (1, 9, 7, 3, 9, 1000000),
        (2, 0, 0, 0, 1, 0),
        (2, 1, 1, 1, 2, 1),
        (2, 2000000, 3, 4, 5, 7),
        (3, 1, 0, 0, 1, 3),
        (3, 2, 2, 1, 3, 1),
        (4, 4, 2, 3, 5, 2),
        (5, 5, 0, 1, 1, 0),
        (6, 0, 1, 1, 6, 6),
        (7, 7, 3, 2, 7, 14),
        (8, 3, 5, 2, 7, 4),
        (10, 9, 0, 5, 10, 0),
        (16, 15, 7, 11, 13, 4),
        (25, 0, 9, 8, 17, 5),
        (31, 62, 5, 0, 1, 31),
        (40, 17, 9999, 9999, 10000, 8),
    ])
    write("3_wide", [
        (1000000, 1, 7919, 104729, 9973, 6),
        (1000000, 999999, 5, 2, 7, 4),
        (1000000, 1234567, 3, 7, 11, 1000000),
        (999999, 0, 9999, 9999, 10000, 500000),
        (2, 1, 1, 1, 2, 1),
        (1, 0, 0, 1, 1, 0),
    ])
    rng = random.Random(20261125)
    random_cases = []
    for _ in range(200):
        location_count = rng.randint(1, 3000)
        random_cases.append((location_count, rng.randint(0, 2 * location_count),
                             rng.randint(0, 10000), rng.randint(0, 10000),
                             rng.randint(1, 10000), rng.randint(0, 2 * location_count)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(7000):
        location_count = rng.randint(40, 140)
        io_cases.append((location_count, rng.randint(0, 2 * location_count),
                         rng.randint(0, 10000), rng.randint(0, 10000),
                         rng.randint(1, 10000), rng.randint(0, 2 * location_count)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
build()
