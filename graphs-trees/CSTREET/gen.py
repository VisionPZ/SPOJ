#!/usr/bin/env python3
import random
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def find_root(parent, node):
    while parent[node] != node:
        parent[node] = parent[parent[node]]
        node = parent[node]
    return node


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        price = int(tokens[cursor])
        cursor += 1
        building_count = int(tokens[cursor])
        cursor += 1
        street_count = int(tokens[cursor])
        cursor += 1
        edges = []
        for _ in range(street_count):
            first = int(tokens[cursor])
            cursor += 1
            second = int(tokens[cursor])
            cursor += 1
            length = int(tokens[cursor])
            cursor += 1
            edges.append((length, first, second))
        edges.sort()
        parent = list(range(building_count + 1))
        group_size = [1] * (building_count + 1)
        total = 0
        chosen = 0
        for length, first, second in edges:
            root_first = find_root(parent, first)
            root_second = find_root(parent, second)
            if root_first == root_second:
                continue
            if group_size[root_first] < group_size[root_second]:
                root_first, root_second = root_second, root_first
            parent[root_second] = root_first
            group_size[root_first] += group_size[root_second]
            total += length
            chosen += 1
            if chosen == building_count - 1:
                break
        answers.append(str(price * total))
    return "\n".join(answers) + "\n"


def brute_force(building_count, edges):
    best = None
    for subset in combinations(edges, building_count - 1):
        parent = list(range(building_count + 1))
        total = 0
        valid = True
        for first, second, length in subset:
            root_first = find_root(parent, first)
            root_second = find_root(parent, second)
            if root_first == root_second:
                valid = False
                break
            parent[root_second] = root_first
            total += length
        if not valid:
            continue
        root = find_root(parent, 1)
        if any(find_root(parent, node) != root for node in range(2, building_count + 1)):
            continue
        if best is None or total < best:
            best = total
    return best


def format_case(price, building_count, edges):
    lines = [str(price), str(building_count), str(len(edges))]
    lines += [f"{first} {second} {length}" for first, second, length in edges]
    return "\n".join(lines) + "\n"


def single_case(price, building_count, edges):
    return "1\n" + format_case(price, building_count, edges)


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        format_case(price, building_count, edges)
        for price, building_count, edges in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_TEXT = (
    "1\n2\n5\n7\n"
    "1 2 1\n2 3 2\n2 4 6\n5 2 1\n5 1 3\n4 5 2\n3 4 3\n"
)

assert oracle(SAMPLE_TEXT) == "12\n"
assert oracle(single_case(3, 3, [(1, 2, 1), (2, 3, 2), (1, 3, 5)])) == "9\n"
assert brute_force(5, [(1, 2, 1), (2, 3, 2), (2, 4, 6), (5, 2, 1),
                       (5, 1, 3), (4, 5, 2), (3, 4, 3)]) == 6
assert oracle(single_case(1, 3, [(1, 2, 1), (2, 3, 2), (1, 3, 5)])) == "3\n"

check_rng = random.Random(1234567)
for _ in range(40):
    small_count = check_rng.randint(2, 5)
    edge_pool = [(a, b, check_rng.randint(1, 9))
                 for a in range(1, small_count + 1)
                 for b in range(a + 1, small_count + 1)]
    for node in range(2, small_count + 1):
        edge_pool.append((check_rng.randint(1, node - 1), node, check_rng.randint(1, 9)))
    chosen_edges = [(a, b, cost) for a, b, cost in edge_pool
                    if check_rng.random() < 0.6]
    for node in range(2, small_count + 1):
        if not any(node in (a, b) for a, b, _ in chosen_edges):
            chosen_edges.append((node - 1, node, check_rng.randint(1, 9)))
    while True:
        parent = list(range(small_count + 1))
        for first, second, _ in chosen_edges:
            parent[find_root(parent, second)] = find_root(parent, first)
        if len({find_root(parent, node) for node in range(1, small_count + 1)}) == 1:
            break
        chosen_edges.append((check_rng.randint(1, small_count - 1),
                             check_rng.randint(2, small_count),
                             check_rng.randint(1, 9)))
    expected = brute_force(small_count, chosen_edges)
    got = oracle(single_case(7, small_count, chosen_edges))
    assert got == str(7 * expected) + "\n", (chosen_edges, got, expected)

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_TEXT)
(ROOT / "out" / "1_sample.out").write_text(oracle(SAMPLE_TEXT))

write("2_edges", [
    (1, 1, [(1, 1, 5)]),
    (7, 2, [(1, 2, 3)]),
    (2, 3, [(1, 2, 4), (2, 3, 4), (1, 3, 1)]),
    (1, 4, [(1, 2, 2), (1, 3, 3), (1, 4, 4), (2, 3, 1), (3, 4, 1), (2, 4, 5)]),
    (1000000000, 2, [(1, 2, 4), (1, 2, 3)]),
    (3, 5, [(1, 2, 1), (2, 3, 2), (2, 4, 6), (5, 2, 1),
            (5, 1, 3), (4, 5, 2), (3, 4, 3)]),
    (1, 2, [(1, 2, 1)] * 10),
])

wide_rng = random.Random(20261125)
wide_cases = []
for upper_weight in (50, 2000000):
    edges = [(node, node + 1, wide_rng.randint(1, upper_weight))
             for node in range(1, 1000)]
    while len(edges) < 60000:
        first = wide_rng.randint(1, 1000)
        second = wide_rng.randint(1, 1000)
        if first != second:
            edges.append((first, second, wide_rng.randint(1, upper_weight)))
    wide_cases.append((1 if upper_weight > 1000 else 999, 1000, edges))
write("3_wide", wide_cases)

random_rng = random.Random(777001)
random_cases = []
for _ in range(20):
    building_count = random_rng.randint(2, 200)
    edge_count = random_rng.randint(building_count - 1, min(3000, building_count * 12))
    edges = [(node, random_rng.randint(1, node - 1), random_rng.randint(1, 10000))
             for node in range(2, building_count + 1)]
    while len(edges) < edge_count:
        first = random_rng.randint(1, building_count)
        second = random_rng.randint(1, building_count)
        if first != second:
            edges.append((first, second, random_rng.randint(1, 10000)))
    random_cases.append((random_rng.randint(1, 1000), building_count, edges))
write("4_random", random_cases)

io_rng = random.Random(999331)
io_cases = []
for _ in range(100):
    price = io_rng.randint(100000000, 999999999)
    lengths = [io_rng.randint(1, 4) for _ in range(io_rng.randint(1, 3))]
    io_cases.append((price, 2, [(1, 2, length) for length in lengths]))
write("5_io", io_cases)

print("generated five test pairs")
