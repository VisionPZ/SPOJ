import heapq
import random

import numpy as np

INF = 10**9
STATES = 96

SERIALIZE = [
    [-1, 0, 1, 2, 3, -1],
    [4, -1, 5, 6, -1, 7],
    [8, 9, -1, -1, 10, 11],
    [12, 13, -1, -1, 14, 15],
    [16, -1, 17, 18, -1, 19],
    [-1, 20, 21, 22, 23, -1],
]

TOP_FACE = [
    [-1, 0, 0, 0, 0, -1],
    [1, -1, 2, 3, -1, 4],
    [1, 3, -1, -1, 2, 4],
    [1, 2, -1, -1, 3, 4],
    [1, -1, 3, 2, -1, 4],
    [-1, 5, 5, 5, 5, -1],
]

ROTATIONS = [
    [1, 5, 2, 3, 0, 4],
    [4, 0, 2, 3, 5, 1],
    [2, 1, 5, 0, 4, 3],
    [3, 1, 0, 5, 4, 2],
]

ORIENT_CODES = []
for top_position in range(6):
    for front_position in range(6):
        if SERIALIZE[top_position][front_position] >= 0:
            ORIENT_CODES.append((top_position, front_position))
assert len(ORIENT_CODES) == 24

NEXT_ORIENT = [[0] * 4 for _ in range(24)]
COST_FACE = [[0] * 4 for _ in range(24)]
for orient, (top_position, front_position) in enumerate(ORIENT_CODES):
    for move, rotation in enumerate(ROTATIONS):
        new_top = rotation[top_position]
        new_front = rotation[front_position]
        NEXT_ORIENT[orient][move] = SERIALIZE[new_top][new_front]
        COST_FACE[orient][move] = TOP_FACE[new_top][new_front]


def reflect(costs, start_x, target_x):
    if target_x < start_x:
        swapped = costs[:2] + [costs[3], costs[2]] + costs[4:]
        return swapped, start_x - target_x
    return costs[:], target_x - start_x


def build_transfer(costs):
    transfer = np.full((STATES, STATES), INF, dtype=np.int64)
    for state in range(STATES):
        row, orient = divmod(state, 24)
        best = {(0, row, orient): 0}
        queue = [(0, 0, row, orient)]
        while queue:
            distance, column, height, facing = heapq.heappop(queue)
            if best.get((column, height, facing), INF) < distance:
                continue
            for move in range(4):
                next_column, next_row = column, height
                if move == 0:
                    if height == 0:
                        continue
                    next_row -= 1
                elif move == 1:
                    if height == 3:
                        continue
                    next_row += 1
                elif move == 2:
                    if column <= -8:
                        continue
                    next_column -= 1
                else:
                    if column >= 1:
                        continue
                    next_column += 1
                next_orient = NEXT_ORIENT[facing][move]
                next_distance = distance + costs[COST_FACE[facing][move]]
                key = (next_column, next_row, next_orient)
                if next_distance < best.get(key, INF):
                    best[key] = next_distance
                    heapq.heappush(queue, (next_distance, next_column, next_row, next_orient))
        for end_state in range(STATES):
            end_row, end_orient = divmod(end_state, 24)
            transfer[state][end_state] = best.get((1, end_row, end_orient), INF)
    return transfer


def oracle(costs, start_x, start_y, target_x, target_y):
    values, distance = reflect(costs, start_x, target_x)
    start_row, target_row = start_y - 1, target_y - 1
    if distance == 0:
        best = {(0, start_row, 0): 0}
        queue = [(0, 0, start_row, 0)]
        while queue:
            cost, column, row, facing = heapq.heappop(queue)
            if best.get((column, row, facing), INF) < cost:
                continue
            if column == 0 and row == target_row:
                return cost
            for move in (0, 1):
                next_row = row - 1 if move == 0 else row + 1
                if next_row < 0 or next_row >= 4:
                    continue
                next_orient = NEXT_ORIENT[facing][move]
                next_cost = cost + values[COST_FACE[facing][move]]
                key = (0, next_row, next_orient)
                if next_cost < best.get(key, INF):
                    best[key] = next_cost
                    heapq.heappush(queue, (next_cost, 0, next_row, next_orient))
        raise AssertionError('unreachable same-column case')
    transfer = build_transfer(values)
    vector = np.full(STATES, INF, dtype=np.int64)
    vector[24 * start_row] = 0
    while distance > 0:
        if distance & 1:
            vector = np.min(vector[:, None] + transfer, axis=0)
        transfer = np.min(transfer[:, :, None] + transfer[None, :, :], axis=1)
        distance >>= 1
    return int(min(vector[24 * target_row + orient] for orient in range(24)))


