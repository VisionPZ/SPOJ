import os
import random
from collections import deque


def encode_state(first_amount, second_amount, first_capacity, second_capacity):
    if second_amount == 0:
        return first_amount
    if second_amount == second_capacity:
        return first_capacity + 1 + first_amount
    if first_amount == 0:
        return 2 * (first_capacity + 1) + second_amount - 1
    return 2 * (first_capacity + 1) + (second_capacity - 1) + second_amount - 1


def decode_state(state_index, first_capacity, second_capacity):
    if state_index <= first_capacity:
        return state_index, 0
    if state_index <= 2 * first_capacity + 1:
        return state_index - first_capacity - 1, second_capacity
    state_index = state_index - 2 * (first_capacity + 1)
    if state_index < second_capacity - 1:
        return 0, state_index + 1
    return first_capacity, state_index - second_capacity + 2


def oracle(first_capacity, second_capacity, target):
    if target > max(first_capacity, second_capacity):
        return -1
    state_count = 2 * (first_capacity + second_capacity)
    visited = bytearray(state_count)
    start_index = encode_state(0, 0, first_capacity, second_capacity)
    visited[start_index] = 1
    queue = deque([(start_index, 0)])
    while queue:
        state_index, distance = queue.popleft()
        first_amount, second_amount = decode_state(state_index, first_capacity, second_capacity)
        if first_amount == target or second_amount == target:
            return distance
        neighbors = [
            (first_capacity, second_amount),
            (first_amount, second_capacity),
            (0, second_amount),
            (first_amount, 0),
        ]
        poured = min(first_amount, second_capacity - second_amount)
        neighbors.append((first_amount - poured, second_amount + poured))
        poured = min(first_capacity - first_amount, second_amount)
        neighbors.append((first_amount + poured, second_amount - poured))
        for next_first, next_second in neighbors:
            next_index = encode_state(next_first, next_second, first_capacity, second_capacity)
            if not visited[next_index]:
                visited[next_index] = 1
                queue.append((next_index, distance + 1))
    return -1


assert oracle(5, 2, 3) == 2
assert oracle(2, 3, 4) == -1
assert oracle(4, 3, 2) == 4
assert oracle(10, 6, 4) == 2
assert oracle(7, 3, 5) == 8
assert oracle(100, 75, 50) == 4
assert oracle(1, 40000, 1) == 1
assert oracle(6, 4, 5) == -1


def write_case_set(name, cases):
    lines = [str(len(cases))]
    for first_capacity, second_capacity, target in cases:
        lines.append(str(first_capacity))
        lines.append(str(second_capacity))
        lines.append(str(target))
    with open("in/" + name + ".txt", "w") as input_file:
        input_file.write("\n".join(lines) + "\n")
    with open("out/" + name + ".out", "w") as output_file:
        for first_capacity, second_capacity, target in cases:
            output_file.write(str(oracle(first_capacity, second_capacity, target)) + "\n")


os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

write_case_set("1_sample", [(5, 2, 3), (2, 3, 4)])

write_case_set("2_edges", [
    (1, 1, 1),
    (40000, 40000, 40000),
    (2, 3, 4),
    (6, 4, 5),
    (10, 6, 4),
    (7, 3, 5),
    (4, 3, 2),
    (6, 4, 2),
    (100, 75, 50),
    (1, 40000, 1),
    (40000, 39999, 1),
])

write_case_set("3_wide", [
    (40000, 39999, 20000),
    (39999, 40000, 19999),
    (40000, 40000, 20000),
    (1, 40000, 40000),
])

rng = random.Random(20261123)
random_cases = []
for case_index in range(20):
    first_capacity = rng.randint(1, 40000)
    second_capacity = rng.randint(1, 40000)
    target = rng.randint(1, max(first_capacity, second_capacity) + 1)
    random_cases.append((first_capacity, second_capacity, target))
write_case_set("4_random", random_cases)

write_case_set("5_io", [(1000, 999, 500) for case_index in range(100)])

print("generated 5 test sets")
