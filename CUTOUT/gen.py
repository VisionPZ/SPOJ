import os
import random


def oracle(square_size, rectangles):
    xs = sorted({0, square_size} | {c for left, right, bottom, top in rectangles for c in (left, right)})
    ys = sorted({0, square_size} | {c for left, right, bottom, top in rectangles for c in (bottom, top)})
    x_index = {value: index for index, value in enumerate(xs)}
    y_index = {value: index for index, value in enumerate(ys)}
    x_count = len(xs)
    y_count = len(ys)
    blocked = [[False] * (x_count - 1) for _ in range(y_count - 1)]
    for left, right, bottom, top in rectangles:
        if left > right:
            left, right = right, left
        if bottom > top:
            bottom, top = top, bottom
        for x in range(x_index[left], x_index[right]):
            for y in range(y_index[bottom], y_index[top]):
                blocked[y][x] = True
    prefix = [[0] * x_count for _ in range(y_count)]
    for y in range(y_count - 1):
        row_sum = 0
        for x in range(x_count - 1):
            row_sum += 1 if blocked[y][x] else 0
            prefix[y + 1][x + 1] = prefix[y][x + 1] + row_sum
    best = 0
    for left in range(x_count - 1):
        for right in range(left + 1, x_count):
            width = xs[right] - xs[left]
            height = 0
            for y in range(y_count - 1):
                covered = prefix[y + 1][right] - prefix[y + 1][left] - prefix[y][right] + prefix[y][left]
                if covered == 0:
                    height += ys[y + 1] - ys[y]
                    candidate = width * height
                    if candidate > best:
                        best = candidate
                else:
                    height = 0
    return best


assert oracle(6, [(0, 3, 0, 3), (3, 6, 3, 6)]) == 9
assert oracle(10, [(0, 5, 0, 5), (0, 10, 5, 10), (9, 10, 0, 5)]) == 20
assert oracle(1, []) == 1
assert oracle(10, [(2, 8, 2, 8)]) == 20
assert oracle(100, [(0, 50, 0, 100)]) == 5000
assert oracle(10, [(0, 10, 0, 10)]) == 0
assert oracle(5, [(0, 5, 0, 1), (0, 5, 4, 5)]) == 15
assert oracle(40000, [(0, 40000, 0, 1)]) == 1599960000


def write(name, cases):
    lines = [str(len(cases))]
    answers = []
    for size, rects in cases:
        coords = [value for rect in rects for value in rect]
        lines.append(f"{size} {len(rects)}")
        lines.append(" ".join(str(value) for value in coords))
        answers.append(str(oracle(size, rects)))
    with open(f"in/{name}.txt", "w") as handle:
        handle.write("\n".join(lines) + "\n")
    with open(f"out/{name}.out", "w") as handle:
        handle.write("\n".join(answers) + "\n")


os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

with open("in/1_sample.txt", "w") as handle:
    handle.write("2\n6 2\n0 3 0 3 3 6 3 6\n10 3\n0 5 0 5 0 10 5 10 9 10 0 5\n")
with open("out/1_sample.out", "w") as handle:
    handle.write("9\n20\n")

edges = [
    (1, []),
    (1, [(0, 1, 0, 1)]),
    (10, []),
    (10, [(2, 8, 2, 8)]),
    (10, [(0, 10, 0, 10)]),
    (100, [(0, 50, 0, 100)]),
    (5, [(0, 5, 0, 1), (0, 5, 4, 5)]),
    (7, [(0, 7, 3, 3)]),
    (7, [(0, 4, 0, 7), (3, 7, 0, 7)]),
    (40000, []),
    (40000, [(0, 40000, 0, 1)]),
]
write("2_edges", edges)

strips = [(i * 400, i * 400 + 1, 0, 40000) for i in range(100)]
grid = [(i * 3999, (i + 1) * 3999, j * 3999, (j + 1) * 3999) for i in range(10) for j in range(10)]
wide = [
    (40000, strips),
    (40000, grid),
    (1, [(0, 0, 0, 0)] * 100),
]
write("3_wide", wide)

rng = random.Random(20261123)
random_cases = []
for _ in range(10):
    size = rng.choice([1, 2, 7, 50, 40000, rng.randint(1, 40000)])
    count = rng.randint(0, 100)
    rects = []
    for _ in range(count):
        left, right = sorted(rng.sample(range(size + 1), 2))
        bottom, top = sorted(rng.sample(range(size + 1), 2))
        rects.append((left, right, bottom, top))
    random_cases.append((size, rects))
write("4_random", random_cases)

io_cases = []
for _ in range(10):
    rects = []
    for _ in range(100):
        left, right = sorted(rng.sample(range(40001), 2))
        bottom, top = sorted(rng.sample(range(40001), 2))
        rects.append((left, right, bottom, top))
    io_cases.append((40000, rects))
write("5_io", io_cases)

print("generated 5 test pairs")
