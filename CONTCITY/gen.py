#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def oracle_case(place_count, roads, helis, survivor_counts):
    distances = [[INF] * (place_count + 1) for _ in range(place_count + 1)]
    for place in range(1, place_count + 1):
        distances[place][place] = 0
    for first, second, travel in roads:
        if travel < distances[first][second]:
            distances[first][second] = distances[second][first] = travel
    for via in range(1, place_count + 1):
        for source in range(1, place_count + 1):
            if distances[source][via] == INF:
                continue
            for target in range(1, place_count + 1):
                if distances[via][target] < INF and distances[source][target] > distances[source][via] + distances[via][target]:
                    distances[source][target] = distances[source][via] + distances[via][target]
    total = sum(survivor_counts)
    rescue = {}
    for place in range(1, place_count + 1):
        for heli_index, (day, heli_place, _) in enumerate(helis):
            walking = distances[place][heli_place]
            if walking < INF:
                rescue[(place, heli_index)] = max(day, walking)

    def flow_for(day_limit):
        node_count = place_count + len(helis) + 2
        source = 0
        sink = node_count - 1
        capacity = [[0] * node_count for _ in range(node_count)]
        for place in range(1, place_count + 1):
            capacity[source][place] = survivor_counts[place]
            for heli_index in range(len(helis)):
                if rescue.get((place, heli_index), INF) <= day_limit:
                    capacity[place][place_count + 1 + heli_index] = survivor_counts[place]
        for heli_index, (_, _, helicopter_capacity) in enumerate(helis):
            capacity[place_count + 1 + heli_index][sink] = helicopter_capacity
        flow = 0
        while True:
            previous = [-1] * node_count
            previous[source] = source
            queue = [source]
            for node in queue:
                for target in range(node_count):
                    if capacity[node][target] > 0 and previous[target] == -1:
                        previous[target] = node
                        queue.append(target)
            if previous[sink] == -1:
                break
            push = INF
            node = sink
            while node != source:
                parent = previous[node]
                push = min(push, capacity[parent][node])
                node = parent
            node = sink
            while node != source:
                parent = previous[node]
                capacity[parent][node] -= push
                capacity[node][parent] += push
                node = parent
            flow += push
        return flow

    candidates = {0, 1000}
    for value in rescue.values():
        candidates.add(value)
    for day in sorted(candidates):
        if flow_for(day) == total:
            return f"All people can be rescued in {day} day(s)."
    return f"{flow_for(1000)} survivor(s) can be rescued."


def oracle(text):
    tokens = [int(value) for value in text.split()]
    pos = 0
    test_count = tokens[pos]
    pos += 1
    answers = []
    for _ in range(test_count):
        place_count = tokens[pos]
        road_count = tokens[pos + 1]
        helicopter_count = tokens[pos + 2]
        pos += 3
        survivors = [0] + tokens[pos:pos + place_count]
        pos += place_count
        roads = []
        for _ in range(road_count):
            roads.append(tuple(tokens[pos:pos + 3]))
            pos += 3
        helis = []
        for _ in range(helicopter_count):
            helis.append(tuple(tokens[pos:pos + 3]))
            pos += 3
        answers.append(oracle_case(place_count, roads, helis, survivors))
    return "\n".join(answers) + "\n" if answers else ""


SAMPLE = """2
4 4 4
3 4 5 6
1 2 7
2 3 3
3 4 3
4 1 4
4 4 7
6 3 2
5 2 3
3 1 6
4 2 3
2 2 3 1
1 4 3
2 3 3
2 4 2
3 2 4
3 3 2
"""
SAMPLE_OUT = """All people can be rescued in 6 day(s).
7 survivor(s) can be rescued.
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1 1\n0\n1 1 1\n1 1 1\n") == "All people can be rescued in 0 day(s).\n"
assert oracle("1\n3 1 1\n5 0 0\n1 2 4\n4 3 200\n") == "0 survivor(s) can be rescued.\n"
assert oracle("1\n1 1 2\n5\n1 1 1\n3 1 2\n4 1 3\n") == "All people can be rescued in 4 day(s).\n"
assert 6 == max(4, 6)


def write_case(name, cases):
    text = str(len(cases)) + "\n"
    for place_count, roads, helis, survivors in cases:
        text += f"{place_count} {len(roads)} {len(helis)}\n"
        text += " ".join(str(value) for value in survivors) + "\n"
        for road in roads:
            text += " ".join(str(value) for value in road) + "\n"
        for heli in helis:
            text += " ".join(str(value) for value in heli) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [
        (1, [(1, 1, 1)], [(1, 1, 1)], [0]),
        (3, [(1, 2, 4)], [(4, 3, 200)], [5, 0, 0]),
        (1, [(1, 1, 1)], [(3, 1, 2), (4, 1, 3)], [5]),
        (2, [(1, 2, 3)], [(2, 2, 2), (5, 1, 2)], [3, 1]),
    ])
    rng = random.Random(20261126)
    wide_roads = [(index, index + 1, rng.randint(1, 10)) for index in range(1, 50)]
    while len(wide_roads) < 1500:
        first = rng.randint(1, 50)
        second = rng.randint(1, 50)
        if first != second:
            wide_roads.append((first, second, rng.randint(1, 10)))
    wide_survivors = [rng.randint(0, 4) for _ in range(50)]
    wide_helis = [(rng.randint(1, 50), rng.randint(1, 50), rng.randint(1, 20)) for _ in range(50)]
    write_case("3_wide", [(50, wide_roads, wide_helis, wide_survivors)])
    random_cases = []
    for _ in range(15):
        place_count = rng.randint(2, 10)
        roads = [(index, index + 1, rng.randint(1, 8)) for index in range(1, place_count)]
        for _ in range(rng.randint(0, 20)):
            first = rng.randint(1, place_count)
            second = rng.randint(1, place_count)
            if first != second:
                roads.append((first, second, rng.randint(1, 8)))
        helis = [(rng.randint(1, 30), rng.randint(1, place_count), rng.randint(1, 8))
                 for _ in range(rng.randint(1, 8))]
        survivors = [rng.randint(0, 3) for _ in range(place_count)]
        random_cases.append((place_count, roads, helis, survivors))
    write_case("4_random", random_cases)
    io_cases = []
    for _ in range(4000):
        place_count = rng.randint(2, 5)
        roads = [(index, index + 1, rng.randint(1, 5)) for index in range(1, place_count)]
        helis = [(rng.randint(1, 20), rng.randint(1, place_count), rng.randint(1, 5))
                 for _ in range(rng.randint(1, 3))]
        survivors = [rng.randint(0, 3) for _ in range(place_count)]
        io_cases.append((place_count, roads, helis, survivors))
    write_case("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", [
    (4, [(1, 2, 7), (2, 3, 3), (3, 4, 3), (4, 1, 4)],
     [(4, 4, 7), (6, 3, 2), (5, 2, 3), (3, 1, 6)], [3, 4, 5, 6]),
    (4, [(1, 4, 3), (2, 3, 3)], [(2, 4, 2), (3, 2, 4), (3, 3, 2)], [2, 2, 3, 1]),
])
build()
