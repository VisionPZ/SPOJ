import random
from collections import deque

DIRECTIONS = {'N': (0, 1), 'S': (0, -1), 'E': (1, 0), 'W': (-1, 0)}
LEFT = {'N': 'W', 'W': 'S', 'S': 'E', 'E': 'N'}
RIGHT = {'N': 'E', 'E': 'S', 'S': 'W', 'W': 'N'}
OPPOSITE = {'N': 'S', 'S': 'N', 'E': 'W', 'W': 'E'}

SAMPLE_MOVES = list('SSSE' 'NEES' 'EENNNN' 'SSS' 'WW' 'NN' 'WWW' 'N' 'S')


def trace_walk(moves):
    pos_x = 0
    pos_y = 0
    points = [(0, 0)]
    for direction in moves:
        step_x, step_y = DIRECTIONS[direction]
        pos_x += step_x
        pos_y += step_y
        points.append((pos_x, pos_y))
    assert (pos_x, pos_y) == (0, 0)
    return points


def oracle_answer(moves):
    points = trace_walk(moves)
    blocked = set(points)
    xs = [point[0] for point in points]
    ys = [point[1] for point in points]
    min_x, max_x = min(xs) - 2, max(xs) + 2
    min_y, max_y = min(ys) - 2, max(ys) + 2
    reached = set()
    queue = deque()
    for grid_x in range(min_x, max_x + 1):
        for grid_y in (min_y, max_y):
            point = (grid_x, grid_y)
            if point not in blocked and point not in reached:
                reached.add(point)
                queue.append(point)
    for grid_y in range(min_y, max_y + 1):
        for grid_x in (min_x, max_x):
            point = (grid_x, grid_y)
            if point not in blocked and point not in reached:
                reached.add(point)
                queue.append(point)
    while queue:
        grid_x, grid_y = queue.popleft()
        for step_x, step_y in DIRECTIONS.values():
            point = (grid_x + step_x, grid_y + step_y)
            if (min_x <= point[0] <= max_x and min_y <= point[1] <= max_y
                    and point not in blocked and point not in reached):
                reached.add(point)
                queue.append(point)
    interior_count = 0
    for grid_x in range(min_x, max_x + 1):
        for grid_y in range(min_y, max_y + 1):
            point = (grid_x, grid_y)
            if point not in blocked and point not in reached:
                interior_count += 1
    return len(blocked) + interior_count


def boundary_cells(shape):
    result = set()
    for cell_x, cell_y in shape:
        for offset_x in (-1, 0, 1):
            for offset_y in (-1, 0, 1):
                if (offset_x, offset_y) == (0, 0):
                    continue
                if (cell_x + offset_x, cell_y + offset_y) not in shape:
                    result.add((cell_x, cell_y))
                    break
            else:
                continue
            break
    return result


def is_valid_shape(shape):
    start = next(iter(shape))
    colored = {start}
    queue = deque([start])
    while queue:
        cell_x, cell_y = queue.popleft()
        for step_x, step_y in DIRECTIONS.values():
            point = (cell_x + step_x, cell_y + step_y)
            if point in shape and point not in colored:
                colored.add(point)
                queue.append(point)
    if len(colored) != len(shape):
        return False
    xs = [cell[0] for cell in shape]
    ys = [cell[1] for cell in shape]
    min_x, max_x = min(xs) - 1, max(xs) + 1
    min_y, max_y = min(ys) - 1, max(ys) + 1
    outside = set()
    for grid_x in range(min_x, max_x + 1):
        for grid_y in range(min_y, max_y + 1):
            if grid_x in (min_x, max_x) or grid_y in (min_y, max_y):
                outside.add((grid_x, grid_y))
    queue = deque(outside)
    while queue:
        grid_x, grid_y = queue.popleft()
        for step_x, step_y in DIRECTIONS.values():
            point = (grid_x + step_x, grid_y + step_y)
            if (min_x <= point[0] <= max_x and min_y <= point[1] <= max_y
                    and point not in shape and point not in outside):
                outside.add(point)
                queue.append(point)
    for cell_x, cell_y in shape:
        for step_x, step_y in DIRECTIONS.values():
            point = (cell_x + step_x, cell_y + step_y)
            if point not in shape and point not in outside:
                return False
    return True


