#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    school_count = tokens[position]
    position += 1
    sizes = tokens[position:position + school_count]
    position += school_count
    rank_lists = []
    for size in sizes:
        rank_lists.append(tokens[position:position + size])
        position += size
    mark_lists = []
    for size in sizes:
        mark_lists.append(tokens[position:position + size])
        position += size
    mark_by_rank = []
    for school_index in range(school_count):
        mapping = {}
        for student_index in range(sizes[school_index]):
            mapping[rank_lists[school_index][student_index]] = mark_lists[school_index][student_index]
        mark_by_rank.append(mapping)
    query_count = tokens[position]
    position += 1
    answers = []
    for _ in range(query_count):
        selected = tokens[position]
        position += 1
        schools = [value - 1 for value in tokens[position:position + selected]]
        position += selected
        rank_low = tokens[position]
        rank_high = tokens[position + 1]
        position += 2
        desired = tokens[position]
        position += 1
        marks = []
        for school_index in schools:
            for rank in range(rank_low, min(rank_high, sizes[school_index]) + 1):
                if rank in mark_by_rank[school_index]:
                    marks.append(mark_by_rank[school_index][rank])
        marks.sort(reverse=True)
        answers.append(str(-1) if desired > len(marks) else str(marks[desired - 1]))
    return "\n".join(answers) + "\n"


SAMPLE = """4
1 3 4 1
1
1 2 3
2 3 1 4
1
28
20 11 8
6 18 22 26
7
4
1
2
3 3
1
1
2
3 3
1
3
1 3 4
4 4
1
4
1 2 3 4
4 4
4
"""
SAMPLE_OUT = """8
8
26
-1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n1 2\n5 9\n1\n1\n1\n2 2\n2\n") == "-1\n"
assert oracle("1\n2\n1 2\n5 9\n1\n1\n1\n2 2\n1\n") == "9\n"
assert oracle("1\n2\n1 2\n5 9\n1\n1\n1\n1 2\n1\n") == "9\n"
assert oracle("2\n1 1\n1\n1\n10\n20\n1\n2\n1 2\n1 1\n1\n") == "20\n"


def write(name, sizes, ranks, marks, queries):
    lines = [str(len(sizes))]
    lines.append(" ".join(str(value) for value in sizes))
    for values in ranks:
        lines.append(" ".join(str(value) for value in values))
    for values in marks:
        lines.append(" ".join(str(value) for value in values))
    lines.append(str(len(queries)))
    for selected, rank_low, rank_high, desired in queries:
        lines.append(str(len(selected)))
        lines.append(" ".join(str(value) for value in selected))
        lines.append(str(rank_low) + " " + str(rank_high))
        lines.append(str(desired))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3], [[1], [2, 1], [1, 2, 3]], [[5], [7, 9], [11, 13, 15]],
          [([1], 1, 1, 1), ([2, 3], 1, 2, 2), ([1, 2, 3], 1, 3, 4), ([3], 3, 3, 1)])
    write("3_wide", [4, 4, 4, 4],
          [[1, 2, 3, 4], [4, 3, 2, 1], [2, 1, 4, 3], [3, 4, 1, 2]],
          [[10, 20, 30, 40], [15, 25, 35, 45], [12, 22, 32, 42], [18, 28, 38, 48]],
          [([1, 2, 3, 4], 1, 4, 8), ([1, 2], 2, 3, 3), ([4], 1, 4, 2)])
    rng = random.Random(20261126)
    sizes = [rng.randint(1, 6) for _ in range(5)]
    ranks = []
    marks = []
    all_marks = rng.sample(range(1, 1000000), sum(sizes))
    cursor = 0
    for size in sizes:
        ranks.append(rng.sample(range(1, size + 1), size))
        marks.append(all_marks[cursor:cursor + size])
        cursor += size
    queries = []
    for _ in range(20):
        selected = rng.sample(range(1, 6), rng.randint(1, 5))
        low = rng.randint(1, max(sizes))
        high = rng.randint(low, max(sizes))
        queries.append((selected, low, high, rng.randint(1, sum(sizes))))
    write("4_random", sizes, ranks, marks, queries)
    write("5_io", [8, 8, 8, 8],
          [list(range(1, 9)), list(range(8, 0, -1)), [1, 3, 5, 7, 2, 4, 6, 8], [8, 7, 6, 5, 4, 3, 2, 1]],
          [list(range(100, 108)), list(range(200, 208)), list(range(300, 308)), list(range(400, 408))],
          [([1, 2, 3, 4], 1, 8, 16) for _ in range(200)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 3, 4, 1], [[1], [1, 2, 3], [2, 3, 1, 4], [1]],
      [[28], [20, 11, 8], [6, 18, 22, 26], [7]],
      [([2], 3, 3, 1), ([2], 3, 3, 1), ([1, 3, 4], 4, 4, 1), ([1, 2, 3, 4], 4, 4, 4)])
build()
