#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def directions(corners):
    letters = []
    for index in range(len(corners)):
        first = corners[index]
        second = corners[(index + 1) % len(corners)]
        delta_x = second[0] - first[0]
        delta_y = second[1] - first[1]
        if delta_x > 0:
            letters.append('E')
        elif delta_x < 0:
            letters.append('W')
        elif delta_y > 0:
            letters.append('N')
        else:
            letters.append('S')
    return ''.join(letters)


def build_polygon(rng, grid_size, target_cells):
    while True:
        cells = {(0, 0)}
        while len(cells) < target_cells:
            candidates = set()
            for cell_x, cell_y in cells:
                for delta_x, delta_y in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    neighbor = (cell_x + delta_x, cell_y + delta_y)
                    if 0 <= neighbor[0] < grid_size and 0 <= neighbor[1] < grid_size:
                        if neighbor not in cells:
                            candidates.add(neighbor)
            if not candidates:
                break
            cells.add(rng.choice(sorted(candidates)))
        if len(cells) != target_cells:
            continue

        seen = set()
        stack = [(-1, -1)]
        while stack:
            position = stack.pop()
            if position in seen:
                continue
            seen.add(position)
            pos_x, pos_y = position
            for delta_x, delta_y in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                neighbor = (pos_x + delta_x, pos_y + delta_y)
                if -1 <= neighbor[0] <= grid_size and -1 <= neighbor[1] <= grid_size:
                    if neighbor not in cells:
                        stack.append(neighbor)
        if any((x, y) not in cells and (x, y) not in seen
               for x in range(grid_size) for y in range(grid_size)):
            continue

        edges = []
        for cell_x, cell_y in cells:
            edges.append(((cell_x, cell_y), (cell_x + 1, cell_y)))
            edges.append(((cell_x + 1, cell_y), (cell_x + 1, cell_y + 1)))
            edges.append(((cell_x + 1, cell_y + 1), (cell_x, cell_y + 1)))
            edges.append(((cell_x, cell_y + 1), (cell_x, cell_y)))
        edge_set = set(edges)
        boundary = [edge for edge in edges if (edge[1], edge[0]) not in edge_set]
        outgoing = {}
        for start, end in boundary:
            if start in outgoing:
                outgoing = {}
                break
            outgoing[start] = end
        if not outgoing or len(outgoing) != len(boundary):
            continue

        start_vertex = boundary[0][0]
        cycle = []
        current = start_vertex
        while True:
            cycle.append(current)
            current = outgoing[current]
            if current == start_vertex:
                break
            if len(cycle) > len(boundary):
                break
        if len(cycle) != len(boundary):
            continue

        corners = []
        for index, vertex in enumerate(cycle):
            previous = cycle[index - 1]
            following = cycle[(index + 1) % len(cycle)]
            incoming = (vertex[0] - previous[0], vertex[1] - previous[1])
            outgoing_step = (following[0] - vertex[0], following[1] - vertex[1])
            if incoming != outgoing_step:
                corners.append(vertex)
        if len(corners) < 4 or len(corners) % 2:
            continue
        return corners


def oracle(clockwise, start_index):
    rotated = clockwise[start_index:] + clockwise[:start_index]
    return directions(rotated)


def polygon_text(clockwise, start_index, offset_x, offset_y):
    rotated = clockwise[start_index:] + clockwise[:start_index]
    shuffled = rotated[1:]
    random.shuffle(shuffled)
    ordered = [rotated[0]] + shuffled
    lines = [str(len(ordered))]
    for point_x, point_y in ordered:
        lines.append(f"{point_x + offset_x} {point_y + offset_y}")
    return "\n".join(lines) + "\n\n"


SAMPLE = """4
0 0
2 2
0 2
2 0

6
1 1
2 2
0 1
1 0
0 2
2 0

0
"""
SAMPLE_OUT = """NESW
WNESWN
"""
assert oracle([(0, 0), (0, 2), (2, 2), (2, 0)], 0) == "NESW"
assert oracle([(0, 0), (0, 2), (2, 2), (2, 0)], 2) == "SWNE"
assert oracle([(1, 1), (0, 1), (0, 2), (2, 2), (2, 0), (1, 0)], 0) == "WNESWN"


def write(name, pieces):
    input_parts = []
    output_lines = []
    for corners, start_index, offset_x, offset_y in pieces:
        input_parts.append(polygon_text(corners, start_index, offset_x, offset_y))
        output_lines.append(oracle(corners, start_index))
    input_parts.append("0\n")
    input_text = "".join(input_parts)
    output_text = "\n".join(output_lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


def comb_corners(notch_count):
    corners = [(0, 0), (0, 4)]
    for notch_index in range(notch_count):
        left_x = 1 + 2 * notch_index
        right_x = left_x + 1
        corners.append((left_x, 4))
        corners.append((left_x, 2))
        corners.append((right_x, 2))
        corners.append((right_x, 4))
    corners.append((2 * notch_count + 2, 4))
    corners.append((2 * notch_count + 2, 0))
    return corners


def make_piece(rng, grid_size, cells):
    counter_clockwise = build_polygon(rng, grid_size, cells)
    clockwise = [counter_clockwise[0]] + list(reversed(counter_clockwise[1:]))
    start_index = rng.randrange(len(clockwise))
    offset_x = rng.randint(-30, 30)
    offset_y = rng.randint(-30, 30)
    return clockwise, start_index, offset_x, offset_y


def build():
    write("2_edges", [
        ([(0, 0), (0, 4), (4, 4), (4, 0)], 0, -2, -7),
        ([(0, 0), (0, 4), (1, 4), (1, 1), (3, 1), (3, 4), (4, 4), (4, 0)], 2, 5, -3),
    ])
    rng = random.Random(20261126)
    write("3_wide", [(comb_corners(30), 0, -17, 9)])
    random_pieces = []
    for _ in range(12):
        random_pieces.append(make_piece(rng, 6, rng.randint(3, 20)))
    write("4_random", random_pieces)
    io_pieces = []
    for _ in range(120):
        io_pieces.append(make_piece(rng, 4, rng.randint(1, 5)))
    write("5_io", io_pieces)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
