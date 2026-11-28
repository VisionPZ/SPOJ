#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    position = 1
    results = []
    for _ in range(case_count):
        length = int(tokens[position])
        bullets = int(tokens[position + 1])
        position += 2
        track = tokens[position]
        position += 1
        distances = {(0, 0, 0): 0}
        queue = [(0, 0, 0, 0)]
        while queue:
            cost, place, lane, shots = heapq.heappop(queue)
            if cost != distances.get((place, lane, shots)):
                continue
            if place == length - 1 and lane == 0:
                break
            if lane == 0:
                if place + 1 < length:
                    if track[place + 1] != '#':
                        step = (cost + 1, place + 1, 0, shots)
                        if step[0] < distances.get(step[1:], 10 ** 9):
                            distances[step[1:]] = step[0]
                            heapq.heappush(queue, step)
                    elif shots < bullets:
                        step = (cost + 1, place + 1, 0, shots + 1)
                        if step[0] < distances.get(step[1:], 10 ** 9):
                            distances[step[1:]] = step[0]
                            heapq.heappush(queue, step)
                step = (cost + 2, place, 1, shots)
                if step[0] < distances.get(step[1:], 10 ** 9):
                    distances[step[1:]] = step[0]
                    heapq.heappush(queue, step)
            else:
                if track[place] != '#':
                    step = (cost + 2, place, 0, shots)
                    if step[0] < distances.get(step[1:], 10 ** 9):
                        distances[step[1:]] = step[0]
                        heapq.heappush(queue, step)
                if place + 1 < length:
                    step = (cost + 2, place + 1, 1, shots)
                    if step[0] < distances.get(step[1:], 10 ** 9):
                        distances[step[1:]] = step[0]
                        heapq.heappush(queue, step)
        answer = min((cost for (place, lane, shots), cost in distances.items()
                      if place == length - 1 and lane == 0), default=None)
        results.append(str(answer) if answer is not None else "Impossible")
    return "\n".join(results) + "\n"


SAMPLE = """10
7 3
S00000E
2 2
SE
4 1
S00E
8 1
S0000##E
8 3
S0#00#0E
7 2
S0#0##E
10 4
S00#0#0##E
5 2
S000E
7 1
S0##00E
9 0
S0000##0E
"""
SAMPLE_OUT = """6
1
3
13
7
12
9
4
12
15
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 0\nSE\n") == "1\n"
assert oracle("1\n4 10\nS##E\n") == "3\n"
assert oracle("1\n5 0\nS000E\n") == "4\n"
assert oracle("1\n4 1\nS0#E\n") == "3\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for length, bullets, track in cases:
        text += f"{length} {bullets}\n{track}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_track(rng, length, density):
    middle = ['#' if rng.random() < density else '0' for _ in range(length - 2)]
    return 'S' + ''.join(middle) + 'E'


def build():
    write("2_edges", [
        (2, 0, "SE"), (3, 0, "S#E"), (3, 1, "S#E"),
        (4, 10, "S##E"), (5, 0, "S000E"), (4, 1, "S0#E"),
    ])
    write("3_wide", [
        (1000, 1000, make_track(random.Random(1), 1000, 0.5)),
        (1000, 0, make_track(random.Random(2), 1000, 0.5)),
    ])
    rng = random.Random(20261126)
    cases = []
    for _ in range(100):
        length = rng.randint(2, 12)
        cases.append((length, rng.randint(0, 5),
                      make_track(rng, length, rng.choice([0.0, 0.2, 0.5, 0.9]))))
    write("4_random", cases)
    cases = []
    for _ in range(100):
        length = rng.randint(50, 1000)
        cases.append((length, rng.randint(0, 3),
                      make_track(rng, length, rng.choice([0.1, 0.4]))))
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
