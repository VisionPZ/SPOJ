#!/usr/bin/env python3
import itertools
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def search_possible(arrival, target):
    total = len(arrival)

    @lru_cache(maxsize=None)
    def explore(arrival_index, stack, target_index):
        if target_index == total:
            return True
        if stack and stack[-1] == target[target_index]:
            if explore(arrival_index, stack[:-1], target_index + 1):
                return True
        if arrival_index < total:
            if explore(arrival_index + 1, stack + (arrival[arrival_index],), target_index):
                return True
        return False

    return explore(0, (), 0)


def avoids_312(permutation):
    prefix_max = [0] * len(permutation)
    best = 0
    for index, value in enumerate(permutation):
        prefix_max[index] = best
        if value > best:
            best = value
    for middle in range(len(permutation)):
        for later in range(middle + 1, len(permutation)):
            if permutation[middle] < permutation[later] < prefix_max[middle]:
                return False
    return True


def oracle(text):
    tokens = [int(value) for value in text.split()]
    car_count = tokens[0]
    arrival = tokens[1:1 + car_count]
    target = tokens[1 + car_count:1 + 2 * car_count]
    position = {car: index for index, car in enumerate(arrival)}
    relabeled = [position[car] + 1 for car in target]
    if car_count <= 8:
        feasible = search_possible(arrival, target)
    else:
        feasible = avoids_312(relabeled)
    if not feasible:
        return "IMPOSSIVEL\n"
    operations = []
    pushed = 0
    stack = []
    for desired in target:
        arrival_index = position[desired]
        while pushed <= arrival_index:
            operations.append("PUSH")
            stack.append(arrival[pushed])
            pushed += 1
        assert stack and stack[-1] == desired
        operations.append("POP")
        stack.pop()
    return "\n".join(operations) + "\n"


SAMPLE = "5\n1 2 3 4 5\n3 2 5 4 1\n"
SAMPLE_OUT = "PUSH\nPUSH\nPUSH\nPOP\nPOP\nPUSH\nPUSH\nPOP\nPOP\nPOP\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("4\n1 2 3 4\n4 2 3 1\n") == "IMPOSSIVEL\n"
assert oracle("1\n7\n7\n") == "PUSH\nPOP\n"
assert oracle("3\n5 6 7\n7 6 5\n") == "PUSH\nPUSH\nPUSH\nPOP\nPOP\nPOP\n"
assert avoids_312([3, 2, 5, 4, 1]) and not avoids_312([4, 2, 3, 1])

for size in range(1, 7):
    identity = list(range(1, size + 1))
    for permutation in itertools.permutations(identity):
        assert search_possible(identity, list(permutation)) == avoids_312(list(permutation))


def write(name, arrival, target):
    text = str(len(arrival)) + "\n"
    text += " ".join(str(car) for car in arrival) + "\n"
    text += " ".join(str(car) for car in target) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1], [1])
    identity = list(range(1, 1001))
    write("3_wide", identity, identity)
    rng = random.Random(20261126)
    small = list(range(1, 8))
    shuffled = small[:]
    rng.shuffle(shuffled)
    write("4_random", small, shuffled)
    paired = []
    for first in range(1, 1001, 2):
        paired.extend([first + 1, first])
    write("5_io", identity, paired)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 3, 4, 5], [3, 2, 5, 4, 1])
build()
