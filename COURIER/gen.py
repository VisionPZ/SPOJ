#!/usr/bin/env python3
import heapq
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10**18


def parse(text):
    tokens = text.split()
    position = 0
    case_count = int(tokens[position]); position += 1
    cases = []
    for _ in range(case_count):
        city_count = int(tokens[position]); position += 1
        road_count = int(tokens[position]); position += 1
        home = int(tokens[position]); position += 1
        roads = []
        for _ in range(road_count):
            u = int(tokens[position]); position += 1
            v = int(tokens[position]); position += 1
            w = int(tokens[position]); position += 1
            roads.append((u, v, w))
        request_count = int(tokens[position]); position += 1
        requests = []
        for _ in range(request_count):
            u = int(tokens[position]); position += 1
            v = int(tokens[position]); position += 1
            c = int(tokens[position]); position += 1
            requests.append((u, v, c))
        cases.append((city_count, road_count, home, roads, requests))
    return cases


def build_adjacency(city_count, roads):
    adjacency = [[] for _ in range(city_count + 1)]
    for u, v, w in roads:
        adjacency[u].append((v, w))
        adjacency[v].append((u, w))
    return adjacency


def raw_route(city_count, home, roads, parcels):
    adjacency = build_adjacency(city_count, roads)
    parcel_total = len(parcels)
    full_mask = (1 << parcel_total) - 1
    best = {(0, -1, home): 0}
    heap = [(0, 0, -1, home)]
    while heap:
        cost, mask, carry, city = heapq.heappop(heap)
        if best[(mask, carry, city)] != cost:
            continue
        if mask == full_mask and carry == -1 and city == home:
            return cost
        for next_city, length in adjacency[city]:
            key = (mask, carry, next_city)
            new_cost = cost + length
            if new_cost < best.get(key, INF):
                best[key] = new_cost
                heapq.heappush(heap, (new_cost, mask, carry, next_city))
        if carry == -1:
            for i in range(parcel_total):
                if mask & (1 << i):
                    continue
                if city == parcels[i][0]:
                    key = (mask, i, city)
                    if cost < best.get(key, INF):
                        best[key] = cost
                        heapq.heappush(heap, (cost, mask, i, city))
        elif city == parcels[carry][1]:
            key = (mask | (1 << carry), -1, city)
            if cost < best.get(key, INF):
                best[key] = cost
                heapq.heappush(heap, (cost, mask | (1 << carry), -1, city))
    return INF


def subset_route(city_count, home, roads, parcels):
    adjacency = build_adjacency(city_count, roads)
    relevant = {home}
    for source, target in parcels:
        relevant.add(source)
        relevant.add(target)
    distances = {}
    for source in relevant:
        distance = [INF] * (city_count + 1)
        distance[source] = 0
        heap = [(0, source)]
        while heap:
            used, city = heapq.heappop(heap)
            if used != distance[city]:
                continue
            for next_city, length in adjacency[city]:
                candidate = used + length
                if candidate < distance[next_city]:
                    distance[next_city] = candidate
                    heapq.heappush(heap, (candidate, next_city))
        distances[source] = distance
    parcel_total = len(parcels)
    full_mask = (1 << parcel_total) - 1

    @lru_cache(maxsize=None)
    def search(mask, city):
        if mask == full_mask:
            return distances[city][home]
        best = INF
        for i in range(parcel_total):
            if mask & (1 << i):
                continue
            source, target = parcels[i]
            pickup = distances[city][source]
            if pickup >= INF:
                continue
            candidate = pickup + distances[source][target] + search(mask | (1 << i), target)
            if candidate < best:
                best = candidate
        return best

    return search(0, home)


def oracle(case):
    city_count, road_count, home, roads, requests = case
    parcels = []
    for source, target, count in requests:
        parcels.extend([(source, target)] * count)
    if not parcels:
        return 0
    answer = subset_route(city_count, home, roads, parcels)
    if len(parcels) <= 5 and city_count <= 15:
        direct = raw_route(city_count, home, roads, parcels)
        assert direct == answer, ("raw vs subset", direct, answer, case)
    return answer


