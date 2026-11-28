import random

def oracle(tile_a, tile_b, box_x, box_y):
    if tile_a > tile_b:
        tile_a, tile_b = tile_b, tile_a
    if box_x > box_y:
        box_x, box_y = box_y, box_x
    if box_x <= tile_a and box_y <= tile_b:
        return True
    if box_x > tile_a:
        return False
    short_gap = box_y * box_y - box_x * box_x
    left_side = short_gap * short_gap + 4 * tile_a * tile_b * box_x * box_y
    right_side = (tile_a * tile_a + tile_b * tile_b) * (box_x * box_x + box_y * box_y)
    return left_side <= right_side

assert oracle(10, 10, 8, 8) is True
assert oracle(8, 8, 10, 10) is False
assert oracle(100, 50, 105, 9) is True
assert oracle(9, 9, 10, 1) is True
assert oracle(10, 10, 10, 10) is True
assert oracle(50, 100, 9, 200) is False
assert oracle(1, 1, 1, 1) is True
assert oracle(1, 1, 2, 1) is False
assert oracle(50000, 50000, 50000, 50000) is True
assert oracle(50000, 50000, 50001, 50001) is False

escape_line = "Escape is possible."
blocked_line = "Box cannot be dropped."

def emit(cases, name):
    with open("in/" + name + ".txt", "w") as handle:
        handle.write(str(len(cases)) + "\n")
        for case in cases:
            handle.write("%d %d %d %d\n" % case)
    with open("out/" + name + ".out", "w") as handle:
        for case in cases:
            handle.write((escape_line if oracle(*case) else blocked_line) + "\n")

sample_cases = [
    (10, 10, 8, 8),
    (8, 8, 10, 10),
]
emit(sample_cases, "1_sample")

edge_cases = [
    (1, 1, 1, 1),
    (1, 1, 2, 1),
    (10, 10, 10, 10),
    (10, 10, 9, 14),
    (100, 50, 105, 9),
    (9, 9, 10, 1),
    (5, 5, 5, 5),
    (5, 5, 6, 5),
    (100, 100, 1, 141),
    (100, 100, 1, 142),
    (7, 3, 7, 3),
    (7, 3, 8, 2),
    (2, 2, 1, 3),
    (2, 2, 2, 3),
]
emit(edge_cases, "2_edges")

wide_cases = [
    (50000, 50000, 50000, 50000),
    (50000, 50000, 50000, 50001),
    (50000, 1, 50000, 1),
    (1, 50000, 1, 50000),
    (50000, 50000, 1, 70710),
    (50000, 50000, 1, 70711),
    (1, 1, 50000, 50000),
    (50000, 49999, 50000, 49999),
    (40000, 30000, 50000, 1000),
    (30000, 40000, 1000, 50000),
    (50000, 50000, 49999, 50001),
    (50000, 50000, 1, 50000),
]
emit(wide_cases, "3_wide")

rng = random.Random(20241123)
random_cases = []
for _ in range(10000):
    tile_a = rng.randint(1, 50000)
    tile_b = rng.randint(1, 50000)
    box_x = rng.randint(1, 50000)
    box_y = rng.randint(1, 50000)
    random_cases.append((tile_a, tile_b, box_x, box_y))
emit(random_cases, "4_random")

io_cases = []
for index in range(10000):
    tile_a = 10000 + (index % 30000)
    tile_b = 20000 + (index % 20000)
    box_x = 50000
    box_y = 50000
    io_cases.append((tile_a, tile_b, box_x, box_y))
emit(io_cases, "5_io")

big_rng = random.Random(777)
with open("/tmp/EQBOX_big.txt", "w") as big_handle:
    big_handle.write("200000\n")
    for _ in range(200000):
        big_handle.write("%d %d %d %d\n" % (
            big_rng.randint(1, 50000),
            big_rng.randint(1, 50000),
            big_rng.randint(1, 50000),
            big_rng.randint(1, 50000),
        ))
