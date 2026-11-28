#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(budget, city_count, roads_by_source):
    levels = budget + 1
    infinity = 10 ** 18
    distances = [infinity] * (city_count * levels)
    distances[0] = 0
    queue = [(0, 0, 0)]
    while queue:
        length, city, toll = heapq.heappop(queue)
        slot = city * levels + toll
        if length != distances[slot]:
            continue
        for dest, road_length, road_toll in roads_by_source[city]:
            next_toll = toll + road_toll
            if next_toll > budget:
                continue
            candidate = length + road_length
            next_slot = dest * levels + next_toll
            if candidate < distances[next_slot]:
                distances[next_slot] = candidate
                heapq.heappush(queue, (candidate, dest, next_toll))
    answer = min(distances[(city_count - 1) * levels + spent] for spent in range(levels))
    return -1 if answer >= infinity else answer


def brute_case(budget, city_count, roads):
    best = [None]

    def walk(city, toll, length, seen):
        if city == city_count - 1 and (best[0] is None or length < best[0]):
            best[0] = length
        for source, dest, road_length, road_toll in roads:
            if source == city and toll + road_toll <= budget and dest not in seen:
                seen.add(dest)
                walk(dest, toll + road_toll, length + road_length, seen)
                seen.remove(dest)

    walk(0, 0, 0, {0})
    return -1 if best[0] is None else best[0]


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        budget = int(tokens[cursor]); cursor += 1
        city_count = int(tokens[cursor]); cursor += 1
        road_count = int(tokens[cursor]); cursor += 1
        roads = []
        roads_by_source = [[] for _ in range(city_count)]
        for _ in range(road_count):
            source = int(tokens[cursor]) - 1; cursor += 1
            dest = int(tokens[cursor]) - 1; cursor += 1
            road_length = int(tokens[cursor]); cursor += 1
            road_toll = int(tokens[cursor]); cursor += 1
            roads.append((source, dest, road_length, road_toll))
            roads_by_source[source].append((dest, road_length, road_toll))
        answers.append(str(oracle_case(budget, city_count, roads_by_source)))
    return "\n".join(answers) + "\n"


def case_text(cases):
    body = [str(len(cases)) + "\n"]
    for budget, city_count, roads in cases:
        body.append(f"{budget}\n{city_count}\n{len(roads)}\n")
        for source, dest, road_length, road_toll in roads:
            body.append(f"{source} {dest} {road_length} {road_toll}\n")
    return "".join(body)


def write(name, cases):
    input_text = case_text(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [
    (5, 6, [(1, 2, 2, 3), (2, 4, 3, 3), (3, 4, 2, 4), (1, 3, 4, 1), (4, 6, 2, 1),
            (3, 5, 2, 0), (5, 4, 3, 2)]),
    (0, 4, [(1, 4, 5, 2), (1, 2, 1, 0), (2, 3, 1, 1), (3, 4, 1, 0)]),
]

assert oracle(case_text(SAMPLE)) == "11\n-1\n"
assert oracle_case(0, 3, [[(1, 1, 0)], [(2, 1, 0)], []]) == 2
assert oracle_case(5, 2, [[(1, 9, 5), (1, 4, 5)], []]) == 4
assert brute_case(5, 6, [(s - 1, d - 1, l, t) for s, d, l, t in SAMPLE[0][2]]) == 11
assert brute_case(0, 4, [(s - 1, d - 1, l, t) for s, d, l, t in SAMPLE[1][2]]) == -1

cross_check = random.Random(4242)
for _ in range(200):
    city_count = cross_check.randint(2, 5)
    budget = cross_check.randint(0, 8)
    roads = [(cross_check.randint(1, city_count), cross_check.randint(1, city_count),
              cross_check.randint(1, 6), cross_check.randint(0, 4))
             for _ in range(cross_check.randint(1, 8))]
    by_source = [[] for _ in range(city_count)]
    for source, dest, road_length, road_toll in roads:
        by_source[source - 1].append((dest - 1, road_length, road_toll))
    assert oracle_case(budget, city_count, by_source) == brute_case(
        budget, city_count, [(s - 1, d - 1, l, t) for s, d, l, t in roads])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)

edges = [
    (0, 2, [(1, 2, 7, 0)]),
    (0, 2, [(1, 2, 5, 1)]),
    (10000, 2, [(1, 2, 100, 100)]),
    (5, 3, [(1, 2, 2, 5), (2, 3, 3, 0)]),
    (0, 3, [(1, 2, 1, 0), (2, 3, 1, 0), (1, 3, 10, 0)]),
    (10, 3, [(1, 2, 1, 10), (2, 3, 1, 10)]),
    (5, 2, [(1, 2, 9, 5), (1, 2, 4, 5)]),
    (0, 4, [(1, 4, 5, 2), (1, 2, 1, 0), (2, 3, 1, 1), (3, 4, 1, 0)]),
]
write("2_edges", edges)

wide_rng = random.Random(7007)
wide_roads = [(wide_rng.randint(1, 100), wide_rng.randint(1, 100),
               wide_rng.randint(1, 100), wide_rng.randint(50, 100))
              for _ in range(9901)]
wide_roads += [(city, city + 1, 1, wide_rng.randint(0, 100)) for city in range(1, 100)]
free_roads = [(wide_rng.randint(1, 100), wide_rng.randint(1, 100),
               wide_rng.randint(1, 100), 0) for _ in range(10000)]
write("3_wide", [(10000, 100, wide_roads), (0, 100, free_roads)])

random_rng = random.Random(20261125)
random_cases = []
for _ in range(30):
    city_count = random_rng.randint(2, 20)
    budget = random_rng.randint(0, 100)
    roads = [(random_rng.randint(1, city_count), random_rng.randint(1, city_count),
              random_rng.randint(1, 100), random_rng.randint(0, 100))
             for _ in range(random_rng.randint(1, 100))]
    random_cases.append((budget, city_count, roads))
write("4_random", random_cases)

io_rng = random.Random(31337)
io_cases = [(0, 2, [(1, 2, io_rng.randint(1, 100), 0)]) for _ in range(20000)]
write("5_io", io_cases)

print("generated", len(random_cases), "random cases")