def format_case(case):
    city_count, road_count, home, roads, requests = case
    lines = [f"{city_count} {road_count} {home}"]
    for u, v, w in roads:
        lines.append(f"{u} {v} {w}")
    lines.append(str(len(requests)))
    for u, v, c in requests:
        lines.append(f"{u} {v} {c}")
    return "\n".join(lines)


def emit(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(format_case(case) + "\n" for case in cases)
    answers = [str(oracle(case)) for case in cases]
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")


SAMPLE = (5, 7, 2,
          [(1, 2, 7), (1, 3, 5), (1, 5, 2), (2, 4, 10), (2, 5, 1), (3, 4, 3), (3, 5, 4)],
          [(1, 4, 2), (5, 3, 1), (5, 1, 1)])

assert oracle(SAMPLE) == 43
assert oracle((1, 1, 1, [(1, 1, 7)], [(1, 1, 1)])) == 0
assert oracle((3, 2, 1, [(1, 2, 3), (2, 3, 4)], [(1, 3, 1)])) == 14
assert parse("1\n5 7 2\n1 2 7\n1 3 5\n1 5 2\n2 4 10\n2 5 1\n3 4 3\n3 5 4\n3\n1 4 2\n5 3 1\n5 1 1\n") == [SAMPLE]


def build_edges():
    return [
        (1, 1, 1, [(1, 1, 7)], [(1, 1, 1)]),
        (3, 3, 1, [(1, 2, 5), (2, 3, 5), (1, 3, 9)], [(2, 2, 1)]),
        (3, 2, 1, [(1, 2, 3), (2, 3, 4)], [(1, 3, 1)]),
        (5, 6, 5, [(1, 2, 2), (2, 3, 2), (3, 4, 2), (4, 5, 2), (5, 1, 2), (1, 3, 9)],
         [(2, 4, 2), (2, 4, 2), (2, 4, 2), (2, 4, 2), (2, 4, 2), (2, 4, 2)]),
        (4, 5, 1, [(1, 2, 2), (2, 3, 2), (3, 4, 2), (4, 1, 2), (1, 3, 5)],
         [(4, 1, 1), (4, 1, 1)]),
    ]


def build_wide(seed):
    rng = random.Random(seed)
    city_count = 100
    road_count = 10000
    roads = []
    for city in range(2, city_count + 1):
        roads.append((city - 1, city, rng.randint(1, 10000)))
    while len(roads) < road_count:
        roads.append((rng.randint(1, city_count), rng.randint(1, city_count), rng.randint(1, 10000)))
    requests = [(rng.randint(1, city_count), rng.randint(1, city_count), count)
                for count in (3, 3, 2, 2, 2)]
    return (city_count, road_count, city_count, roads, requests)


def build_random():
    rng = random.Random(20261124)
    cases = []
    for _ in range(36):
        city_count = rng.randint(3, 40)
        road_count = rng.randint(city_count, min(300, city_count * 4))
        home = rng.randint(1, city_count)
        roads = []
        for city in range(2, city_count + 1):
            roads.append((rng.randint(1, city - 1), city, rng.randint(1, 10000)))
        while len(roads) < road_count:
            roads.append((rng.randint(1, city_count), rng.randint(1, city_count), rng.randint(1, 10000)))
        parcel_total = rng.randint(1, 12)
        request_count = rng.randint(1, min(5, parcel_total))
        counts = [1] * request_count
        remaining = parcel_total - request_count
        while remaining:
            add = min(remaining, rng.randint(1, 4))
            counts[rng.randrange(request_count)] += add
            remaining -= add
        requests = [(rng.randint(1, city_count), rng.randint(1, city_count), count)
                    for count in counts]
        cases.append((city_count, road_count, home, roads, requests))
    return cases


def build_io():
    rng = random.Random(7)
    cases = []
    for _ in range(60000):
        roads = [(1, 2, rng.randint(1, 10000)),
                 (2, 3, rng.randint(1, 10000)),
                 (1, 3, rng.randint(1, 10000))]
        requests = [(2, 3, 1)]
        cases.append((3, 3, 1, roads, requests))
    return cases


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
emit("1_sample", [SAMPLE])
emit("2_edges", build_edges())
emit("3_wide", [build_wide(101), build_wide(202)])
emit("4_random", build_random())
emit("5_io", build_io())
