import math
import random

MAX_ANSWER = (1 << 63) - 1
LIMIT = 1000000


def exact_count(marble_count, color_count):
    return math.comb(marble_count - 1, color_count - 1)


def safe_case(marble_count, color_count):
    assert 1 <= color_count <= marble_count <= LIMIT
    radius = min(color_count - 1, marble_count - color_count)
    answer = exact_count(marble_count, color_count)
    assert answer * radius <= MAX_ANSWER
    return (marble_count, color_count)


def try_case(marble_count, color_count):
    if not 1 <= color_count <= marble_count <= LIMIT:
        return None
    radius = min(color_count - 1, marble_count - color_count)
    answer = exact_count(marble_count, color_count)
    if answer * radius > MAX_ANSWER:
        return None
    return (marble_count, color_count)


def emit(name, cases):
    with open("in/" + name + ".txt", "w") as source:
        source.write(str(len(cases)) + "\n")
        for marble_count, color_count in cases:
            source.write(str(marble_count) + " " + str(color_count) + "\n")
    with open("out/" + name + ".out", "w") as expected:
        for marble_count, color_count in cases:
            expected.write(str(exact_count(marble_count, color_count)) + "\n")


assert exact_count(10, 10) == 1
assert exact_count(30, 7) == 475020
assert exact_count(1000000, 2) == 999999
assert exact_count(1000000, 4) == 166665666668499999

sample = [(10, 10), (30, 7)]
emit("1_sample", sample)

edges = [
    (1, 1),
    (2, 1),
    (3, 3),
    (7, 2),
    (7, 6),
    (1000000, 1),
    (1000000, 1000000),
    (1000000, 999999),
    (1000000, 2),
    (1000000, 3),
    (1000000, 999998),
    (1000000, 4),
    (1000000, 999997),
]
for marble_count, color_count in edges:
    safe_case(marble_count, color_count)
emit("2_edges", edges)

wide = []
for marble_count in [1000000, 999999, 999998, 900000, 500000, 100000, 65536, 32768]:
    wide.append(safe_case(marble_count, 2))
    wide.append(safe_case(marble_count, 3))
    wide.append(safe_case(marble_count, marble_count - 1))
    wide.append(safe_case(marble_count, marble_count - 2))
emit("3_wide", wide)

rng = random.Random(20261123)
random_cases = []
while len(random_cases) < 60:
    marble_count = rng.randint(1, LIMIT)
    radius = rng.randint(0, 4)
    if rng.randrange(2) == 0:
        color_count = radius + 1
    else:
        color_count = marble_count - radius
    candidate = try_case(marble_count, color_count)
    if candidate is not None:
        random_cases.append(candidate)
emit("4_random", random_cases)

io_cases = []
for index in range(100):
    marble_count = 70000 + index
    io_cases.append(safe_case(marble_count, 5))
emit("5_io", io_cases)

print("generated", len(sample) + len(edges) + len(wide) + len(random_cases) + len(io_cases), "cases")
