#!/usr/bin/env python3
import itertools
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(maxsize=None)
def oracle(permutation_size, inversions):
    largest = permutation_size * (permutation_size - 1) // 2
    if inversions == 0:
        return " ".join(str(value) for value in range(1, permutation_size + 1))
    if inversions == largest:
        return " ".join(str(value) for value in range(permutation_size, 0, -1))
    assert permutation_size <= 8
    for candidate in itertools.permutations(range(1, permutation_size + 1)):
        count = 0
        for left in range(permutation_size):
            for right in range(left + 1, permutation_size):
                if candidate[left] > candidate[right]:
                    count += 1
        if count == inversions:
            return " ".join(str(value) for value in candidate)
    raise ValueError("no permutation found")


SAMPLE = "5 9\n7 3\n-1 -1\n"
SAMPLE_OUT = "4 5 3 2 1\n1 2 3 4 7 6 5\n"
assert oracle(5, 9) == "4 5 3 2 1"
assert oracle(7, 3) == "1 2 3 4 7 6 5"
assert oracle(4, 0) == "1 2 3 4"
assert oracle(4, 6) == "4 3 2 1"
assert oracle(3, 2) == "2 3 1"
assert "\n".join([oracle(5, 9), oracle(7, 3)]) + "\n" == SAMPLE_OUT


def write(name, pairs):
    text = "".join(f"{size} {inversions}\n" for size, inversions in pairs) + "-1 -1\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(
        "".join(oracle(size, inversions) + "\n" for size, inversions in pairs)
    )


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)

write("2_edges", [(1, 0), (2, 0), (2, 1), (3, 3), (8, 0), (8, 28)])
write("3_wide", [(8, inversions) for inversions in range(29)])
rng = random.Random(20261128)
random_pairs = []
for _ in range(40):
    chosen_size = rng.randint(2, 8)
    largest_inversions = chosen_size * (chosen_size - 1) // 2
    random_pairs.append((chosen_size, rng.randint(0, largest_inversions)))
write("4_random", random_pairs)
write("5_io", [(50000, 0 if index % 2 == 0 else 1249975000) for index in range(12)])
