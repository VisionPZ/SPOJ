import os
import random


def positions(route):
    x_positions = [0]
    y_positions = [0]
    current_x = 0
    current_y = 0
    for direction in route:
        if direction == 'N':
            current_y += 1
        elif direction == 'S':
            current_y -= 1
        elif direction == 'E':
            current_x += 1
        elif direction == 'W':
            current_x -= 1
        x_positions.append(current_x)
        y_positions.append(current_y)
    return x_positions, y_positions


def run_lengths(values):
    runs = [1] * len(values)
    for index in range(1, len(values)):
        if values[index] == values[index - 1]:
            runs[index] = runs[index - 1] + 1
    return runs


def brute_force(route):
    x_positions, y_positions = positions(route)
    same_x_run = run_lengths(x_positions)
    same_y_run = run_lengths(y_positions)
    break_count = len(x_positions)
    best = None
    for first in range(break_count):
        for second in range(first + 1, break_count):
            if x_positions[first] == x_positions[second]:
                horizontal = False
                length = abs(y_positions[second] - y_positions[first])
                if same_x_run[second] >= second - first + 1:
                    continue
            elif y_positions[first] == y_positions[second]:
                horizontal = True
                length = abs(x_positions[second] - x_positions[first])
                if same_y_run[second] >= second - first + 1:
                    continue
            else:
                continue
            begin = first
            end = second
            if horizontal:
                direction = 'E' if x_positions[end] > x_positions[begin] else 'W'
            else:
                direction = 'N' if y_positions[end] > y_positions[begin] else 'S'
            candidate = (length, begin, -end, direction)
            if best is None or candidate < best:
                best = candidate
    assert best is not None
    return (best[0], best[1], -best[2], best[3])


def oracle(route):
    x_positions, y_positions = positions(route)
    same_x_run = run_lengths(x_positions)
    same_y_run = run_lengths(y_positions)
    rows = {}
    columns = {}
    for break_index in range(len(x_positions)):
        rows.setdefault(y_positions[break_index], []).append((x_positions[break_index], break_index))
        columns.setdefault(x_positions[break_index], []).append((y_positions[break_index], break_index))
    best = None
    for groups, horizontal in ((rows, True), (columns, False)):
        run_lengths_for_line = same_y_run if horizontal else same_x_run
        for items in groups.values():
            items.sort()
            for left_index in range(len(items)):
                left_coord, left_break = items[left_index]
                for right_index in range(left_index + 1, len(items)):
                    right_coord, right_break = items[right_index]
                    if best is not None and right_coord - left_coord > best[0]:
                        break
                    begin = min(left_break, right_break)
                    end = max(left_break, right_break)
                    if run_lengths_for_line[end] >= end - begin + 1:
                        continue
                    length = right_coord - left_coord
                    if horizontal:
                        direction = 'E' if x_positions[end] > x_positions[begin] else 'W'
                    else:
                        direction = 'N' if y_positions[end] > y_positions[begin] else 'S'
                    candidate = (length, begin, -end, direction)
                    if best is None or candidate < best:
                        best = candidate
    assert best is not None
    result = (best[0], best[1], -best[2], best[3])
    if len(route) <= 400:
        assert result == brute_force(route)
    return result


def random_self_avoiding(length, rng):
    while True:
        visited = {(0, 0)}
        current_x = 0
        current_y = 0
        directions = []
        for unused in range(length):
            choices = ['N', 'S', 'E', 'W']
            rng.shuffle(choices)
            chosen = None
            for direction in choices:
                next_x = current_x
                next_y = current_y
                if direction == 'N':
                    next_y += 1
                elif direction == 'S':
                    next_y -= 1
                elif direction == 'E':
                    next_x += 1
                else:
                    next_x -= 1
                if (next_x, next_y) not in visited:
                    chosen = (direction, next_x, next_y)
                    break
            if chosen is None:
                break
            direction, current_x, current_y = chosen
            visited.add((current_x, current_y))
            directions.append(direction)
        if len(directions) == length:
            return ''.join(directions)


def snake_route(length, width):
    directions = []
    going_east = True
    while len(directions) < length:
        for unused in range(width):
            if len(directions) == length:
                break
            directions.append('E' if going_east else 'W')
        if len(directions) == length:
            break
        directions.append('N')
        going_east = not going_east
    return ''.join(directions[:length])


def spiral_route(length):
    directions = []
    turn_pattern = ['E', 'N', 'W', 'S']
    turn_index = 0
    step_size = 1
    while len(directions) < length:
        for unused in range(step_size):
            if len(directions) == length:
                break
            directions.append(turn_pattern[turn_index % 4])
        turn_index += 1
        if turn_index % 2 == 0:
            step_size += 1
    return ''.join(directions[:length])


def random_snake(length, rng):
    directions = []
    going_east = True
    while len(directions) < length:
        width = rng.randint(1, 24)
        for unused in range(width):
            if len(directions) == length:
                break
            directions.append('E' if going_east else 'W')
        if len(directions) == length:
            break
        directions.append('N')
        going_east = not going_east
    return ''.join(directions[:length])


def shortest_exists(route):
    try:
        oracle(route)
        return True
    except AssertionError:
        return False


def serialize(cases):
    lines = [str(len(cases))]
    for route in cases:
        lines.append(str(len(route)))
        lines.append(route)
    return '\n'.join(lines) + '\n'


def expected(cases):
    output = []
    for route in cases:
        length, begin, end, direction = oracle(route)
        output.append('%d %d %d %s' % (length, begin, end, direction))
    return '\n'.join(output) + '\n'


assert oracle('NENW') == (1, 1, 4, 'N')
assert oracle('NNNENNWWWSSW') == (2, 3, 11, 'W')
assert brute_force('NENW') == (1, 1, 4, 'N')
assert brute_force('NNNENNWWWSSW') == (2, 3, 11, 'W')

sample_cases = ['NNNENNWWWSSW']

rng = random.Random(20231124)

edge_cases = ['NENW', 'ENWN', 'NNENNWWSS']
while len(edge_cases) < 12:
    candidate = random_self_avoiding(rng.randint(4, 30), rng)
    if shortest_exists(candidate):
        edge_cases.append(candidate)

wide_cases = [
    snake_route(250000, 500),
    spiral_route(250000),
]

random_cases = [random_snake(rng.randint(4, 120000), rng) for unused in range(12)]

io_cases = ['NENW'] * 100000

all_groups = {
    '1_sample': sample_cases,
    '2_edges': edge_cases,
    '3_wide': wide_cases,
    '4_random': random_cases,
    '5_io': io_cases,
}

os.makedirs('in', exist_ok=True)
os.makedirs('out', exist_ok=True)
for name, cases in all_groups.items():
    with open(os.path.join('in', name + '.txt'), 'w') as input_file:
        input_file.write(serialize(cases))
    with open(os.path.join('out', name + '.out'), 'w') as output_file:
        output_file.write(expected(cases))
