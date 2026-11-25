#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def scan(text):
    position = 0
    while position < len(text):
        if text[position].isspace():
            position += 1
            continue
        if text[position] in "TS":
            yield text[position]
            position += 1
            continue
        end = position
        while end < len(text) and text[end].isdigit():
            end += 1
        yield int(text[position:end])
        position = end


def oracle(text):
    stream = list(scan(text))
    position = 0
    case_count = stream[position]
    position += 1
    answers = []
    for _ in range(case_count):
        buildings = stream[position]
        walkways = stream[position + 1]
        days = stream[position + 2]
        position += 3
        edges = []
        for _ in range(walkways):
            edges.append((stream[position], stream[position + 1]))
            position += 2
        adjacency = [[] for _ in range(buildings + 1)]
        for index, (left, right) in enumerate(edges):
            adjacency[left].append((right, index))
            adjacency[right].append((left, index))
        waiting = [0] * (buildings + 1)
        total = 0
        for _ in range(days):
            event = stream[position]
            position += 1
            if event == "T":
                start = stream[position]
                finish = stream[position + 1]
                outsiders = stream[position + 2]
                position += 3
                reached = {start}
                frontier = [start]
                while frontier:
                    current = frontier.pop()
                    for neighbor, _ in adjacency[current]:
                        if neighbor not in reached:
                            reached.add(neighbor)
                            frontier.append(neighbor)
                if finish in reached:
                    usable = set()

                    def explore(current, used_mask, path):
                        if current == finish:
                            usable.update(path)
                        for index, (left, right) in enumerate(edges):
                            if used_mask & (1 << index):
                                continue
                            if left == current:
                                nxt = right
                            elif right == current:
                                nxt = left
                            else:
                                continue
                            explore(nxt, used_mask | (1 << index), path + [nxt])

                    explore(start, 0, [start])
                    for building in usable:
                        waiting[building] = (waiting[building] + outsiders) % MOD
            else:
                swept = stream[position]
                position += 1
                total = (total + waiting[swept]) % MOD
                waiting[swept] = 0
        answers.append(total)
    return "".join(str(answer) + "\n" for answer in answers)


SAMPLE = """1
6 5 9
1 2
2 3
3 4
4 5
5 3
T 1 2 5
T 5 6 1000
S 2
S 6
T 2 3 1
T 5 3 14
S 1
S 2
S 4
"""
SAMPLE_OUT = "26\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 0 3\nS 1\nS 1\nS 1\n") == "0\n"
assert oracle("1\n2 1 3\n1 2\nT 1 2 7\nS 1\nS 2\n") == "14\n"
assert oracle("1\n3 0 4\nT 1 2 9\nS 1\nS 2\nS 3\n") == "0\n"
assert oracle("1\n3 2 3\n1 2\n2 3\nT 1 3 5\nS 2\nS 2\n") == "5\n"


def write(name, cases):
    lines = [str(len(cases))]
    for buildings, edges, events in cases:
        lines.append(f"{buildings} {len(edges)} {len(events)}")
        for left, right in edges:
            lines.append(f"{left} {right}")
        for event in events:
            lines.append(" ".join(str(part) for part in event))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_graph(rng, buildings):
    edges = []
    for child in range(2, buildings + 1):
        edges.append((child, rng.randint(1, child - 1)))
    extras = [(left, right) for left in range(1, buildings + 1)
              for right in range(left + 1, buildings + 1)
              if (left, right) not in edges and (right, left) not in edges]
    rng.shuffle(extras)
    edges.extend(extras[:rng.randint(0, 2)])
    return edges


def random_events(rng, buildings, count):
    events = []
    for _ in range(count):
        if rng.random() < 0.5:
            start = rng.randint(1, buildings)
            finish = rng.randint(1, buildings)
            while finish == start:
                finish = rng.randint(1, buildings)
            events.append(("T", start, finish, rng.randint(1, 1000)))
        else:
            events.append(("S", rng.randint(1, buildings)))
    return events


def build():
    write("2_edges", [
        (1, [], [("S", 1), ("S", 1)]),
        (2, [(1, 2)], [("T", 1, 2, 7), ("S", 1), ("S", 2)]),
        (3, [], [("T", 1, 3, 9), ("S", 1), ("S", 2)]),
        (3, [(1, 2), (2, 3)], [("T", 1, 3, 4), ("S", 2), ("S", 3)]),
    ])
    rng = random.Random(20261126)
    edges = random_graph(rng, 7)
    write("3_wide", [(7, edges, random_events(rng, 7, 24))])
    random_cases = []
    for _ in range(4):
        buildings = rng.randint(2, 7)
        random_cases.append((buildings, random_graph(rng, buildings),
                             random_events(rng, buildings, 16)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(6):
        buildings = rng.randint(2, 7)
        io_cases.append((buildings, random_graph(rng, buildings),
                         random_events(rng, buildings, 30)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
