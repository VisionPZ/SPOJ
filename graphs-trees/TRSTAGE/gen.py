#!/usr/bin/env python3
import random
from fractions import Fraction
from heapq import heappop, heappush
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    values = [int(value) for value in text.split()]
    pos = 0
    answers = []
    while pos + 5 <= len(values):
        ticket_count, city_count, road_count, start_city, target_city = values[pos:pos + 5]
        pos += 5
        if (ticket_count, city_count, road_count, start_city, target_city) == (0, 0, 0, 0, 0):
            break
        tickets = values[pos:pos + ticket_count]
        pos += ticket_count
        adjacency = [[] for _ in range(city_count + 1)]
        for _ in range(road_count):
            first_city, second_city, road_length = values[pos:pos + 3]
            pos += 3
            adjacency[first_city].append((second_city, Fraction(road_length)))
            adjacency[second_city].append((first_city, Fraction(road_length)))
        infinity = Fraction(10 ** 12)
        distances = {(0, start_city): Fraction(0)}
        heap = [(Fraction(0), 0, start_city)]
        while heap:
            current_time, used_mask, current_city = heappop(heap)
            if current_time != distances[(used_mask, current_city)]:
                continue
            for ticket_index, horses in enumerate(tickets):
                if (used_mask >> ticket_index) & 1:
                    continue
                next_mask = used_mask | (1 << ticket_index)
                for neighbor_city, road_length in adjacency[current_city]:
                    next_time = current_time + Fraction(road_length, horses)
                    key = (next_mask, neighbor_city)
                    if next_time < distances.get(key, infinity):
                        distances[key] = next_time
                        heappush(heap, (next_time, next_mask, neighbor_city))
        best = None
        for (used_mask, city), total_time in distances.items():
            if city == target_city and (best is None or total_time < best):
                best = total_time
        if best is None:
            answers.append("Impossible")
        else:
            rounded = best * 1000 + Fraction(1, 2)
            thousandths = rounded.numerator // rounded.denominator
            answers.append(f"{thousandths // 1000}.{thousandths % 1000:03d}")
    return "\n".join(answers) + ("\n" if answers else "")


SAMPLE = """3 4 3 1 4
3 1 2
1 2 10
2 3 30
3 4 20
2 4 4 2 1
3 1
2 3 3
1 3 3
4 1 2
4 2 5
2 4 3 4 1
5 5
1 2 10
2 3 10
3 4 10
1 2 0 1 2
1
8 5 10 1 5
2 7 1 8 4 5 6 3
1 2 5
2 3 4
3 4 7
4 5 3
1 3 25
2 4 23
3 5 22
1 4 45
2 5 51
1 5 99
0 0 0 0 0
"""
SAMPLE_OUT = """30.000
3.667
Impossible
Impossible
2.856
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 2 1 1 2\n5\n1 2 10\n0 0 0 0 0\n") == "2.000\n"
assert oracle("1 2 0 1 2\n5\n0 0 0 0 0\n") == "Impossible\n"
assert oracle("2 2 1 1 2\n1 2\n1 2 7\n0 0 0 0 0\n") == "3.500\n"
assert oracle("2 3 2 1 3\n3 1\n1 2 9\n2 3 9\n0 0 0 0 0\n") == "12.000\n"


def emit(name, datasets):
    text = "".join(datasets) + "0 0 0 0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def dataset(tickets, city_count, roads, start_city, target_city):
    parts = [f"{len(tickets)} {city_count} {len(roads)} {start_city} {target_city}\n"]
    parts.append(" ".join(str(value) for value in tickets) + "\n")
    for first_city, second_city, length in roads:
        parts.append(f"{first_city} {second_city} {length}\n")
    return "".join(parts)


def build():
    emit("2_edges", [
        dataset([5], 2, [(1, 2, 10)], 1, 2),
        dataset([1], 2, [(1, 2, 7)], 1, 2),
        dataset([1], 2, [], 1, 2),
        dataset([1, 1], 3, [(1, 2, 3), (2, 3, 4)], 1, 3),
        dataset([2, 3], 3, [(1, 3, 6)], 1, 3),
    ])
    rng = random.Random(20261122)
    roads = []
    for first_city in range(1, 31):
        for second_city in range(first_city + 1, min(31, first_city + 4)):
            roads.append((first_city, second_city, rng.randint(1, 100)))
    emit("3_wide", [dataset([rng.randint(1, 10) for _ in range(8)], 30, roads, 1, 30)])
    random_sets = []
    for _ in range(6):
        city_count = rng.randint(3, 12)
        road_list = []
        for first_city in range(1, city_count + 1):
            for second_city in range(first_city + 1, city_count + 1):
                if rng.random() < 0.3:
                    road_list.append((first_city, second_city, rng.randint(1, 100)))
        ticket_count = rng.randint(1, 8)
        random_sets.append(dataset([rng.randint(1, 10) for _ in range(ticket_count)],
                                   city_count, road_list, 1, city_count))
    emit("4_random", random_sets)
    io_sets = []
    for case_index in range(80):
        ticket_count = 1 + case_index % 3
        tickets = [1 + ((case_index + offset) % 10) for offset in range(ticket_count)]
        io_sets.append(dataset(tickets, 2, [(1, 2, 1 + case_index % 100)], 1, 2))
    emit("5_io", io_sets)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
emit("1_sample", [SAMPLE[:-len("0 0 0 0 0\n")]])
build()
