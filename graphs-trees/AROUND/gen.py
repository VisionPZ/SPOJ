#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def signed_step(start_longitude, end_longitude):
    forward = (end_longitude - start_longitude) % 360
    return forward if forward < 180 else forward - 360


def adjacency(farm_count, longitudes, flights):
    graph = [[] for _ in range(farm_count + 1)]
    for departure, arrival in flights:
        graph[departure].append((arrival, signed_step(longitudes[departure], longitudes[arrival])))
        graph[arrival].append((departure, signed_step(longitudes[arrival], longitudes[departure])))
    return graph


def depth_search(graph, depth_limit, failed, farm, total, depth):
    if depth == depth_limit:
        return None
    state = (farm, total, depth)
    if state in failed:
        return None
    for neighbour, step in graph[farm]:
        updated = total + step
        if neighbour == 1 and updated != 0:
            return depth + 1
        answer = depth_search(graph, depth_limit, failed, neighbour, updated, depth + 1)
        if answer is not None:
            return answer
    failed.add(state)
    return None


def oracle(farm_count, longitudes, flights):
    graph = adjacency(farm_count, longitudes, flights)
    for depth_limit in range(1, 41):
        answer = depth_search(graph, depth_limit, set(), 1, 0, 0)
        if answer is not None:
            return answer
    return -1


def bounded_check(farm_count, longitudes, flights, cap=5000):
    graph = adjacency(farm_count, longitudes, flights)
    queue = deque([(1, 0, 0)])
    visited = {(1, 0)}
    while queue:
        farm, total, distance = queue.popleft()
        for neighbour, step in graph[farm]:
            updated = total + step
            if neighbour == 1 and updated != 0:
                return distance + 1
            if -cap <= updated <= cap and (neighbour, updated) not in visited:
                visited.add((neighbour, updated))
                queue.append((neighbour, updated, distance + 1))
    return -1


assert signed_step(0, 120) == 120
assert signed_step(350, 10) == 20
assert signed_step(350, 200) == -150
SAMPLE = (3, [0, 0, 120, 240], [(1, 2), (2, 3), (1, 3)])
assert oracle(*SAMPLE) == 3
assert bounded_check(*SAMPLE) == 3
assert oracle(2, [0, 0, 120], [(1, 2)]) == -1
RING = (5, [0, 0, 72, 144, 216, 288], [(1, 2), (2, 3), (3, 4), (4, 5), (5, 1)])
assert oracle(*RING) == 5
assert bounded_check(*RING) == 5
LONG_A = (8, [0, 276, 65, 176, 249, 6, 148, 168, 326],
          [(6, 4), (3, 7), (6, 8), (1, 2), (6, 3), (5, 7), (5, 8), (4, 5), (5, 2)])
LONG_B = (9, [0, 260, 60, 257, 89, 238, 332, 38, 107, 22],
          [(8, 6), (2, 7), (5, 8), (9, 8), (6, 3), (4, 3), (1, 9), (2, 6), (2, 4)])
assert oracle(*LONG_A) == 9
assert bounded_check(*LONG_A) == 9
assert oracle(*LONG_B) == 10
assert bounded_check(*LONG_B) == 10


def case_text(cases):
    lines = [str(len(cases))]
    for farm_count, longitudes, flights in cases:
        lines.append(f"{farm_count} {len(flights)}")
        lines.extend(str(longitudes[farm]) for farm in range(1, farm_count + 1))
        lines.extend(f"{departure} {arrival}" for departure, arrival in flights)
    return "\n".join(lines) + "\n"


def oracle_text(cases, cache):
    answers = []
    for case in cases:
        key = (case[0], tuple(case[1]), tuple(case[2]))
        if key not in cache:
            value = oracle(*case)
            assert value == bounded_check(*case), (key, value)
            assert value == -1 or value <= 12, key
            cache[key] = value
        answers.append(str(cache[key]))
    return "\n".join(answers) + "\n"


def write(name, cases, cache):
    (ROOT / "in" / f"{name}.txt").write_text(case_text(cases))
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(cases, cache))


def add_extra_flights(rng, farm_count, longitudes, flights, wanted):
    seen = {(min(u, v), max(u, v)) for u, v in flights}
    attempts = 0
    while len(flights) < wanted and attempts < 6000:
        attempts += 1
        departure = rng.randint(1, farm_count)
        arrival = rng.randint(1, farm_count)
        if departure == arrival:
            continue
        if (longitudes[departure] - longitudes[arrival]) % 360 in (0, 180):
            continue
        key = (min(departure, arrival), max(departure, arrival))
        if key in seen:
            continue
        seen.add(key)
        flights.append((departure, arrival))


def wide_triangle_case():
    rng = random.Random(24680)
    farm_count = 5000
    longitudes = [0] * (farm_count + 1)
    longitudes[1], longitudes[2], longitudes[3] = 0, 120, 240
    for farm in range(4, farm_count + 1):
        value = (farm * 7) % 360
        while value in (0, 120, 240):
            value = (value + 1) % 360
        longitudes[farm] = value
    flights = [(1, 2), (2, 3), (1, 3)]
    add_extra_flights(rng, farm_count, longitudes, flights, 25000)
    return farm_count, longitudes, flights


def wide_tree_case():
    farm_count = 5000
    longitudes = [0] + [(farm - 1) % 360 for farm in range(1, farm_count + 1)]
    flights = [(farm, farm + 1) for farm in range(1, farm_count)]
    return farm_count, longitudes, flights


def random_cases():
    rng = random.Random(20261125)
    cases = []
    for index in range(12):
        ring_size = 3 if index % 2 == 0 else 5
        step = 360 // ring_size
        farm_count = rng.randint(ring_size, min(10, ring_size + 5))
        longitudes = [0] + [(position - 1) * step for position in range(1, ring_size + 1)]
        for farm in range(ring_size + 1, farm_count + 1):
            longitudes.append(rng.randint(0, 359))
        flights = [(position, position + 1) for position in range(1, ring_size)]
        flights.append((ring_size, 1))
        wanted = rng.randint(len(flights), min(20, farm_count * (farm_count - 1) // 2))
        add_extra_flights(rng, farm_count, longitudes, flights, wanted)
        cases.append((farm_count, longitudes, flights))
    return cases


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
cache = {}
write("1_sample", [SAMPLE], cache)
write("2_edges", [
    (2, [0, 0, 120], [(1, 2)]),
    SAMPLE,
    (3, [0, 0, 120, 240], [(1, 2), (2, 3)]),
    (3, [0, 0, 100, 200], [(1, 2), (2, 3), (1, 3)]),
    (4, [0, 0, 120, 240, 60], [(1, 2), (2, 3), (1, 3), (1, 4)]),
], cache)
write("3_wide", [wide_triangle_case(), wide_tree_case()], cache)
write("4_random", random_cases() + [LONG_A, LONG_B], cache)
write("5_io", [SAMPLE] * 50000, cache)
print("generated", len(cache), "distinct oracle cases")