def walk_from_boundary(boundary, start, first_direction):
    moves = []
    current = start
    direction = first_direction
    for _ in range(200000):
        step_x, step_y = DIRECTIONS[direction]
        following = (current[0] + step_x, current[1] + step_y)
        if following not in boundary:
            return None
        moves.append(direction)
        for candidate in (LEFT[direction], direction, RIGHT[direction], OPPOSITE[direction]):
            delta_x, delta_y = DIRECTIONS[candidate]
            if (following[0] + delta_x, following[1] + delta_y) in boundary:
                direction = candidate
                break
        current = following
        if current == start:
            return moves
    return None


def make_walk(shape):
    assert is_valid_shape(shape)
    boundary = boundary_cells(shape)
    for start in sorted(boundary):
        for first_direction in 'NESW':
            moves = walk_from_boundary(boundary, start, first_direction)
            if moves is None:
                continue
            visited = set()
            pos_x, pos_y = start
            for direction in moves:
                step_x, step_y = DIRECTIONS[direction]
                pos_x += step_x
                pos_y += step_y
                visited.add((pos_x, pos_y))
            if visited != boundary:
                continue
            assert len(moves) <= 20000
            assert oracle_answer(moves) == len(shape)
            return moves
    raise AssertionError('no boundary walk found')


def rectangle(width, height):
    return {(grid_x, grid_y) for grid_x in range(width) for grid_y in range(height)}


def plus_shape():
    return {(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)}


def random_shape(cell_count, rng):
    shape = {(0, 0)}
    for _ in range(cell_count - 1):
        cell_x, cell_y = rng.choice(tuple(shape))
        step_x, step_y = DIRECTIONS[rng.choice('NESW')]
        shape.add((cell_x + step_x, cell_y + step_y))
    return shape


def case_text(moves):
    if not moves:
        return 'P\nK\n'
    return 'P\n' + '\n'.join(moves) + '\nK\n'


def write_case(name, cases):
    with open('in/' + name + '.txt', 'w') as input_file:
        input_file.write(''.join(case_text(moves) for moves in cases))
    with open('out/' + name + '.out', 'w') as output_file:
        output_file.write(''.join(str(oracle_answer(moves)) + '\n' for moves in cases))


assert oracle_answer(SAMPLE_MOVES) == 23
assert oracle_answer(make_walk(rectangle(2, 2))) == 4
assert oracle_answer(make_walk(plus_shape())) == 5
assert oracle_answer(list('EEWW')) == 3

write_case('1_sample', [SAMPLE_MOVES])

edge_shapes = [
    [],
    list('EEWW'),
    make_walk(rectangle(2, 2)),
    make_walk(rectangle(3, 3)),
    make_walk(plus_shape()),
    make_walk(rectangle(1, 7)),
]
write_case('2_edges', edge_shapes)

wide_shapes = [
    make_walk(rectangle(400, 100)),
    make_walk(rectangle(2, 1000)),
]
write_case('3_wide', wide_shapes)

rng = random.Random(20261123)
random_cases = []
while len(random_cases) < 10:
    shape = random_shape(rng.randint(2, 220), rng)
    if not is_valid_shape(shape):
        continue
    moves = make_walk(shape)
    if len(moves) > 1000:
        continue
    random_cases.append(moves)
write_case('4_random', random_cases)

io_shapes = [make_walk(rectangle(300, 300)) for _ in range(10)]
write_case('5_io', io_shapes)

stress_line = list('E' * 9999 + 'W' * 9999)
with open('/tmp/JASIEK_big.txt', 'w') as stress_file:
    stress_file.write(case_text(stress_line) * 10)
