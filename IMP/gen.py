import os
import random
from math import gcd


def bezout_abs(first_value, second_value):
    old_remainder, remainder = first_value, second_value
    old_first, current_first = 1, 0
    old_second, current_second = 0, 1
    while remainder != 0:
        quotient = old_remainder // remainder
        old_remainder, remainder = remainder, old_remainder - quotient * remainder
        old_first, current_first = current_first, old_first - quotient * current_first
        old_second, current_second = current_second, old_second - quotient * current_second
    return old_remainder, old_first, old_second


def solve_by_y(first_x, first_y, second_x, second_y):
    gcd_y = gcd(abs(first_y), abs(second_y))
    if gcd_y == 0:
        return gcd(abs(first_x), abs(second_x))
    search_radius = min(abs(first_x) + abs(first_y), abs(second_x) + abs(second_y))
    _, first_coef, second_coef = bezout_abs(abs(first_y), abs(second_y))
    if first_y < 0:
        first_coef = -first_coef
    if second_y < 0:
        second_coef = -second_coef
    base_x = first_coef * first_x + second_coef * second_x
    determinant = first_x * second_y - first_y * second_x
    step_size = abs(determinant // gcd_y)
    best = search_radius
    if step_size > 0:
        best = min(best, step_size)
    for index in range(-(search_radius // gcd_y), search_radius // gcd_y + 1):
        if index == 0:
            continue
        if step_size == 0:
            distance = abs(index * base_x)
        else:
            residue = (index * base_x) % step_size
            distance = min(residue, step_size - residue)
        best = min(best, abs(gcd_y * index) + distance)
    return best


def brute_small(first_x, first_y, second_x, second_y):
    search_radius = min(abs(first_x) + abs(first_y), abs(second_x) + abs(second_y))
    limit = search_radius + 6
    best = None
    for first_count in range(-limit, limit + 1):
        for second_count in range(-limit, limit + 1):
            x_value = first_count * first_x + second_count * second_x
            y_value = first_count * first_y + second_count * second_y
            if x_value == 0 and y_value == 0:
                continue
            distance = abs(x_value) + abs(y_value)
            if best is None or distance < best:
                best = distance
    return best


assert bezout_abs(13, 17) == (1, 4, -3)
assert solve_by_y(13, 4, 17, 5) == 2
assert solve_by_y(-7, 6, 9, 2) == 10
assert solve_by_y(100000, 100000, -100000, 100000) == 200000
assert brute_small(13, 4, 17, 5) == 2
for small_case in ((2, 3, 5, 7), (4, 4, 6, 6), (0, 1, 0, 7), (1, 0, 0, 1),
                   (-3, 5, 7, -2), (5, 5, 5, 5), (2, 4, 3, 6)):
    assert brute_small(*small_case) == solve_by_y(*small_case), small_case


def write_cases(name, cases):
    with open(f"in/{name}.txt", "w") as source:
        source.write("".join(f"{a} {b} {c} {d}\n" for a, b, c, d in cases))
    with open(f"out/{name}.out", "w") as answer:
        answer.write("".join(f"{solve_by_y(a, b, c, d)}\n" for a, b, c, d in cases))


os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

write_cases("1_sample", [(13, 4, 17, 5)])

write_cases("2_edges", [
    (5, 5, 5, 5),
    (1, 0, 0, 1),
    (0, 1, 0, 7),
    (0, 1, 5, 0),
    (100000, 100000, 100000, 99999),
    (-7, 6, 9, 2),
    (100000, 100000, -100000, 100000),
    (100000, 0, 100000, 0),
    (0, 100000, 0, 100000),
    (1, 1, -1, 1),
])

write_cases("3_wide", [
    (100000, 99999, 99999, 100000),
    (-100000, 100000, 100000, 100000),
    (100000, -100000, 99999, -99999),
    (99991, 99989, 99979, 99983),
    (-99999, 100000, -100000, -99999),
])

rng = random.Random(20261123)
random_cases = []
while len(random_cases) < 10:
    candidate = tuple(rng.randint(-100000, 100000) for _ in range(4))
    if (candidate[0], candidate[1]) == (0, 0) or (candidate[2], candidate[3]) == (0, 0):
        continue
    random_cases.append(candidate)
write_cases("4_random", random_cases)

write_cases("5_io", [(100000, 100000, -100000, 100000)] * 10)

print("generated five pairs, oracle checks passed")
