#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
GRID_METERS = 200


class Dinic:
    def __init__(self, size):
        self.graph = [[] for _ in range(size)]

    def add_edge(self, source, target, capacity):
        self.graph[source].append([target, capacity, len(self.graph[target])])
        self.graph[target].append([source, 0, len(self.graph[source]) - 1])

    def max_flow(self, source, sink):
        total = 0
        while True:
            level = [-1] * len(self.graph)
            level[source] = 0
            queue = [source]
            head = 0
            while head < len(queue):
                node = queue[head]
                head += 1
                for edge in self.graph[node]:
                    if edge[1] > 0 and level[edge[0]] < 0:
                        level[edge[0]] = level[node] + 1
                        queue.append(edge[0])
            if level[sink] < 0:
                return total
            cursor = [0] * len(self.graph)

            def push(node, amount):
                if node == sink:
                    return amount
                while cursor[node] < len(self.graph[node]):
                    edge = self.graph[node][cursor[node]]
                    target = edge[0]
                    if edge[1] > 0 and level[target] == level[node] + 1:
                        moved = push(target, min(amount, edge[1]))
                        if moved > 0:
                            edge[1] -= moved
                            self.graph[target][edge[2]][1] += moved
                            return moved
                    cursor[node] += 1
                return 0

            while True:
                moved = push(source, 10**9)
                if moved == 0:
                    break
                total += moved


def brute_matching(edges, person_count, taxi_count):
    partner = [-1] * taxi_count

    def visit(person, seen):
        for taxi in edges[person]:
            if not seen[taxi]:
                seen[taxi] = True
                if partner[taxi] == -1 or visit(partner[taxi], seen):
                    partner[taxi] = person
                    return True
        return False

    matched = 0
    for person in range(person_count):
        if visit(person, [False] * taxi_count):
            matched += 1
    return matched


def oracle_case(persons, taxis, speed, seconds):
    person_count = len(persons)
    taxi_count = len(taxis)
    source = 0
    person_base = 1
    taxi_base = 1 + person_count
    sink = 1 + person_count + taxi_count
    network = Dinic(sink + 1)
    for person in range(person_count):
        network.add_edge(source, person_base + person, 1)
    for taxi in range(taxi_count):
        network.add_edge(taxi_base + taxi, sink, 1)
    edges = [[] for _ in range(person_count)]
    reach = speed * seconds
    for person, (person_x, person_y) in enumerate(persons):
        for taxi, (taxi_x, taxi_y) in enumerate(taxis):
            if GRID_METERS * (abs(person_x - taxi_x) + abs(person_y - taxi_y)) <= reach:
                edges[person].append(taxi)
                network.add_edge(person_base + person, taxi_base + taxi, 1)
    return network.max_flow(source, sink)


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        person_count = int(tokens[cursor])
        taxi_count = int(tokens[cursor + 1])
        speed = int(tokens[cursor + 2])
        seconds = int(tokens[cursor + 3])
        cursor += 4
        persons = []
        for _ in range(person_count):
            persons.append((int(tokens[cursor]), int(tokens[cursor + 1])))
            cursor += 2
        taxis = []
        for _ in range(taxi_count):
            taxis.append((int(tokens[cursor]), int(tokens[cursor + 1])))
            cursor += 2
        answers.append(str(oracle_case(persons, taxis, speed, seconds)))
    return "\n".join(answers) + "\n"


def encode(cases):
    lines = [str(len(cases))]
    for persons, taxis, speed, seconds in cases:
        lines.append(f"{len(persons)} {len(taxis)} {speed} {seconds}")
        for point_x, point_y in persons:
            lines.append(f"{point_x} {point_y}")
        for point_x, point_y in taxis:
            lines.append(f"{point_x} {point_y}")
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = encode(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [([(2, 5), (5, 2)], [(2, 3), (4, 1), (4, 4)], 10, 40)]
SAMPLE_TEXT = "1\n2 3 10 40\n2 5\n5 2\n2 3\n4 1\n4 4\n"

assert oracle(SAMPLE_TEXT) == "2\n"
assert oracle(encode(SAMPLE)) == "2\n"
assert oracle_case([(0, 0)] * 4, [(1, 1)] * 2, 2000, 1000000) == 2
assert oracle_case([(0, 0)] * 3, [(100000, 0)] * 2, 1, 1) == 0

rng = random.Random(20261125)
for _ in range(250):
    person_count = rng.randint(1, 7)
    taxi_count = rng.randint(1, 7)
    persons = [(rng.randint(-8, 8), rng.randint(-8, 8)) for _ in range(person_count)]
    taxis = [(rng.randint(-8, 8), rng.randint(-8, 8)) for _ in range(taxi_count)]
    speed = rng.randint(1, 800)
    seconds = rng.randint(1, 12)
    reach = speed * seconds
    edges = [[] for _ in range(person_count)]
    for person, (person_x, person_y) in enumerate(persons):
        for taxi, (taxi_x, taxi_y) in enumerate(taxis):
            if GRID_METERS * (abs(person_x - taxi_x) + abs(person_y - taxi_y)) <= reach:
                edges[person].append(taxi)
    assert oracle_case(persons, taxis, speed, seconds) == brute_matching(edges, person_count, taxi_count)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)

write("2_edges", [
    ([(0, 0)], [(0, 0)], 1, 1),
    ([(0, 0)], [(1, 0)], 1, 1),
    ([(0, 0)], [(3, 0)], 200, 3),
    ([(0, 0)], [(4, 0)], 200, 3),
    ([(0, 0), (1, 1), (2, 2)], [(0, 0), (1, 1), (2, 2)], 200, 4),
    ([(-5, -5), (-4, -4)], [(-5, -5), (-4, -4)], 200, 1),
    ([(5, 7)], [(5, 7), (1000000, 1000000)], 1, 1),
])

wide = []
for group in range(8):
    persons = []
    taxis = []
    for index in range(400):
        persons.append(((index * 37 + group * 11) % 10000000, (index * 53 + group * 7) % 10000000))
    for index in range(200):
        taxis.append(((index * 61 + group * 13) % 10000000, (index * 97 + group * 3) % 10000000))
    wide.append((persons, taxis, 2000, 1000000))
for group in range(2):
    persons = [(rng.randint(0, 10**9), rng.randint(0, 10**9)) for _ in range(400)]
    taxis = [(rng.randint(0, 10**9), rng.randint(0, 10**9)) for _ in range(200)]
    wide.append((persons, taxis, 2000, 1000000))
write("3_wide", wide)

random_cases = []
for _ in range(24):
    person_count = rng.randint(1, 400)
    taxi_count = rng.randint(1, 200)
    persons = [(rng.randint(-10**6, 10**6), rng.randint(-10**6, 10**6)) for _ in range(person_count)]
    taxis = [(rng.randint(-10**6, 10**6), rng.randint(-10**6, 10**6)) for _ in range(taxi_count)]
    random_cases.append((persons, taxis, rng.randint(1, 2000), rng.randint(1, 1000000)))
write("4_random", random_cases)

io_cases = []
for _ in range(250):
    persons = [(rng.randint(0, 1000), rng.randint(0, 1000)) for _ in range(200)]
    taxis = [(rng.randint(0, 1000), rng.randint(0, 1000)) for _ in range(100)]
    io_cases.append((persons, taxis, 100, 100))
write("5_io", io_cases)

print("generated five test pairs")
