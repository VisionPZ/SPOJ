#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.splitlines()
    school_count = int(lines[0])
    colors = lines[1].strip()
    happiness = [int(value) for value in lines[2].split()]
    parents = [int(value) for value in lines[3].split()]
    signs = [1 if color == "B" else -1 for color in colors]

    best = None
    for first in range(1, school_count + 1):
        for second in range(first + 1, school_count + 1):
            def path_to_root(node):
                result = []
                while node != 0:
                    result.append(node)
                    node = parents[node - 2] if node > 1 else 0
                return result

            first_path = path_to_root(first)
            second_path = path_to_root(second)
            first_index = len(first_path) - 1
            second_index = len(second_path) - 1
            while (first_index >= 0 and second_index >= 0
                   and first_path[first_index] == second_path[second_index]):
                first_index -= 1
                second_index -= 1
            path = (first_path[:first_index + 2]
                    + list(reversed(second_path[:second_index + 1])))
            balance = sum(signs[node - 1] for node in path)
            if balance == 0:
                total = sum(happiness[node - 1] for node in path)
                if best is None or total > best:
                    best = total
    return str(best) + "\n"


SAMPLE = """6
BWBBBW
6 0 3 -2 100 5
1 2 2 4 4
"""
SAMPLE_OUT = """9
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\nBW\n5 -2\n1\n") == "3\n"
assert oracle("3\nBWB\n10 -5 7\n1 1\n") == "5\n"
assert oracle("4\nBBWW\n1 2 3 4\n1 1 3\n") == "10\n"
assert oracle("4\nBWWB\n-5 10 20 -1\n1 2 3\n") == "24\n"


def write(name, colors, happiness, parents):
    input_text = (str(len(colors)) + "\n" + colors + "\n"
                  + " ".join(str(value) for value in happiness) + "\n"
                  + " ".join(str(value) for value in parents) + "\n")
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", "BW", [7, -3], [1])
    write("3_wide", "BWBWBW", [100, -50, 30, -20, 10, -5], [1, 1, 2, 2, 3])
    rng = random.Random(20261126)
    colors = "".join(rng.choice("BW") for _ in range(11))
    happiness = [rng.randint(-20, 20) for _ in range(11)]
    parents = [rng.randint(1, index) for index in range(1, 11)]
    write("4_random", colors, happiness, parents)
    colors = "".join(rng.choice("BW") for _ in range(12))
    happiness = [rng.randint(-100, 100) for _ in range(12)]
    parents = [rng.randint(1, index) for index in range(1, 12)]
    write("5_io", colors, happiness, parents)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "BWBBBW", [6, 0, 3, -2, 100, 5], [1, 2, 2, 4, 4])
build()
