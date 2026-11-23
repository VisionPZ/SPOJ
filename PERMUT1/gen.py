import math
import os
import random
from itertools import permutations

ROOT = os.path.dirname(os.path.abspath(__file__))
IN_DIR = os.path.join(ROOT, "in")
OUT_DIR = os.path.join(ROOT, "out")


def brute_count(n, k):
    total = 0
    for perm in permutations(range(1, n + 1)):
        inversions = 0
        for left in range(n):
            for right in range(left + 1, n):
                if perm[left] > perm[right]:
                    inversions += 1
        if inversions == k:
            total += 1
    return total


def oracle(n, k):
    table = [[0] * (k + 1) for _ in range(n + 1)]
    table[0][0] = 1
    for length in range(1, n + 1):
        table[length][0] = 1
        for inversions in range(1, k + 1):
            total = 0
            for added in range(0, min(inversions, length - 1) + 1):
                total += table[length - 1][inversions - added]
            table[length][inversions] = total
    return table[n][k]


assert oracle(4, 1) == 3
assert oracle(7, 2) == 20
assert oracle(7, 3) == 49
assert oracle(8, 3) == 76
assert oracle(14, 91) == 1
assert oracle(20, 190) == 1
for small_n in range(1, 8):
    for small_k in range(0, small_n * (small_n - 1) // 2 + 2):
        assert oracle(small_n, small_k) == brute_count(small_n, small_k)
for size in range(0, 8):
    assert sum(oracle(size, k) for k in range(size * (size - 1) // 2 + 1)) == math.factorial(size)


def build_table(max_n, max_k):
    table = [[0] * (max_k + 1) for _ in range(max_n + 1)]
    table[0][0] = 1
    for length in range(1, max_n + 1):
        table[length][0] = 1
        for inversions in range(1, max_k + 1):
            total = 0
            for added in range(0, min(inversions, length - 1) + 1):
                total += table[length - 1][inversions - added]
            table[length][inversions] = total
    return table


MASTER = build_table(20, 200)


def emit(name, cases):
    with open(os.path.join(IN_DIR, name + ".txt"), "w") as handle:
        handle.write(str(len(cases)) + "\n")
        for n, k in cases:
            handle.write("%d %d\n" % (n, k))
    with open(os.path.join(OUT_DIR, name + ".out"), "w") as handle:
        for n, k in cases:
            handle.write(str(MASTER[n][k]) + "\n")


emit("1_sample", [(4, 1)])
emit("2_edges", [
    (1, 0), (1, 1), (2, 0), (2, 1), (2, 5),
    (4, 1), (4, 6), (4, 7), (14, 91), (15, 98),
])
emit("3_wide", [
    (1, 98), (12, 0), (12, 66), (13, 78), (14, 91),
    (20, 0), (20, 98), (20, 190), (20, 191), (11, 98),
])
rng = random.Random(20261123)
random_cases = [(rng.randint(1, 20), rng.randint(0, 98)) for _ in range(10)]
emit("4_random", random_cases)
emit("5_io", [(20, k) for k in range(90, 100)])

stress_path = "/tmp/PERMUT1_big.txt"
stress_out_path = "/tmp/PERMUT1_big.out"
stress_rng = random.Random(90817263)
stress_cases = [(stress_rng.randint(1, 20), stress_rng.randint(0, 98)) for _ in range(200000)]
with open(stress_path, "w") as handle:
    handle.write("200000\n")
    for n, k in stress_cases:
        handle.write("%d %d\n" % (n, k))
with open(stress_out_path, "w") as handle:
    for n, k in stress_cases:
        handle.write(str(MASTER[n][k]) + "\n")
