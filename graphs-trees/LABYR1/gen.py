import random
import sys
from collections import deque


def neighbours(cells, columns, rows):
    result = []
    for index in cells:
        column = index % columns
        if column > 0 and cells[index - 1]:
            result.append((index - 1, index))
        if column + 1 < columns and cells[index + 1]:
            result.append((index + 1, index))
        if index >= columns and cells[index - columns]:
            result.append((index - columns, index))
        if index + columns < len(cells) and cells[index + columns]:
            result.append((index + columns, index))
    return result


def bfs_farthest(cells, start, columns, rows):
    seen = [-1] * len(cells)
    seen[start] = 0
    pending = deque([start])
    far = start
    while pending:
        current = pending.popleft()
        column = current % columns
        if column > 0 and cells[current - 1] and seen[current - 1] < 0:
            seen[current - 1] = seen[current] + 1
            pending.append(current - 1)
        if column + 1 < columns and cells[current + 1] and seen[current + 1] < 0:
            seen[current + 1] = seen[current] + 1
            pending.append(current + 1)
        if current >= columns and cells[current - columns] and seen[current - columns] < 0:
            seen[current - columns] = seen[current] + 1
            pending.append(current - columns)
        if current + columns < len(cells) and cells[current + columns] and seen[current + columns] < 0:
            seen[current + columns] = seen[current] + 1
            pending.append(current + columns)
        if seen[current] > seen[far]:
            far = current
    return far, seen[far]


def expected(data):
    tokens = data.split()
    position = 0
    cases = int(tokens[position]); position += 1
    out = []
    for _ in range(cases):
        columns = int(tokens[position]); rows = int(tokens[position + 1]); position += 2
        lines = tokens[position:position + rows]; position += rows
        cells = []
        for line in lines:
            for char in line:
                cells.append(1 if char == "." else 0)
        free = [index for index, value in enumerate(cells) if value]
        if not free:
            out.append("Maximum rope length is 0.\n")
            continue
        if len(free) <= 300:
            best = 0
            for start in free:
                far, distance = bfs_farthest(cells, start, columns, rows)
                if distance > best:
                    best = distance
            out.append("Maximum rope length is {}.\n".format(best))
        else:
            far, first = bfs_farthest(cells, free[0], columns, rows)
            second_far, second = bfs_farthest(cells, far, columns, rows)
            out.append("Maximum rope length is {}.\n".format(second))
    return "".join(out)


SAMPLE = """2
3 3
###
#.#
###
7 6
#######
#.#.###
#.#.###
#.#.#.#
#.....#
#######
"""


def perfect_maze(rng, cells_x, cells_y):
    walls = [[1] * (2 * cells_x + 1) for _ in range(2 * cells_y + 1)]
    for y in range(cells_y):
        for x in range(cells_x):
            walls[2 * y + 1][2 * x + 1] = 0
    visited = [[False] * cells_x for _ in range(cells_y)]
    stack = [(0, 0)]
    visited[0][0] = True
    while stack:
        x, y = stack[-1]
        options = []
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < cells_x and 0 <= ny < cells_y and not visited[ny][nx]:
                options.append((nx, ny, dx, dy))
        if not options:
            stack.pop()
            continue
        nx, ny, dx, dy = rng.choice(options)
        walls[2 * y + 1 + dy][2 * x + 1 + dx] = 0
        visited[ny][nx] = True
        stack.append((nx, ny))
    return walls


def random_grid(rng, columns, rows):
    lines = []
    for y in range(rows):
        line = []
        for x in range(columns):
            edge = x == 0 or y == 0 or x == columns - 1 or y == rows - 1
            line.append("#" if (edge or rng.random() < 0.25) else ".")
        lines.append("".join(line))
    return lines


def case_lines(columns, rows, lines):
    return ["{} {}".format(columns, rows)] + lines


def one_random(rng):
    cells_x = rng.randint(3, 18)
    cells_y = rng.randint(3, 18)
    return maze_case(rng, cells_x, cells_y)


def corridor():
    rows = 21
    columns = 11
    grid = [["#"] * columns for _ in range(rows)]
    for row in range(rows):
        column = 1 if (row // 2) % 2 == 0 else columns - 2
        grid[row][column] = "."
        if row % 2 == 1 and row + 1 < rows:
            grid[row][columns // 2] = "."
    for row in range(1, rows, 2):
        for column in range(1, columns - 1):
            grid[row][column] = "."
    for row in range(rows):
        grid[row][1 if row % 2 == 0 else columns - 2] = "."
    return case_lines(columns, rows, ["".join(line) for line in grid])


def all_rocks():
    return case_lines(4, 4, ["####"] * 4)


def single_free():
    return case_lines(5, 5, ["#####", "#####", "##.##", "#####", "#####"])


def open_room():
    rows = ["#" + "." * 18 + "#"]
    rows = ["####################"] + [row for row in [rows[0]] * 8] + ["####################"]
    return case_lines(20, 10, rows)


def maze_case(rng, cells_x, cells_y):
    walls = perfect_maze(rng, cells_x, cells_y)
    lines = ["".join("#" if value else "." for value in row) for row in walls]
    return case_lines(len(walls[0]), len(walls), lines)


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "write"
    if mode == "expected":
        sys.stdout.write(expected(sys.stdin.read()))
    elif mode == "write":
        import pathlib
        pathlib.Path("in").mkdir(exist_ok=True)
        pathlib.Path("out").mkdir(exist_ok=True)
        rng = random.Random(7)
        small_cases = [all_rocks(), single_free(), open_room(), corridor()]
        for _ in range(6):
            small_cases.append(one_random(rng))
        data2 = "1\n" + "\n".join(small_cases[0]) + "\n"
        data3 = "{}\n".format(len(small_cases)) + "\n".join("\n".join(case) for case in small_cases) + "\n"
        data4 = "1\n" + "\n".join(maze_case(random.Random(11), 200, 200)) + "\n"
        data5 = "1\n" + "\n".join(maze_case(random.Random(13), 499, 499)) + "\n"
        cases = [("1_sample", SAMPLE), ("2_edges", data2), ("3_random", data3),
                 ("4_maze", data4), ("5_huge", data5)]
        for name, data in cases:
            pathlib.Path("in/{}.txt".format(name)).write_text(data)
            pathlib.Path("out/{}.out".format(name)).write_text(expected(data))
        print("cases written")
    else:
        raise SystemExit("unknown mode")
