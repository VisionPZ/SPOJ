#!/usr/bin/env python3
import random
from bisect import bisect_right
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1 << 32


def oracle(text):
    tokens = text.split()
    cursor = 0
    item_count = int(tokens[cursor]); cursor += 1
    query_count = int(tokens[cursor]); cursor += 1
    values = [int(tokens[cursor + index]) for index in range(item_count)]
    cursor += item_count
    queries = []
    for _ in range(query_count):
        kind = int(tokens[cursor]); cursor += 1
        left = int(tokens[cursor]); cursor += 1
        right = int(tokens[cursor]); cursor += 1
        parameter = int(tokens[cursor]); cursor += 1
        queries.append((kind, left - 1, right - 1, parameter))

    @lru_cache(maxsize=None)
    def subset_counts(left, right):
        if left > right:
            return {0: 1}
        inner = subset_counts(left + 1, right)
        result = dict(inner)
        added = values[left]
        for total, ways in inner.items():
            result[total + added] = result.get(total + added, 0) + ways
        return result

    answers = []
    for kind, left, right, parameter in queries:
        counts = subset_counts(left, right)
        if kind == 1:
            ways = counts.get(parameter, 0)
            if parameter == 0:
                ways -= 1
            answers.append(str(ways % MODULUS))
        else:
            present = sorted(total for total, ways in counts.items() if ways > 0 and total > 0)
            greatest = present[-1] if present else 0
            low = 1
            high = greatest + parameter + 1
            while low < high:
                middle = (low + high) // 2
                missing_count = middle - bisect_right(present, middle)
                if missing_count >= parameter:
                    high = middle
                else:
                    low = middle + 1
            answers.append(str(low))
    return "\n".join(answers) + "\n"


def brute_force(text):
    tokens = text.split()
    cursor = 0
    item_count = int(tokens[cursor]); cursor += 1
    query_count = int(tokens[cursor]); cursor += 1
    values = [int(tokens[cursor + index]) for index in range(item_count)]
    cursor += item_count
    answers = []
    for _ in range(query_count):
        kind = int(tokens[cursor]); cursor += 1
        left = int(tokens[cursor]); cursor += 1
        right = int(tokens[cursor]); cursor += 1
        parameter = int(tokens[cursor]); cursor += 1
        segment = values[left - 1:right]
        sums = []
        for mask in range(1, 1 << len(segment)):
            total = 0
            for index, value in enumerate(segment):
                if (mask >> index) & 1:
                    total += value
            sums.append(total)
        if kind == 1:
            answers.append(str(sum(1 for total in sums if total == parameter) % MODULUS))
        else:
            missing = []
            candidate = 1
            while len(missing) < parameter:
                if candidate not in sums:
                    missing.append(candidate)
                candidate += 1
            answers.append(str(missing[-1]))
    return "\n".join(answers) + "\n"


SAMPLE = """5 3
1 0 2 4 1
0 2 3 2
1 1 4 0
1 2 5 3
"""
SAMPLE_OUT = """3
1
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_force(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n0\n1 1 1 0\n") == "1\n"
assert oracle("2 1\n1 1\n1 1 2 2\n") == "1\n"
assert oracle("3 2\n1 2 3\n0 1 3 1\n0 1 3 2\n") == "7\n8\n"
assert brute_force("3 2\n1 2 3\n0 1 3 1\n0 1 3 2\n") == "7\n8\n"


def write(name, values, queries):
    lines = [f"{len(values)} {len(queries)}", " ".join(str(value) for value in values)]
    lines.extend(f"{kind} {left} {right} {parameter}" for kind, left, right, parameter in queries)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    values = [1, 2, 3, 4, 5]
    queries = [(0, 1, 5, 1), (0, 1, 5, 3), (1, 1, 5, 5), (1, 2, 4, 0)]
    write("2_edges", values, queries)

    wide = [100] * 25
    queries = []
    for kind in (0, 1):
        for left in (1, 7, 25):
            for right in (left, 25):
                queries.append((kind, left, right, 10 ** 9 if kind == 0 else 0))
    write("3_wide", wide, queries)

    values = [rng.randint(0, 100) for _ in range(25)]
    queries = []
    for _ in range(400):
        left = rng.randint(1, 25)
        right = rng.randint(left, 25)
        if rng.randint(0, 1):
            queries.append((0, left, right, rng.randint(1, 10 ** 9)))
        else:
            queries.append((1, left, right, rng.randint(0, 2000)))
    write("4_random", values, queries)

    values = [rng.randint(0, 100) for _ in range(25)]
    queries = []
    for index in range(10000):
        left = rng.randint(1, 25)
        right = rng.randint(left, 25)
        if index % 3 == 0:
            queries.append((0, left, right, rng.randint(1, 10 ** 9)))
        else:
            queries.append((1, left, right, rng.randint(0, 2000)))
    write("5_io", values, queries)


def trace_example():
    values = [1, 0, 2, 4, 1]
    print("segment 1..4:", values[0:4])
    print("subset sums:", sorted({0, 1, 2, 3, 4, 5, 6, 7}))
    print("missing positives: 8, 9, 10, ...")
    print("segment 2..3:", values[1:3])
    print("ways to sum 3:", 2)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 0, 2, 4, 1], [(0, 2, 3, 2), (1, 1, 4, 0), (1, 2, 5, 3)])
build()
trace_example()
