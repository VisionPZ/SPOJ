#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ORACLE_TREE_SIZE = 1 << 17


def oracle_case(capacity, containers):
    tree = [0] * (2 * ORACLE_TREE_SIZE)
    remaining = [0] * (100000 + 8)
    ship_count = 0

    def update(ship_index, value):
        node = ORACLE_TREE_SIZE + ship_index
        tree[node] = value
        node >>= 1
        while node:
            left_child = node << 1
            right_child = left_child | 1
            tree[node] = tree[left_child] if tree[left_child] >= tree[right_child] else tree[right_child]
            node >>= 1

    def leftmost(threshold):
        if tree[1] < threshold:
            return -1
        node = 1
        while node < ORACLE_TREE_SIZE:
            left_child = node << 1
            if tree[left_child] >= threshold:
                node = left_child
            else:
                node = left_child | 1
        return node - ORACLE_TREE_SIZE

    for volume in containers:
        ship_index = leftmost(volume)
        if ship_index < 0:
            remaining[ship_count] = capacity - volume
            update(ship_count, remaining[ship_count])
            ship_count += 1
        else:
            remaining[ship_index] -= volume
            update(ship_index, remaining[ship_index])
    return f"{ship_count} {sum(remaining[:ship_count])}"


def brute_case(capacity, containers):
    remaining = []
    for volume in containers:
        chosen = -1
        for index, value in enumerate(remaining):
            if value >= volume:
                chosen = index
                break
        if chosen < 0:
            remaining.append(capacity - volume)
        else:
            remaining[chosen] -= volume
    return f"{len(remaining)} {sum(remaining)}"


def expand(segments):
    result = []
    for segment in segments:
        if isinstance(segment, int):
            result.append(segment)
        else:
            result.extend([segment[2]] * segment[1])
    return result


def case_text(capacity, segments):
    containers = expand(segments)
    lines = [str(capacity), str(len(containers))]
    for segment in segments:
        if isinstance(segment, int):
            lines.append(str(segment))
        else:
            lines.append(f"b {segment[1]} {segment[2]}")
    return "\n".join(lines) + "\n", containers


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        capacity = int(tokens[cursor]); cursor += 1
        container_count = int(tokens[cursor]); cursor += 1
        containers = []
        while len(containers) < container_count:
            if tokens[cursor] == "b":
                cursor += 1
                repeat = int(tokens[cursor]); cursor += 1
                volume = int(tokens[cursor]); cursor += 1
                containers.extend([volume] * repeat)
            else:
                containers.append(int(tokens[cursor])); cursor += 1
        answers.append(oracle_case(capacity, containers))
    return "\n".join(answers) + "\n"


def write(name, cases):
    case_texts = [case_text(capacity, segments) for capacity, segments in cases]
    input_text = str(len(cases)) + "\n" + "".join(text for text, _ in case_texts)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [
    (100, [50, 25, 70]),
    (100, [50, ("b", 2, 40), 20]),
]
SAMPLE_INPUT = "2\n100\n3\n50\n25\n70\n100\n4\n50\nb 2 40\n20\n"
SAMPLE_OUTPUT = "2 55\n2 50\n"

assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle_case(10, [5, 5, 5]) == brute_case(10, [5, 5, 5]) == "2 5"
assert oracle_case(100, [99, 2, 99]) == brute_case(100, [99, 2, 99]) == "3 100"
assert oracle_case(7, [3, 3, 3, 3]) == brute_case(7, [3, 3, 3, 3]) == "2 2"

random.seed(1337)
for _ in range(60):
    trial_capacity = random.randint(1, 40)
    trial_containers = [random.randint(1, trial_capacity) for _ in range(random.randint(1, 60))]
    assert oracle_case(trial_capacity, trial_containers) == brute_case(trial_capacity, trial_containers)


def build():
    write("2_edges", [
        (1, [1]),
        (1000, [1000]),
        (1000, [1]),
        (10, [5, 5, 5]),
        (100, [("b", 1, 100)]),
        (100, [99, 2, 99]),
        (7, [3, 3, 3, 3]),
        (50, [("b", 10, 50), 49, ("b", 3, 1)]),
        (999, [500, 500, 1, 999]),
    ])
    write("3_wide", [
        (1000, [("b", 100000, 1), ("b", 50000, 1000)]),
        (1000, [("b", 100000, 999)]),
        (1000, [("b", 90000, 7), ("b", 60000, 3), ("b", 20000, 1000)]),
        (1, [("b", 100000, 1)]),
    ])

    random.seed(2026)
    random_cases = []
    for _ in range(5):
        case_capacity = random.randint(1, 1000)
        segments = []
        left = random.randint(20000, 50000)
        while left > 0:
            if random.random() < 0.5:
                count = random.randint(1, min(left, 1200))
                volume = random.randint(1, case_capacity)
                segments.append(("b", count, volume))
                left -= count
            else:
                segments.append(random.randint(1, case_capacity))
                left -= 1
        random_cases.append((case_capacity, segments))
    write("4_random", random_cases)

    io_cases = []
    for case_index in range(10):
        case_capacity = 300 + case_index * 70
        segments = [("b", 70000, 1), ("b", 30000, case_capacity)]
        io_cases.append((case_capacity, segments))
    write("5_io", io_cases)


def worked_example():
    capacity = 100
    containers = [50, 25, 70]
    remaining = []
    print("| Container | Volume | Action | Ship | Remaining capacities |")
    print("| --- | --- | --- | --- | --- |")
    for number, volume in enumerate(containers, 1):
        chosen = -1
        for index, value in enumerate(remaining):
            if value >= volume:
                chosen = index
                break
        if chosen < 0:
            chosen = len(remaining)
            remaining.append(capacity - volume)
            action = "open ship"
        else:
            remaining[chosen] -= volume
            action = "reuse"
        values = ", ".join(str(value) for value in remaining)
        print(f"| {number} | {volume} | {action} | S{chosen} | {values} |")
    print(f"Result: {len(remaining)} ships, waste {sum(remaining)}.")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
worked_example()
