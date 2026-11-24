#!/usr/bin/env python3
import random

from pathlib import Path

ROOT = Path(__file__).resolve().parent
DAY_MINUTES = 1440
INF = 10 ** 9


def minutes(text):
    return int(text[:2]) * 60 + int(text[3:5])


def clock(value):
    return "%02d:%02d" % (value // 60, value % 60)


def parse(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    cases = []
    for _ in range(case_count):
        city_count = int(tokens[cursor])
        cursor += 1
        trains = []
        for source_city in range(1, city_count + 1):
            position_count = int(tokens[cursor])
            cursor += 1
            for _ in range(position_count):
                first = minutes(tokens[cursor])
                second = minutes(tokens[cursor + 1])
                target = int(tokens[cursor + 2])
                cursor += 3
                trains.append((source_city, first, second, target))
        cases.append((city_count, trains))
    return cases


def oracle(text):
    answers = []
    for city_count, trains in parse(text):
        used = {1, city_count}
        for source_city, _, _, target in trains:
            used.add(source_city)
            used.add(target)
        ids = {city: index + 1 for index, city in enumerate(sorted(used))}
        size = len(ids)
        table = [[INF] * (DAY_MINUTES + 2) for _ in range(size + 1)]
        destination = ids[city_count]
        for time_value in range(DAY_MINUTES):
            table[destination][time_value + 1] = time_value
        departures = [{} for _ in range(size + 1)]
        for source_city, first, second, target in trains:
            departures[ids[source_city]].setdefault(first, []).append((second, ids[target]))
        source = ids[1]
        for time_value in range(DAY_MINUTES - 1, -1, -1):
            for city_id in range(1, size + 1):
                if city_id == destination:
                    continue
                value = table[city_id][time_value + 2]
                for second, target_id in departures[city_id].get(time_value, ()):
                    candidate = table[target_id][second + 1]
                    if candidate < value:
                        value = candidate
                table[city_id][time_value + 1] = value
        answers.append(format_frontier(table[source][1:DAY_MINUTES + 1]))
    return "\n".join(answers) + "\n"


def format_frontier(source_row):
    best_seen = INF
    frontier = []
    for time_value in range(DAY_MINUTES - 1, -1, -1):
        arrival = source_row[time_value]
        if arrival < best_seen:
            frontier.append((time_value, arrival))
            best_seen = arrival
    frontier.reverse()
    lines = [str(len(frontier))]
    for first, second in frontier:
        lines.append(clock(first) + " " + clock(second))
    return "\n".join(lines)


def brute(text):
    answers = []
    for city_count, trains in parse(text):
        by_source = [[] for _ in range(city_count + 1)]
        for source_city, first, second, target in trains:
            by_source[source_city].append((first, second, target))
        values = []
        for start_time in range(DAY_MINUTES):
            stack = [(1, start_time, 0)]
            visited = set()
            best = INF
            while stack:
                city, moment, depth = stack.pop()
                if city == city_count:
                    if moment < best:
                        best = moment
                    continue
                if depth >= 8 or (city, moment) in visited:
                    continue
                visited.add((city, moment))
                for first, second, target in by_source[city]:
                    if first >= moment:
                        stack.append((target, second, depth + 1))
            values.append(best)
        best_seen = INF
        frontier = []
        for time_value in range(DAY_MINUTES - 1, -1, -1):
            if values[time_value] < best_seen:
                frontier.append((time_value, values[time_value]))
                best_seen = values[time_value]
        frontier.reverse()
        lines = [str(len(frontier))]
        for first, second in frontier:
            lines.append(clock(first) + " " + clock(second))
        answers.append("\n".join(lines))
    return "\n".join(answers) + "\n"


def render(cases):
    blocks = [str(len(cases))]
    for city_count, trains in cases:
        blocks.append(str(city_count))
        by_source = [[] for _ in range(city_count + 1)]
        for source_city, first, second, target in trains:
            by_source[source_city].append((first, second, target))
        for source_city in range(1, city_count + 1):
            positions = sorted(by_source[source_city], key=lambda item: (item[0], item[1]))
            blocks.append(str(len(positions)))
            for first, second, target in positions:
                blocks.append(clock(first) + " " + clock(second) + " " + str(target))
    return "\n".join(blocks) + "\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


SAMPLE = """1
3
3
09:00 15:00 3
10:00 12:00 2
11:00 20:00 3
2
11:30 13:00 3
12:30 14:00 3
0
"""
SAMPLE_OUT = "2\n10:00 14:00\n11:00 20:00\n"

assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
tiny = render([(2, [(1, 540, 600, 2)])])
assert oracle(tiny) == "1\n09:00 10:00\n"
assert brute(tiny) == "1\n09:00 10:00\n"
simple_cycle = render([(3, [(1, 480, 540, 2), (2, 540, 600, 1), (1, 600, 660, 3)])])
assert oracle(simple_cycle) == brute(simple_cycle) == "1\n10:00 11:00\n"


def build_edges():
    cases = []
    cases.append((2, [(1, 540, 600, 2)]))
    cases.append((2, []))
    cases.append((3, [(1, 480, 720, 3), (1, 540, 600, 2), (2, 600, 630, 3)]))
    cases.append((3, [(1, 600, 660, 3), (1, 600, 690, 3)]))
    cases.append((2, [(1, 1438, 1439, 2)]))
    cases.append((3, [(1, 480, 540, 2), (2, 540, 600, 1), (1, 600, 660, 3)]))
    cases.append((4, [(1, 300, 400, 2), (2, 401, 450, 3), (3, 451, 500, 4), (1, 0, 1000, 4)]))
    cases.append((2, [(1, 720, 725, 2), (1, 700, 705, 2), (1, 740, 745, 2)]))
    return cases


def build_wide():
    cases = []
    cases.append((100000, [(1, 0, 1, 100000)]))
    cases.append((100000, [(99999, 720, 750, 100000), (1, 0, 720, 99999)]))
    cases.append((2, [(1, minute, minute + 1, 2) for minute in range(DAY_MINUTES - 1)]))
    cases.append((2, [(1, minute, DAY_MINUTES - 1, 2) for minute in range(0, 200)]))
    return cases


def build_random():
    cases = []
    rng = random.Random(20261124)
    for _ in range(24):
        city_count = rng.randint(2, 48)
        count = rng.randint(0, 300)
        trains = []
        for _ in range(count):
            source_city = rng.randint(1, city_count)
            target = rng.randint(1, city_count)
            first = rng.randint(0, DAY_MINUTES - 2)
            second = rng.randint(first + 1, DAY_MINUTES - 1)
            trains.append((source_city, first, second, target))
        cases.append((city_count, trains))
    return cases


def build_io():
    cases = []
    for _ in range(600):
        cases.append((2, [(1, minute, minute + 1, 2) for minute in range(DAY_MINUTES - 1)]))
    return cases


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
write("2_edges", build_edges())
write("3_wide", build_wide())
write("4_random", build_random())
write("5_io", build_io())
