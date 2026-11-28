#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    washbasin_count = tokens[0]
    initial_count = tokens[1]
    query_count = tokens[2]
    occupied = tokens[3:3 + initial_count]
    requested = tokens[3 + initial_count:3 + initial_count + query_count]

    gaps = []
    if occupied[0] > 1:
        gaps.append((1, occupied[0] - 1))
    for index in range(initial_count - 1):
        length = occupied[index + 1] - occupied[index] - 1
        if length > 0:
            gaps.append((occupied[index] + 1, length))
    if occupied[-1] < washbasin_count:
        gaps.append((occupied[-1] + 1, washbasin_count - occupied[-1]))

    heap = [(-length, left) for left, length in gaps]
    heapq.heapify(heap)
    arrival_answer = {}
    max_arrival = max(requested) - initial_count
    for step in range(1, max_arrival + 1):
        negative_length, left = heapq.heappop(heap)
        length = -negative_length
        midpoint = left + (length - 1) // 2
        arrival_answer[initial_count + step] = midpoint
        first_length = (length - 1) // 2
        second_length = length - 1 - first_length
        if first_length > 0:
            heapq.heappush(heap, (-first_length, left))
        if second_length > 0:
            heapq.heappush(heap, (-second_length, midpoint + 1))

    answers = []
    for label in requested:
        answers.append(str(occupied[label - 1] if label <= initial_count
                           else arrival_answer[label]))
    return "\n".join(answers) + "\n"


SAMPLE = "7 1 4 4 2 3 4 5\n"
SAMPLE_OUT = "2\n6\n1\n3\n"
SECOND = "10 2 4 2 8 1 3 5 8\n"
SECOND_OUT = "2\n5\n6\n4\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SECOND) == SECOND_OUT
assert oracle("3 3 1\n1 2 3\n2\n") == "2\n"
assert oracle("5 1 4\n3\n1 2 4 5\n") == "3\n1\n2\n5\n"
assert oracle("6 2 4\n2 5\n1 3 4 6\n") == "2\n3\n1\n6\n"


def write(name, washbasin_count, occupied, requested):
    input_text = (f"{washbasin_count} {len(occupied)} {len(requested)}\n"
                  + " ".join(str(value) for value in occupied) + "\n"
                  + " ".join(str(value) for value in requested) + "\n")
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", 5, [3], [1, 2, 3, 4, 5])
    write("3_wide", 64, [1, 64], list(range(1, 65, 3)))
    rng = random.Random(20261126)
    occupied = sorted(rng.sample(range(1, 201), 17))
    requested = sorted(rng.sample(range(1, 201), 50))
    write("4_random", 200, occupied, requested)
    occupied = sorted(rng.sample(range(1, 501), 40))
    requested = sorted(rng.sample(range(1, 501), 100))
    write("5_io", 500, occupied, requested)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
