import os
import random
from math import gcd

MAX_FIELDS = 10**9
SIMULATION_LIMIT = 1500000


def simulate_billiard(width, height, start_col, start_row):
    span_x = width - 1
    span_y = height - 1
    pos_x = start_col - 1
    pos_y = start_row - 1
    step_x = 1
    step_y = 1
    start_cell = (pos_x, pos_y)
    visits = {}
    while True:
        next_x = pos_x + step_x
        next_y = pos_y + step_y
        new_step_x = step_x
        new_step_y = step_y
        if next_x < 0 or next_x > span_x:
            new_step_x = -step_x
            next_x = pos_x + new_step_x
        if next_y < 0 or next_y > span_y:
            new_step_y = -step_y
            next_y = pos_y + new_step_y
        pos_x, pos_y = next_x, next_y
        step_x, step_y = new_step_x, new_step_y
        visits[(pos_x, pos_y)] = visits.get((pos_x, pos_y), 0) + 1
        if (pos_x, pos_y) == start_cell:
            return sum(count % 2 for count in visits.values())


def count_by_self_crossings(width, height, start_col, start_row):
    span_x = width - 1
    span_y = height - 1
    along = start_col - 1
    across = start_row - 1
    if across != 0 and across != span_y:
        span_x, span_y = span_y, span_x
        along, across = across, along
    divisor = gcd(span_x, span_y)
    if along % divisor == 0:
        return 2
    reduced_x = span_x // divisor
    reduced_y = span_y // divisor
    period = 2 * span_x * span_y // divisor
    crossings = 2 * reduced_x * reduced_y - reduced_x - reduced_y
    return period - 2 * crossings


def oracle(width, height, start_col, start_row):
    span_x = width - 1
    span_y = height - 1
    period_bound = 2 * span_x * span_y // gcd(span_x, span_y)
    if period_bound <= SIMULATION_LIMIT:
        return simulate_billiard(width, height, start_col, start_row)
    return count_by_self_crossings(width, height, start_col, start_row)


assert simulate_billiard(13, 6, 1, 5) == 2
assert simulate_billiard(10, 7, 1, 5) == 22
assert simulate_billiard(5, 5, 1, 3) == 8
for probe_width in range(3, 26):
    for probe_height in range(3, 26):
        for probe_col in (1, probe_width):
            for probe_row in range(1, probe_height + 1):
                assert count_by_self_crossings(probe_width, probe_height, probe_col, probe_row) == \
                    simulate_billiard(probe_width, probe_height, probe_col, probe_row)
for probe_width in range(3, 26):
    for probe_height in range(3, 16):
        for probe_row in (1, probe_height):
            for probe_col in range(1, probe_width + 1):
                assert count_by_self_crossings(probe_width, probe_height, probe_col, probe_row) == \
                    simulate_billiard(probe_width, probe_height, probe_col, probe_row)


def write_pair(prefix, cases):
    input_lines = [str(len(cases))]
    output_lines = []
    for width, height, start_col, start_row in cases:
        assert width > 2 and height > 2
        assert width * height <= MAX_FIELDS
        assert start_col in (1, width) or start_row in (1, height)
        input_lines.append("%d %d %d %d" % (width, height, start_col, start_row))
        answer = oracle(width, height, start_col, start_row)
        assert answer >= 2 and answer % 2 == 0
        assert answer <= width * height
        output_lines.append(str(answer))
    with open(os.path.join("in", prefix + ".txt"), "w") as input_file:
        input_file.write("\n".join(input_lines) + "\n")
    with open(os.path.join("out", prefix + ".out"), "w") as output_file:
        output_file.write("\n".join(output_lines) + "\n")


sample_cases = [(13, 6, 1, 5), (10, 7, 1, 5)]
edge_cases = [
    (3, 3, 1, 1), (3, 3, 1, 2), (3, 3, 3, 2),
    (5, 5, 1, 3), (5, 5, 3, 1), (4, 4, 4, 4),
    (7, 4, 1, 2), (7, 4, 7, 3), (10, 7, 1, 4),
    (9, 9, 1, 2), (12, 8, 12, 5), (16, 9, 1, 9),
]
wide_cases = [(31622, 31622, 1, 2), (499001, 1001, 1, 500)]

rng = random.Random(20240607)
random_cases = []
while len(random_cases) < 12:
    width = rng.randint(3, 1200)
    height = rng.randint(3, 1200)
    if width * height > MAX_FIELDS:
        continue
    if rng.randrange(2) == 0:
        start_col = rng.choice((1, width))
        start_row = rng.randint(1, height)
    else:
        start_col = rng.randint(1, width)
        start_row = rng.choice((1, height))
    span_x = width - 1
    span_y = height - 1
    if 2 * span_x * span_y // gcd(span_x, span_y) > SIMULATION_LIMIT:
        continue
    random_cases.append((width, height, start_col, start_row))

max_output_cases = []
for index in range(10):
    long_side = 333333332 - index * 2
    start_edge = 1 if index % 2 == 0 else long_side + 1
    max_output_cases.append((3, long_side + 1, 2, start_edge))

write_pair("1_sample", sample_cases)
write_pair("2_edges", edge_cases)
write_pair("3_wide", wide_cases)
write_pair("4_random", random_cases)
write_pair("5_io", max_output_cases)
