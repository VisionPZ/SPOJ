#!/usr/bin/env python3
import random
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent
LIMIT = 1 << 30
HUGE = 1 << 62


def exhaustive(populations, colors):
    regions = len(populations)
    if regions < colors:
        return None
    groups = [[] for _ in range(colors)]
    best = None

    def visit(position, highest_label):
        nonlocal best
        if position == regions:
            if highest_label != colors - 1:
                return
            total = 0
            for group in groups:
                ordered = sorted(group)
                median = ordered[len(ordered) // 2]
                for value in ordered:
                    total += abs(value - median)
            if best is None or total < best:
                best = total
            return
        top = min(highest_label + 1, colors - 1)
        for label in range(top + 1):
            groups[label].append(populations[position])
            visit(position + 1, max(highest_label, label))
            groups[label].pop()

    visit(0, -1)
    return best


def block_costs(splits, right, values, prefix):
    middle = (splits + right) // 2
    left_count = middle - splits + 1
    right_count = right - middle
    middle_value = values[middle]
    return (left_count * middle_value - (prefix[middle + 1] - prefix[splits])) + \
           ((prefix[right + 1] - prefix[middle + 1]) - right_count * middle_value)


def reference(populations, colors):
    values = np.array(sorted(populations), dtype=np.int64)
    regions = len(values)
    prefix = np.zeros(regions + 1, dtype=np.int64)
    np.cumsum(values, out=prefix[1:])
    previous = np.full(regions + 1, HUGE, dtype=np.int64)
    for colored in range(1, regions + 1):
        previous[colored] = block_costs(np.array([0], dtype=np.int64),
                                        colored - 1, values, prefix)[0]
    for used in range(2, colors + 1):
        current = np.full(regions + 1, HUGE, dtype=np.int64)
        for colored in range(used, regions + 1):
            splits = np.arange(used - 1, colored, dtype=np.int64)
            candidate = previous[splits] + block_costs(splits, colored - 1,
                                                       values, prefix)
            current[colored] = candidate.min()
        previous = current
    return int(previous[regions])


def oracle(text):
    tokens = text.split()
    cursor = 0
    cases = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(cases):
        regions = int(tokens[cursor]); cursor += 1
        colors = int(tokens[cursor]); cursor += 1
        populations = [int(tokens[cursor + i]) for i in range(regions)]
        cursor += regions
        answers.append(str(reference(populations, colors)))
    return "\n".join(answers) + "\n"


def encode(pairs):
    chunks = []
    for regions, colors, populations in pairs:
        chunks.append(str(regions) + "\n" + str(colors) + "\n" +
                      "".join(str(value) + "\n" for value in populations))
    return str(len(pairs)) + "\n" + "\n".join(chunk.rstrip("\n") for chunk in chunks) + "\n"


def write(name, pairs):
    text = encode(pairs)
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


SAMPLE = [(11, 3, [21, 14, 6, 18, 10, 2, 15, 12, 3, 2, 2])]
assert oracle(encode(SAMPLE)) == "15\n"
assert exhaustive([1, 1, 1, 1], 2) == 0
assert exhaustive([0, 10], 2) == 0
assert exhaustive([1, 2, 3, 4], 2) == 2
random.seed(1937)
for _ in range(300):
    regions = random.randint(2, 9)
    colors = random.randint(2, min(4, regions))
    values = [random.randint(0, 60) for _ in range(regions)]
    assert exhaustive(values, colors) == reference(values, colors)


def build():
    edges = [
        (11, 2, [7] * 11),
        (11, 10, list(range(11))),
        (11, 2, [0] * 11),
        (12, 6, [LIMIT] * 6 + [0] * 6),
        (11, 3, [LIMIT, LIMIT - 1, 0, 1, 2, 3, 4, 5, 6, 7, 8]),
    ]
    write("2_edges", edges)

    wide = [
        (2999, 10, [0] * 2999),
        (2999, 10, [LIMIT] * 2999),
        (2999, 2, [random.randint(0, LIMIT) for _ in range(2999)]),
        (2999, 10, [random.randint(0, 5) for _ in range(2999)]),
    ]
    write("3_wide", wide)

    random.seed(20261124)
    general = []
    for _ in range(16):
        regions = random.randint(11, 2999)
        colors = random.randint(2, 10)
        spread = random.choice([5, 100, 10000, LIMIT])
        general.append((regions, colors, [random.randint(0, spread)
                                          for _ in range(regions)]))
    write("4_random", general)

    random.seed(7)
    many = []
    for _ in range(20000):
        values = [random.randint(0, LIMIT) for _ in range(11)]
        many.append((11, 2, values))
    write("5_io", many)


def worked_example():
    populations = SAMPLE[0][2]
    ordered = sorted(populations)
    best = None
    for first_split in range(1, len(ordered) - 1):
        for second_split in range(first_split + 1, len(ordered)):
            total = (reference(ordered[:first_split], 1) +
                     reference(ordered[first_split:second_split], 1) +
                     reference(ordered[second_split:], 1))
            if best is None or total < best[0]:
                best = (total, first_split, second_split)
    assert best[0] == reference(populations, SAMPLE[0][1])
    print("sorted:", ordered)
    bounds = [(0, best[1] - 1), (best[1], best[2] - 1),
              (best[2], len(ordered) - 1)]
    for left, right in bounds:
        median = ordered[(left + right) // 2]
        cost = reference(ordered[left:right + 1], 1)
        print(f"block [{left},{right}] median {median} cost {cost}")
    print("total:", best[0])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
worked_example()
