#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "10\n"
SAMPLE_OUT = """SIN ORDENAR
6 5 12 17 18 37 24 65 30 101
ORDENADO
30 24 18 12 6 5 17 37 65 101
"""


def build_vector(size):
    cells = []
    for index in range(1, size + 1):
        if index % 2 == 0:
            cells.append(index * index + 1)
        else:
            cells.append(3 * (index + 1))
    return cells


def radix_sort(values, descending=False):
    arranged = list(values)
    if not arranged:
        return arranged
    place = 1
    largest = max(arranged)
    while place <= largest:
        buckets = [[] for _ in range(10)]
        for value in arranged:
            buckets[(value // place) % 10].append(value)
        order = reversed(buckets) if descending else buckets
        arranged = [value for bucket in order for value in bucket]
        place *= 10
    return arranged


def oracle(text):
    size = int(text.split()[0])
    cells = build_vector(size)
    even_cells = [value for value in cells if value % 2 == 0]
    odd_cells = [value for value in cells if value % 2 == 1]
    ordered = radix_sort(even_cells, True) + radix_sort(odd_cells, False)
    return ("SIN ORDENAR\n" + " ".join(str(value) for value in cells)
            + "\nORDENADO\n" + " ".join(str(value) for value in ordered) + "\n")


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n") == "SIN ORDENAR\n6\nORDENADO\n6\n"
assert oracle("2\n") == "SIN ORDENAR\n6 5\nORDENADO\n6 5\n"
assert oracle("4\n") == "SIN ORDENAR\n6 5 12 17\nORDENADO\n12 6 5 17\n"


def write(name, size):
    input_text = str(size) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", 1)
    write("3_wide", 1000)
    rng = random.Random(20261125)
    write("4_random", rng.randint(2000, 8000))
    write("5_io", 200000)


def worked_example():
    cells = build_vector(10)
    even_cells = [value for value in cells if value % 2 == 0]
    odd_cells = [value for value in cells if value % 2 == 1]
    print(f"cells: {cells}")
    print(f"even values descending: {radix_sort(even_cells, True)}")
    print(f"odd values ascending: {radix_sort(odd_cells, False)}")


if "--trace" in sys.argv:
    worked_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", 10)
    build()
