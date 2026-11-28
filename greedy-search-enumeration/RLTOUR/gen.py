#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def counts_direct(arrangement):
    return [sum(1 for value in arrangement[:index] if value >= height)
            for index, height in enumerate(arrangement)]


def counts_with_bit(arrangement):
    doll_count = len(arrangement)
    tree = [0] * (doll_count + 2)

    def add(position, amount):
        while position <= doll_count:
            tree[position] += amount
            position += position & -position

    def prefix(position):
        total = 0
        while position > 0:
            total += tree[position]
            position -= position & -position
        return total

    result = []
    for index, height in enumerate(arrangement):
        smaller_before = prefix(height - 1)
        result.append(index - smaller_before)
        add(height, 1)
    return result


def brute_reconstruct(heights, containers_before):
    for arrangement in itertools.permutations(heights):
        if counts_direct(list(arrangement)) == containers_before:
            return list(arrangement)
    return None


SAMPLE = "2\n3\n12 13 14\n0 0 2\n3\n12 14 13\n0 1 0\n"
SAMPLE_OUT = "13 14 12\n13 12 14\n"
assert counts_direct([13, 14, 12]) == [0, 0, 2]
assert counts_direct([13, 12, 14]) == [0, 1, 0]
assert all(counts_with_bit(list(range(1, n + 1))) == [0] * n for n in range(1, 8))


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        doll_count = tokens[cursor]
        cursor += 1
        heights = tokens[cursor:cursor + doll_count]
        cursor += doll_count
        containers_before = tokens[cursor:cursor + doll_count]
        cursor += doll_count
        arrangement = brute_reconstruct(heights, containers_before)
        assert arrangement is not None
        answers.append(" ".join(str(value) for value in arrangement))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n7\n0\n") == "7\n"


def make_case(rng, doll_count):
    arrangement = rng.sample(range(1, doll_count + 1), doll_count)
    containers_before = counts_with_bit(arrangement)
    heights = arrangement[:]
    rng.shuffle(heights)
    return heights, containers_before, arrangement


def write(name, cases):
    lines = [str(len(cases))]
    for heights, containers_before, arrangement in cases:
        lines.append(str(len(heights)))
        lines.append(" ".join(str(value) for value in heights))
        lines.append(" ".join(str(value) for value in containers_before))
    text = "\n".join(lines) + "\n"
    expected = "\n".join(" ".join(str(value) for value in arrangement)
                         for heights, containers_before, arrangement in cases) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(expected)


def build():
    rng = random.Random(20261126)
    edges = [make_case(rng, 1), make_case(rng, 2), make_case(rng, 3),
             make_case(rng, 5), make_case(rng, 8)]
    for heights, containers_before, arrangement in edges:
        assert brute_reconstruct(heights, containers_before) == arrangement
    for _ in range(40):
        heights, containers_before, arrangement = make_case(rng, rng.randint(1, 7))
        assert brute_reconstruct(heights, containers_before) == arrangement
        assert counts_direct(arrangement) == containers_before
    write("2_edges", edges)
    write("3_wide", [make_case(rng, 500) for _ in range(4)])
    write("4_random", [make_case(rng, rng.randint(5, 50)) for _ in range(20)])
    write("5_io", [make_case(rng, 500) for _ in range(500)])


def trace():
    containers_before = [0, 0, 2]
    remaining = sorted([12, 13, 14], reverse=True)
    print(f"heights sorted: {remaining}  counts: {containers_before}")
    for position in range(2, -1, -1):
        target = containers_before[position] + 1
        running = 0
        chosen = None
        for height in remaining:
            running += 1
            if running == target:
                chosen = height
                break
        print(f"position {position}: target {target} -> height {chosen}")
        remaining.remove(chosen)
    arrangement = [13, 14, 12]
    print(f"reconstructed: {arrangement}")
    print(f"checked counts: {counts_direct(arrangement)}")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
trace()
