#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INFINITY = 10**9

SAMPLE_INPUT = (
    "1\n"
    "5 60\n"
    "5\n"
    "3 36 120\n"
    "10 25 129\n"
    "5 50 250\n"
    "1 45 130\n"
    "4 20 119\n"
)


def parse(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    cases = []
    for _ in range(case_count):
        oxygen_demand = int(tokens[cursor])
        nitrogen_demand = int(tokens[cursor + 1])
        cursor += 2
        cylinder_count = int(tokens[cursor])
        cursor += 1
        cylinders = []
        for _ in range(cylinder_count):
            cylinders.append((int(tokens[cursor]), int(tokens[cursor + 1]), int(tokens[cursor + 2])))
            cursor += 3
        cases.append((oxygen_demand, nitrogen_demand, cylinders))
    return cases


def oracle_case(oxygen_demand, nitrogen_demand, cylinders):
    states = {(0, 0): 0}
    for cylinder_oxygen, cylinder_nitrogen, cylinder_weight in cylinders:
        next_states = dict(states)
        for (stored_oxygen, stored_nitrogen), stored_weight in states.items():
            reached_oxygen = min(stored_oxygen + cylinder_oxygen, oxygen_demand)
            reached_nitrogen = min(stored_nitrogen + cylinder_nitrogen, nitrogen_demand)
            candidate = stored_weight + cylinder_weight
            if candidate < next_states.get((reached_oxygen, reached_nitrogen), INFINITY):
                next_states[(reached_oxygen, reached_nitrogen)] = candidate
        states = next_states
    return states[(oxygen_demand, nitrogen_demand)]


def brute_case(oxygen_demand, nitrogen_demand, cylinders):
    best = INFINITY
    for subset in range(1 << len(cylinders)):
        total_oxygen = 0
        total_nitrogen = 0
        total_weight = 0
        for cylinder_index, (cylinder_oxygen, cylinder_nitrogen, cylinder_weight) in enumerate(cylinders):
            if subset & (1 << cylinder_index):
                total_oxygen += cylinder_oxygen
                total_nitrogen += cylinder_nitrogen
                total_weight += cylinder_weight
        if total_oxygen >= oxygen_demand and total_nitrogen >= nitrogen_demand:
            best = min(best, total_weight)
    return best


def oracle(text):
    return "".join(str(oracle_case(*case)) + "\n" for case in parse(text))


def render(cases, blank_between):
    lines = [str(len(cases))]
    for oxygen_demand, nitrogen_demand, cylinders in cases:
        if blank_between:
            lines.append("")
        lines.append(f"{oxygen_demand} {nitrogen_demand}")
        lines.append(str(len(cylinders)))
        lines.extend(f"{cylinder_oxygen} {cylinder_nitrogen} {cylinder_weight}"
                     for cylinder_oxygen, cylinder_nitrogen, cylinder_weight in cylinders)
    return "\n".join(lines) + "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))
    for oxygen_demand, nitrogen_demand, cylinders in parse(text):
        if len(cylinders) <= 16:
            assert oracle_case(oxygen_demand, nitrogen_demand, cylinders) == brute_case(
                oxygen_demand, nitrogen_demand, cylinders)


assert oracle(SAMPLE_INPUT) == "249\n"
assert oracle_case(1, 1, [(1, 1, 7)]) == 7
assert oracle_case(21, 79, [(21, 79, 800)]) == 800
assert brute_case(5, 60, [(3, 36, 120), (10, 25, 129)]) == 249
small_rng = random.Random(9271)
for _ in range(200):
    demand_oxygen = small_rng.randint(1, 21)
    demand_nitrogen = small_rng.randint(1, 79)
    small_cylinders = [(small_rng.randint(1, 21), small_rng.randint(1, 79), small_rng.randint(1, 800))
                       for _ in range(small_rng.randint(1, 10))]
    small_cylinders.append((demand_oxygen, demand_nitrogen, small_rng.randint(1, 800)))
    assert oracle_case(demand_oxygen, demand_nitrogen, small_cylinders) == brute_case(
        demand_oxygen, demand_nitrogen, small_cylinders)


def build():
    edge_cases = [
        (1, 1, [(1, 1, 5)]),
        (21, 79, [(21, 79, 800)]),
        (5, 60, [(3, 36, 120), (10, 25, 129), (5, 50, 250), (1, 45, 130), (4, 20, 119)]),
        (1, 1, [(21, 79, 700), (1, 1, 3)]),
        (2, 2, [(1, 2, 10), (2, 1, 10), (1, 1, 15)]),
        (21, 1, [(21, 1, 799)]),
        (1, 79, [(1, 79, 800)]),
        (21, 79, [(21, 78, 400), (1, 1, 400), (21, 79, 799)]),
    ]
    write("2_edges", render(edge_cases, True))

    wide_rng = random.Random(31415)
    wide_cases = []
    for demand_oxygen, demand_nitrogen, oxygen_limit, nitrogen_limit in [
            (21, 79, 21, 79), (1, 1, 21, 79), (21, 1, 21, 5), (1, 79, 3, 79)]:
        cylinders = [(wide_rng.randint(1, oxygen_limit), wide_rng.randint(1, nitrogen_limit),
                      wide_rng.randint(1, 800)) for _ in range(999)]
        cylinders.append((demand_oxygen, demand_nitrogen, wide_rng.randint(1, 800)))
        wide_rng.shuffle(cylinders)
        wide_cases.append((demand_oxygen, demand_nitrogen, cylinders))
    write("3_wide", render(wide_cases, True))

    random_rng = random.Random(577)
    random_cases = []
    for _ in range(40):
        demand_oxygen = random_rng.randint(1, 21)
        demand_nitrogen = random_rng.randint(1, 79)
        cylinders = [(random_rng.randint(1, 21), random_rng.randint(1, 79),
                      random_rng.randint(1, 800))
                     for _ in range(random_rng.randint(1, 60))]
        cylinders.append((demand_oxygen, demand_nitrogen, random_rng.randint(1, 800)))
        random_cases.append((demand_oxygen, demand_nitrogen, cylinders))
    write("4_random", render(random_cases, True))

    io_rng = random.Random(8123)
    io_cases = []
    for _ in range(80000):
        io_cases.append((1, 1, [(1, 1, io_rng.randint(100, 800))]))
    write("5_io", render(io_cases, True))


def worked_example():
    demand_oxygen = 2
    demand_nitrogen = 2
    cylinders = [(1, 2, 10), (2, 1, 10), (1, 1, 15)]
    states = {(0, 0): 0}
    for cylinder_index, (cylinder_oxygen, cylinder_nitrogen, cylinder_weight) in enumerate(cylinders, 1):
        added = {}
        for (stored_oxygen, stored_nitrogen), stored_weight in states.items():
            reached = (min(stored_oxygen + cylinder_oxygen, demand_oxygen),
                       min(stored_nitrogen + cylinder_nitrogen, demand_nitrogen))
            candidate = stored_weight + cylinder_weight
            if candidate < added.get(reached, INFINITY):
                added[reached] = candidate
        for state, weight in added.items():
            if weight < states.get(state, INFINITY):
                states[state] = weight
        new_state = min(added, key=lambda state: (added[state], state))
        target = states.get((demand_oxygen, demand_nitrogen), INFINITY)
        target_text = str(target) if target < INFINITY else "unreachable"
        print(f"{cylinder_index} ({cylinder_oxygen}, {cylinder_nitrogen}, {cylinder_weight}) "
              f"new {new_state} weight {added[new_state]} target {target_text}")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_INPUT)
build()
worked_example()
