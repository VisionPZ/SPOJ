#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    answers = []
    for _ in range(case_count):
        kind_count = tokens[position]
        position += 1
        heights = tokens[position:position + kind_count]
        position += kind_count
        modulus_len = tokens[position]
        stack_height = tokens[position + 1]
        target_height = tokens[position + 2] % modulus_len
        position += 3
        residues = [height % modulus_len for height in heights]
        if stack_height <= 6 and kind_count <= 8:
            count = 0
            for choice in itertools.product(range(kind_count), repeat=stack_height):
                if sum(residues[index] for index in choice) % modulus_len == target_height:
                    count = (count + 1) % MOD
        elif len(set(residues)) == 1:
            residue = residues[0]
            count = pow(kind_count, stack_height, MOD) if (stack_height * residue) % modulus_len == target_height else 0
        else:
            distribution = {0: 1}
            for _ in range(stack_height):
                following = {}
                for residue_sum, ways in distribution.items():
                    for residue in residues:
                        key = (residue_sum + residue) % modulus_len
                        following[key] = (following.get(key, 0) + ways) % MOD
                distribution = following
            count = distribution.get(target_height, 0)
        answers.append(str(count))
    return "\n".join(answers) + "\n"


SAMPLE = """2
3
1 2 3
3 1 0
3
1 2 3
3 2 0
"""
SAMPLE_OUT = """1
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n3\n3 1 0\n") == "1\n"
assert oracle("1\n3\n1 2 3\n3 2 0\n") == "3\n"
assert oracle("1\n3\n1 2 3\n1 1000000000 0\n") == str(pow(3, 1000000000, MOD)) + "\n"
assert oracle("1\n2\n1 1\n2 1000000000 0\n") == str(pow(2, 1000000000, MOD)) + "\n"


def write(name, cases):
    lines = [str(len(cases))]
    for heights, modulus_len, stack_height, target_height in cases:
        lines.append(str(len(heights)))
        lines.append(" ".join(str(height) for height in heights))
        lines.append(f"{modulus_len} {stack_height} {target_height}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([3], 3, 1, 0), ([1, 1], 2, 2, 0), ([1000000000], 7, 3, 4),
                      ([1, 2, 3], 3, 1, 2)])
    write("3_wide", [([1, 2, 3], 1, 1000000000, 0),
                     ([1, 1], 2, 1000000000, 0),
                     ([1000000000, 1000000000, 1000000000], 100, 4, 0)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(20):
        kind_count = rng.randrange(1, 7)
        heights = [rng.randrange(1, 40) for _ in range(kind_count)]
        random_cases.append((heights, rng.randrange(1, 8), rng.randrange(1, 5), rng.randrange(0, 8)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(2000):
        kind_count = rng.randrange(1, 5)
        heights = [rng.randrange(1, 20) for _ in range(kind_count)]
        io_cases.append((heights, rng.randrange(1, 6), rng.randrange(1, 4), rng.randrange(0, 6)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