assert oracle([1, 2, 8, 3, 1, 4], -1, 1, 0, 2) == 7
for cost in (1, 7, 50):
    assert oracle([cost] * 6, -13, 2, 29, 4) == cost * 44
    assert oracle([cost] * 6, 5, 3, 5, 3) == 0
random_check = [13, 47, 2, 31, 8, 19]
reflected_check = random_check[:2] + [random_check[3], random_check[2]] + random_check[4:]
assert oracle(random_check, 4, 1, -7, 4) == oracle(reflected_check, -4, 1, 7, 4)

rng = random.Random(20032003)


def formatted_case(values, start_x, start_y, target_x, target_y):
    return ' '.join(str(v) for v in values) + '\n' + ' '.join(str(v) for v in (start_x, start_y, target_x, target_y)) + '\n'


def write_pair(name, cases, answers):
    with open('in/' + name + '.txt', 'w') as source:
        source.write(str(len(cases)) + '\n')
        for case in cases:
            source.write(case)
    with open('out/' + name + '.out', 'w') as expected:
        for answer in answers:
            expected.write(str(answer) + '\n')


sample_cases = [formatted_case([1, 2, 8, 3, 1, 4], -1, 1, 0, 2)]
sample_answers = [7]
write_pair('1_sample', sample_cases, sample_answers)

edge_specs = [
    ([1, 1, 1, 1, 1, 1], 3, 2, 3, 2),
    ([50, 50, 50, 50, 50, 50], -1000000000, 1, -1000000000, 4),
    ([1, 50, 1, 50, 1, 50], 0, 1, 0, 4),
    ([5, 5, 5, 5, 5, 5], -7, 3, -7, 1),
    ([2, 3, 4, 5, 6, 7], -1000000000, 4, 1000000000, 1),
    ([7, 6, 5, 4, 3, 2], 1000000000, 1, -1000000000, 4),
]
edge_cases = [formatted_case(*spec) for spec in edge_specs]
edge_answers = [oracle(*spec) for spec in edge_specs]
write_pair('2_edges', edge_cases, edge_answers)

wide_specs = [
    ([1, 2, 8, 3, 1, 4], -1000000000, 1, 1000000000, 4),
    ([50, 1, 50, 1, 50, 1], -1000000000, 4, 1000000000, 1),
    ([31, 17, 49, 2, 8, 44], 1000000000, 2, -1000000000, 3),
]
wide_cases = [formatted_case(*spec) for spec in wide_specs]
wide_answers = [oracle(*spec) for spec in wide_specs]
write_pair('3_wide', wide_cases, wide_answers)

random_specs = []
for _ in range(60):
    values = [rng.randint(1, 50) for _ in range(6)]
    start_x = rng.randint(-1000000000, 1000000000)
    target_x = rng.randint(-1000000000, 1000000000)
    start_y = rng.randint(1, 4)
    target_y = rng.randint(1, 4)
    random_specs.append((values, start_x, start_y, target_x, target_y))
random_cases = [formatted_case(*spec) for spec in random_specs]
random_answers = [oracle(*spec) for spec in random_specs]
write_pair('4_random', random_cases, random_answers)

io_specs = []
for case_index in range(20000):
    face_value = rng.randint(1, 50)
    horizontal = rng.randint(0, 8)
    vertical = rng.randint(0, 3)
    start_x = rng.randint(-1000000000, 1000000000)
    target_x = start_x + horizontal
    start_y = rng.randint(1, 4 - vertical)
    target_y = start_y + vertical
    io_specs.append(([face_value] * 6, start_x, start_y, target_x, target_y))
io_cases = [formatted_case(*spec) for spec in io_specs]
io_answers = [spec[0][0] * (abs(spec[3] - spec[1]) + abs(spec[4] - spec[2]))
              for spec in io_specs]
write_pair('5_io', io_cases, io_answers)
