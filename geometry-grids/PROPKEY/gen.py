import os
import random

BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def solve_case(key_rows, lock_rows):
    key_height = len(key_rows)
    key_width = len(key_rows[0])
    lock_depth = len(lock_rows)
    lock_width = len(lock_rows[0])
    if key_width > lock_width:
        return "The key falls to depth 0."
    offset_count = lock_width - key_width + 1

    def fits(depth, offset):
        top_row = depth - key_height
        for key_row_index in range(key_height):
            lock_row_index = top_row + key_row_index
            if 0 <= lock_row_index < lock_depth:
                key_row = key_rows[key_row_index]
                lock_row = lock_rows[lock_row_index]
                for col in range(key_width):
                    if key_row[col] == '#':
                        cell = offset + col
                        if cell < 0 or cell >= lock_width or lock_row[cell] == '#':
                            return False
        return True

    valid_cache = {}

    def valid_offsets(depth):
        if depth not in valid_cache:
            valid_cache[depth] = [fits(depth, offset) for offset in range(offset_count)]
        return valid_cache[depth]

    reach = [True] * offset_count
    for depth in range(1, lock_depth + key_height + 1):
        valid = valid_offsets(depth)
        candidate = [reach[offset] and valid[offset] for offset in range(offset_count)]
        new_reach = [False] * offset_count
        offset = 0
        while offset < offset_count:
            if not valid[offset]:
                offset += 1
                continue
            run_start = offset
            run_reachable = candidate[offset]
            offset += 1
            while offset < offset_count and valid[offset]:
                if candidate[offset]:
                    run_reachable = True
                offset += 1
            if run_reachable:
                for index in range(run_start, offset):
                    new_reach[index] = True
        if not any(new_reach):
            return "The key falls to depth %d." % (depth - 1)
        reach = new_reach
    return "The key can fall through."


def make_key(height, width, rng):
    rows = []
    previous_lower, previous_upper = 0, width - 1
    for row_index in range(height):
        if row_index == 0:
            lower, upper = 0, width - 1
        else:
            lower = rng.randint(previous_lower, previous_upper)
            upper = rng.randint(lower, width - 1)
        row = ''.join('#' if lower <= col <= upper else '.' for col in range(width))
        rows.append(row)
        previous_lower, previous_upper = lower, upper
    return rows


def make_lock(depth, width, rng, density=0.4):
    return [''.join('#' if rng.random() < density else '.' for col in range(width))
            for row in range(depth)]


def encode_case(key_rows, lock_rows):
    lines = ["%d %d" % (len(key_rows), len(key_rows[0]))]
    lines.extend(key_rows)
    lines.append("%d %d" % (len(lock_rows), len(lock_rows[0])))
    lines.extend(lock_rows)
    return "\n".join(lines) + "\n"


def write_pair(name, cases):
    input_text = "%d\n" % len(cases)
    output_lines = []
    for key_rows, lock_rows in cases:
        input_text += encode_case(key_rows, lock_rows)
        output_lines.append(solve_case(key_rows, lock_rows))
    with open(os.path.join(BASE_DIR, "in", name + ".txt"), "w") as handle:
        handle.write(input_text)
    with open(os.path.join(BASE_DIR, "out", name + ".out"), "w") as handle:
        handle.write("\n".join(output_lines) + "\n")


SAMPLE_INPUT = """4
2 4
#.##
###.
3 6
#....#
#....#
#..###
2 3
##.
.##
2 7
#.#.#.#
.#.#.#.
1 1
#
1 10
###....###
3 2
##
.#
.#
1 5
#.#.#
"""

SAMPLE_OUTPUT = """The key falls to depth 2.
The key falls to depth 0.
The key can fall through.
The key falls to depth 2.
"""

FORUM_INPUT = """3
1 2
##
1 1
.
3 3
##.
.#.
.##
1 5
#..##
3 3
##.
.#.
.##
1 5
..###
"""

FORUM_OUTPUT = """The key falls to depth 0.
The key can fall through.
The key falls to depth 0.
"""

assert solve_case(["#"], ["."]) == "The key can fall through."
assert solve_case(["#"], ["#"]) == "The key falls to depth 0."
assert solve_case(["#", "#"], [".", "."]) == "The key can fall through."
assert solve_case(["#", "#"], [".", "#"]) == "The key falls to depth 1."

with open(os.path.join(BASE_DIR, "in", "1_sample.txt"), "w") as handle:
    handle.write(SAMPLE_INPUT)
with open(os.path.join(BASE_DIR, "out", "1_sample.out"), "w") as handle:
    handle.write(SAMPLE_OUTPUT)

forum_cases = [
    (["##"], ["."]),
    (["##.", ".#.", ".##"], ["#..##"]),
    (["##.", ".#.", ".##"], ["..###"]),
]
forum_answers = [solve_case(key, lock) for key, lock in forum_cases]
assert "\n".join(forum_answers) + "\n" == FORUM_OUTPUT

edge_cases = [
    (["##"], ["."]),
    (["#"], ["."]),
    (["#"], ["#"]),
    (["#", "#"], [".", "."]),
    (["###"], ["....."]),
    (["###"], [".##."]),
    (["#"], ["#" * 1000]),
    (["#" for _ in range(100)], ["."]),
    (["#", "#"], [".#"]),
    (["##", "##"], ["..", "##"]),
    (["#..#", "####"], ["....", "#..#", "####"]),
]
write_pair("2_edges", edge_cases)

wide_rng = random.Random(20261123)
wide_cases = [
    (make_key(20, 20, wide_rng), make_lock(20, 1000, wide_rng, 0.35)),
    (["#"], ["#" * 400 + "." + "#" * 599]),
    (["#"], ["." for _ in range(10000)]),
    (["##"], ["." for _ in range(10000)]),
]
write_pair("3_wide", wide_cases)

random_rng = random.Random(987654321)
random_cases = []
for _ in range(150):
    key_height = random_rng.randint(1, 12)
    key_width = random_rng.randint(1, 12)
    lock_depth = random_rng.randint(1, 40)
    lock_width = random_rng.randint(1, 30)
    random_cases.append((make_key(key_height, key_width, random_rng),
                         make_lock(lock_depth, lock_width, random_rng)))
write_pair("4_random", random_cases)

io_cases = []
for index in range(100000):
    if index % 3 == 0:
        io_cases.append((["#"], ["."]))
    elif index % 3 == 1:
        io_cases.append((["#"], ["#"]))
    else:
        io_cases.append((["##"], ["..."]))
write_pair("5_io", io_cases)
