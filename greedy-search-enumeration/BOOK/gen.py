#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def heap_answer(school_count, query_school, pages):
    booklet_count = len(pages)
    lower = booklet_count // school_count
    extra = booklet_count % school_count
    upper = lower + (1 if extra else 0)
    heap = [(page, index) for index, page in enumerate(pages)]
    heapq.heapify(heap)
    for school in range(school_count):
        take = upper if school < extra else lower
        chosen = [heapq.heappop(heap)[1] for _ in range(take)]
        if school == query_school:
            return pages[min(chosen)] if chosen else 0
    return 0


def brute_answer(school_count, query_school, pages):
    remaining = list(enumerate(pages))
    booklet_count = len(pages)
    lower = booklet_count // school_count
    extra = booklet_count % school_count
    upper = lower + (1 if extra else 0)
    for school in range(school_count):
        take = upper if school < extra else lower
        chosen = []
        for _ in range(take):
            best = 0
            for position in range(1, len(remaining)):
                if remaining[position][1] < remaining[best][1]:
                    best = position
            chosen.append(remaining.pop(best)[0])
        if school == query_school:
            return pages[min(chosen)] if chosen else 0
    return 0


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        school_count = int(tokens[cursor]); cursor += 1
        query_school = int(tokens[cursor]); cursor += 1
        booklet_count = int(tokens[cursor]); cursor += 1
        pages = [int(token) for token in tokens[cursor:cursor + booklet_count]]
        cursor += booklet_count
        answers.append(str(heap_answer(school_count, query_school, pages)))
    return "\n".join(answers) + "\n"


def write(name, cases):
    chunks = [str(len(cases)) + "\n"]
    for school_count, query_school, pages in cases:
        chunks.append(f"{school_count}\n{query_school}\n{len(pages)}\n")
        chunks.append(" ".join(str(page) for page in pages) + "\n")
    input_text = "".join(chunks)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert heap_answer(3, 2, [3, 5, 9, 1, 11, 14, 2]) == 11
assert heap_answer(2, 1, [100, 1, 2, 3]) == 100
assert heap_answer(2, 1, [3, 1, 4, 2]) == 3
assert heap_answer(5, 1, [3, 1, 2]) == 2

checker = random.Random(7)
for _ in range(150):
    count = checker.randint(1, 14)
    pages = checker.sample(range(1, 200), count)
    schools = checker.randint(1, count + 2)
    query = checker.randint(0, schools - 1)
    assert heap_answer(schools, query, pages) == brute_answer(schools, query, pages)

SAMPLE = [(3, 2, [3, 5, 9, 1, 11, 14, 2])]

EDGES = [
    (1, 0, [5]),
    (1, 0, [42]),
    (3, 0, [9, 1, 5]),
    (3, 2, [9, 1, 5]),
    (2, 0, [2, 1]),
    (2, 1, [2, 1]),
    (4, 3, [10, 20, 30, 40]),
    (5, 4, [50, 40, 30, 20, 10]),
    (3, 1, [100, 1, 2, 3, 4, 5, 6]),
    (5, 1, [3, 1, 2]),
    (3, 1, [8, 6, 4, 2, 10, 12, 14, 16, 18, 20]),
]

rng = random.Random(20261125)
WIDE = []
for schools, query in ((1, 0), (2, 1), (3, 2), (2999, 0), (2999, 2998), (1000, 999)):
    WIDE.append((schools, query, rng.sample(range(1, 30000), 2999)))

RANDOM = []
for _ in range(20):
    count = rng.randint(1, 2999)
    schools = rng.randint(1, count)
    query = rng.randint(0, schools - 1)
    RANDOM.append((schools, query, rng.sample(range(1, 100000), count)))

IO = []
for _ in range(20):
    schools = rng.randint(1, 2999)
    query = rng.randint(0, schools - 1)
    IO.append((schools, query, rng.sample(range(1, 100000), 2999)))

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
write("2_edges", EDGES)
write("3_wide", WIDE)
write("4_random", RANDOM)
write("5_io", IO)
