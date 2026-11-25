#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def oracle(text):
    tokens = [int(value) for value in text.split()]
    city_count = tokens[0]
    road_count = tokens[1]
    roads = []
    position = 2
    for _ in range(road_count):
        start_city, end_city, pay_city, advance_price, arrival_price = tokens[position:position + 5]
        position += 5
        roads.append((start_city - 1, end_city - 1, pay_city - 1, advance_price, arrival_price))
    mask_count = 1 << road_count
    best = [[INF] * mask_count for _ in range(city_count)]
    best[0][0] = 0
    frontier = [(0, 0, 0)]
    while frontier:
        paid, city, mask = heapq.heappop(frontier)
        if paid != best[city][mask]:
            continue
        for road_index, (start_city, end_city, pay_city, advance_price, arrival_price) in enumerate(roads):
            road_bit = 1 << road_index
            if pay_city == city and not (mask & road_bit):
                next_mask = mask | road_bit
                next_paid = paid + advance_price
                if next_paid < best[city][next_mask]:
                    best[city][next_mask] = next_paid
                    heapq.heappush(frontier, (next_paid, city, next_mask))
            if start_city == city:
                next_paid = paid if (mask & road_bit) else paid + arrival_price
                if next_paid < best[end_city][mask]:
                    best[end_city][mask] = next_paid
                    heapq.heappush(frontier, (next_paid, end_city, mask))
    answer = min(best[city_count - 1])
    return "impossible\n" if answer >= INF else str(answer) + "\n"


SAMPLE = """4 5
1 2 1 10 10
2 3 1 30 50
3 4 3 80 80
2 1 2 10 10
1 3 2 10 50
"""
SAMPLE_OUT = """110
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 1\n1 2 1 5 7\n") == "5\n"
assert oracle("2 1\n1 2 2 5 7\n") == "7\n"
assert oracle("2 1\n2 1 1 5 7\n") == "impossible\n"
assert oracle("1 0\n") == "0\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "2 1\n2 1 1 5 7\n")
    lines = ["10 10"]
    for road_index in range(10):
        start_city = road_index + 1
        end_city = start_city % 10 + 1
        pay_city = (road_index * 3) % 10 + 1
        lines.append(f"{start_city} {end_city} {pay_city} {90 - road_index * 4} {100 + road_index * 20}")
    write("3_wide", "\n".join(lines) + "\n")
    rng = random.Random(20261126)
    city_count = rng.randint(3, 10)
    road_count = rng.randint(3, 10)
    lines = [f"{city_count} {road_count}"]
    for _ in range(road_count):
        lines.append(" ".join(str(rng.randint(1, city_count)) for _ in range(3)) +
                     f" {rng.randint(0, 100)} {rng.randint(0, 100)}")
    write("4_random", "\n".join(lines) + "\n")
    write("5_io", "10 1\n2 1 1 0 0\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
