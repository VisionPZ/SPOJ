import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(stops, town_distance, starting_fuel):
    positions = sorted((town_distance - distance, fuel)
                       for distance, fuel in stops
                       if 0 <= distance <= town_distance)
    if starting_fuel >= town_distance:
        return 0
    stop_total = len(positions)
    impossible = -10**18
    best_fuel = [impossible] * (stop_total + 2)
    best_fuel[0] = starting_fuel
    best_count = None
    for index, (position, fuel) in enumerate(positions):
        upper = index + 1
        if best_count is not None:
            upper = min(upper, best_count - 1)
        for used in range(upper, 0, -1):
            carried = best_fuel[used - 1]
            if carried >= position and carried + fuel > best_fuel[used]:
                best_fuel[used] = carried + fuel
        for used in range(1, upper + 1):
            if best_fuel[used] < best_fuel[used - 1]:
                best_fuel[used] = best_fuel[used - 1]
        for used in range(1, upper + 1):
            if best_fuel[used] >= town_distance:
                if best_count is None or used < best_count:
                    best_count = used
    return -1 if best_count is None else best_count


def brute_case(stops, town_distance, starting_fuel):
    positions = sorted((town_distance - distance, fuel)
                       for distance, fuel in stops
                       if 0 <= distance <= town_distance)
    limit = [len(positions) + 1]

    def explore(index, carried, used):
        if carried >= town_distance:
            if used < limit[0]:
                limit[0] = used
            return
        if index == len(positions) or used >= limit[0]:
            return
        explore(index + 1, carried, used)
        position, fuel = positions[index]
        if carried >= position and used + 1 < limit[0]:
            explore(index + 1, carried + fuel, used + 1)

    explore(0, starting_fuel, 0)
    return -1 if limit[0] == len(positions) + 1 else limit[0]


assert oracle_case([(4, 4), (5, 2), (11, 5), (15, 10)], 25, 10) == 2
assert oracle_case([], 10, 10) == 0
assert oracle_case([], 10, 9) == -1
assert oracle_case([(10, 100)], 10, 1) == 1

checker = random.Random(31415)
for _ in range(300):
    town_distance = checker.randint(1, 40)
    stops = [(checker.randint(0, town_distance), checker.randint(1, 12))
             for _ in range(checker.randint(0, 10))]
    starting_fuel = checker.randint(1, town_distance + 10)
    assert oracle_case(stops, town_distance, starting_fuel) == brute_case(
        stops, town_distance, starting_fuel)


def write_case_file(name, cases):
    lines = [str(len(cases))]
    for stops, town_distance, starting_fuel in cases:
        lines.append(str(len(stops)))
        for distance, fuel in stops:
            lines.append(f"{distance} {fuel}")
        lines.append(f"{town_distance} {starting_fuel}")
    input_text = "\n".join(lines) + "\n"
    output_text = "\n".join(
        str(oracle_case(stops, town_distance, starting_fuel))
        for stops, town_distance, starting_fuel in cases) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


SAMPLE = ([([(4, 4), (5, 2), (11, 5), (15, 10)], 25, 10)])
EDGES = [
    ([(1, 1)], 1, 1),
    ([(1, 1)], 10, 10),
    ([(1, 1)], 10, 9),
    ([(5, 1)], 10, 1),
    ([(10, 1)], 10, 1),
    ([(10, 100)], 10, 1),
    ([(1, 100), (2, 1)], 10, 1),
    ([(999999, 1)], 1000000, 999999),
    ([(999999, 1)], 1000000, 1000000),
    ([(999999, 1), (999999, 2)], 1000000, 999998),
    ([(1000001, 100), (999999, 1)], 1000000, 999999),
    ([(500000, 100), (400000, 100), (300000, 100),
      (200000, 100), (100000, 100)], 1000000, 500000),
]

wide_same = [(index, 1 + index % 100) for index in range(1000000, 0, -100)]
wide_near = [(1000000, 100)] * 9999 + [(999999, 1)]
wide_chain = [(1000000 - position, 100) for position in range(1, 10001)]
wide_blocked = [(1000000 - position, 100) for position in range(1, 101)]
WIDE = [
    (wide_same, 1000000, 1000000),
    (wide_near, 1000000, 999999),
    (wide_chain, 1000000, 999900),
    ([(1, 1)] * 10000, 1, 1),
    (wide_blocked, 1000000, 1),
]

generator = random.Random(20261125)
RANDOM = []
for _ in range(60):
    town_distance = generator.randint(1, 1000000)
    stops = [(generator.randint(0, town_distance), generator.randint(1, 100))
             for _ in range(generator.randint(1, 300))]
    RANDOM.append((stops, town_distance, generator.randint(1, town_distance)))

IO_CASES = []
for index in range(180000):
    town_distance = 1 + index % 3
    IO_CASES.append(([(1, 1)], town_distance, 1))

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case_file("1_sample", SAMPLE)
write_case_file("2_edges", EDGES)
write_case_file("3_wide", WIDE)
write_case_file("4_random", RANDOM)
write_case_file("5_io", IO_CASES)

print("generated five case pairs")
