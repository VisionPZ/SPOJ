#!/usr/bin/env python3
import bisect
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def rects_overlap(first, second):
    return first[0] < second[2] and first[2] > second[0] and first[1] < second[3] and first[3] > second[1]


def painting_overlaps_spot(painting, x, y, new_width, new_height):
    left, bottom, right, top = painting
    return x < right and x + new_width > left and y < top and y + new_height > bottom


def is_free(paintings, x, y, new_width, new_height):
    for painting in paintings:
        if painting_overlaps_spot(painting, x, y, new_width, new_height):
            return False
    return True


def oracle_case(wall_width, wall_height, paintings, new_width, new_height):
    max_x = wall_width - new_width
    max_y = wall_height - new_height
    y_values = {0, max_y}
    x_values = {0, max_x}
    for left, bottom, right, top in paintings:
        y_values.add(top)
        y_values.add(bottom - new_height)
        x_values.add(right)
        x_values.add(left - new_width)
    y_candidates = sorted(value for value in y_values if 0 <= value <= max_y)
    x_candidates = sorted(value for value in x_values if 0 <= value <= max_x)
    best = None
    for y in y_candidates:
        blocked = [False] * len(x_candidates)
        for left, bottom, right, top in paintings:
            if y < top and y + new_height > bottom:
                start = bisect.bisect_right(x_candidates, left - new_width)
                end = bisect.bisect_left(x_candidates, right)
                for index in range(start, end):
                    blocked[index] = True
        for index, x in enumerate(x_candidates):
            if not blocked[index]:
                spot = (y, x)
                if best is None or spot < best:
                    best = spot
    return best


def brute_case(wall_width, wall_height, paintings, new_width, new_height):
    for y in range(wall_height - new_height + 1):
        for x in range(wall_width - new_width + 1):
            if is_free(paintings, x, y, new_width, new_height):
                return (y, x)
    return None


def solve_text(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    answers = []
    for _ in range(case_count):
        painting_count = tokens[position]
        wall_width = tokens[position + 1]
        wall_height = tokens[position + 2]
        position += 3
        paintings = []
        for _ in range(painting_count):
            paintings.append(tuple(tokens[position:position + 4]))
            position += 4
        new_width = tokens[position]
        new_height = tokens[position + 1]
        position += 2
        best = oracle_case(wall_width, wall_height, paintings, new_width, new_height)
        answers.append("Fail!" if best is None else f"{best[1]} {best[0]}")
    return "\n".join(answers) + "\n"


SAMPLE_INPUT = (
    "2\n"
    "1 10 9\n"
    "5 4 10 9\n"
    "9 5\n"
    "2 10 10\n"
    "5 5 10 10\n"
    "0 0 4 3\n"
    "3 4\n"
)
SAMPLE_OUTPUT = "Fail!\n4 0\n"

assert solve_text(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle_case(10, 10, [], 3, 4) == (0, 0)
assert oracle_case(10, 10, [(0, 0, 10, 10)], 3, 4) is None
assert oracle_case(10, 10, [(0, 0, 4, 3), (5, 5, 10, 10)], 3, 4) == (0, 4)

check_rng = random.Random(731)
for _ in range(400):
    wall_width = check_rng.randint(1, 12)
    wall_height = check_rng.randint(1, 12)
    new_width = check_rng.randint(1, wall_width)
    new_height = check_rng.randint(1, wall_height)
    paintings = []
    for _ in range(check_rng.randint(0, 4)):
        left = check_rng.randint(0, wall_width - 1)
        right = check_rng.randint(left + 1, wall_width)
        bottom = check_rng.randint(0, wall_height - 1)
        top = check_rng.randint(bottom + 1, wall_height)
        candidate = (left, bottom, right, top)
        if all(not rects_overlap(candidate, painting) for painting in paintings):
            paintings.append(candidate)
    expected = brute_case(wall_width, wall_height, paintings, new_width, new_height)
    actual = oracle_case(wall_width, wall_height, paintings, new_width, new_height)
    assert actual == expected, (wall_width, wall_height, paintings, new_width, new_height, actual, expected)


def format_case(case):
    painting_count, wall_width, wall_height, paintings, new_width, new_height = case
    lines = [f"{painting_count} {wall_width} {wall_height}"]
    for left, bottom, right, top in paintings:
        lines.append(f"{left} {bottom} {right} {top}")
    lines.append(f"{new_width} {new_height}")
    return "\n".join(lines) + "\n"


def write_cases(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(format_case(case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(solve_text(input_text))


def grid_paintings(rng, count, wall_width, wall_height):
    columns = 20
    cell_width = wall_width // columns
    cell_height = wall_height // 10
    result = []
    for index in range(count):
        column = index % columns
        row = index // columns
        left = column * cell_width + rng.randint(0, cell_width // 4)
        right = (column + 1) * cell_width - rng.randint(0, cell_width // 4)
        bottom = row * cell_height + rng.randint(0, cell_height // 4)
        top = (row + 1) * cell_height - rng.randint(0, cell_height // 4)
        result.append((left, bottom, right, top))
    return result


def build():
    write_cases("2_edges", [
        (0, 1, 1, [], 1, 1),
        (0, 1000000, 1000000, [], 1000000, 1000000),
        (1, 10, 10, [(0, 0, 10, 10)], 1, 1),
        (1, 10, 10, [(0, 0, 10, 10)], 10, 10),
        (1, 10, 10, [(0, 0, 1, 10)], 1, 1),
        (1, 10, 10, [(0, 0, 10, 1)], 1, 1),
        (1, 10, 10, [(0, 0, 9, 9)], 1, 1),
        (2, 10, 10, [(0, 0, 4, 3), (5, 5, 10, 10)], 3, 4),
        (2, 10, 10, [(0, 0, 10, 3), (0, 7, 10, 10)], 10, 4),
    ])

    rng = random.Random(20261125)
    wide_paintings = grid_paintings(rng, 200, 1000000, 1000000)
    write_cases("3_wide", [
        (200, 1000000, 1000000, wide_paintings, 1, 1),
        (200, 1000000, 1000000, wide_paintings, 1000000, 1000000),
        (200, 1000000, 1000000, wide_paintings, 1000000, 1),
        (0, 1000000, 1000000, [], 1000000, 1),
    ])

    random_cases = []
    for _ in range(30):
        paintings = grid_paintings(rng, 200, 1000000, 1000000)
        new_width = rng.randint(1, 1000000)
        new_height = rng.randint(1, 1000000)
        random_cases.append((200, 1000000, 1000000, paintings, new_width, new_height))
    write_cases("4_random", random_cases)

    io_case = (1, 1000000, 1000000, [(0, 0, 999999, 999999)], 1, 1)
    write_cases("5_io", [io_case] * 40000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
print("generated five test pairs")
