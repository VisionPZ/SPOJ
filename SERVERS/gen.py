#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def parse_cases(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    cases = []
    for _ in range(case_count):
        server_count = int(tokens[cursor])
        wire_count = int(tokens[cursor + 1])
        cursor += 2
        ranks = [0]
        for _ in range(server_count):
            ranks.append(int(tokens[cursor]))
            cursor += 1
        edges = []
        for _ in range(wire_count):
            endpoint_a = int(tokens[cursor])
            endpoint_b = int(tokens[cursor + 1])
            time = int(tokens[cursor + 2])
            cursor += 3
            edges.append((endpoint_a, endpoint_b, time))
        cases.append((server_count, wire_count, ranks, edges))
    assert cursor == len(tokens)
    return cases


def brute_force_answer(case):
    server_count, wire_count, ranks, edges = case
    distance = [[INF] * (server_count + 1) for _ in range(server_count + 1)]
    for server_index in range(1, server_count + 1):
        distance[server_index][server_index] = 0
    for endpoint_a, endpoint_b, time in edges:
        distance[endpoint_a][endpoint_b] = min(distance[endpoint_a][endpoint_b], time)
        distance[endpoint_b][endpoint_a] = min(distance[endpoint_b][endpoint_a], time)
    for middle in range(1, server_count + 1):
        middle_row = distance[middle]
        for source in range(1, server_count + 1):
            source_row = distance[source]
            source_to_middle = source_row[middle]
            for target in range(1, server_count + 1):
                candidate = source_to_middle + middle_row[target]
                if candidate < source_row[target]:
                    source_row[target] = candidate
    total = 0
    for source in range(1, server_count + 1):
        source_row = distance[source]
        for target in range(1, server_count + 1):
            reach = source_row[target]
            best_rank = max(ranks[other] for other in range(1, server_count + 1)
                            if source_row[other] <= reach)
            if best_rank == ranks[target]:
                total += 1
    return total


def brute_force(text):
    return "".join(str(brute_force_answer(case)) + "\n" for case in parse_cases(text))


def worked_example():
    server_count, wire_count, ranks, edges = parse_cases(SAMPLE_TEXT)[0]
    distance = [[INF] * (server_count + 1) for _ in range(server_count + 1)]
    for server_index in range(1, server_count + 1):
        distance[server_index][server_index] = 0
    for endpoint_a, endpoint_b, time in edges:
        distance[endpoint_a][endpoint_b] = time
        distance[endpoint_b][endpoint_a] = time
    for middle in range(1, server_count + 1):
        for source in range(1, server_count + 1):
            for target in range(1, server_count + 1):
                distance[source][target] = min(
                    distance[source][target],
                    distance[source][middle] + distance[middle][target])
    lines = []
    for source in range(1, server_count + 1):
        order = sorted(range(1, server_count + 1),
                       key=lambda target: (distance[source][target], target))
        parts = []
        chosen = 0
        position = 0
        best_rank = 0
        while position < len(order):
            reach = distance[source][order[position]]
            group = []
            while position < len(order) and distance[source][order[position]] == reach:
                group.append(order[position])
                position += 1
            best_rank = max([best_rank] + [ranks[target] for target in group])
            for target in group:
                mark = "*" if ranks[target] == best_rank else ""
                if mark:
                    chosen += 1
                parts.append(f"{target}({reach},r{ranks[target]}){mark}")
        lines.append(f"V={source}: " + " ".join(parts) + f"  -> {chosen}")
    return "\n".join(lines)


def render(cases):
    lines = [str(len(cases))]
    for server_count, wire_count, ranks, edges in cases:
        lines.append(f"{server_count} {wire_count}")
        lines.extend(str(ranks[index]) for index in range(1, server_count + 1))
        lines.extend(f"{a} {b} {t}" for a, b, t in edges)
    return "\n".join(lines) + "\n"


def write(name, cases, answers):
    input_text = render(cases)
    expected = "".join(str(answer) + "\n" for answer in answers)
    if all(case[0] <= 100 for case in cases):
        assert brute_force(input_text) == expected, name + " disagrees with brute force"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(expected)


def star_case(server_count, center_rank):
    ranks = [0] + [center_rank] + [1] * (server_count - 1)
    edges = [(1, index, 1) for index in range(2, server_count + 1)]
    return server_count, len(edges), ranks, edges


def star_answer(server_count, center_rank):
    if center_rank == 1:
        return server_count * server_count
    return 2 * server_count - 1


def two_center_case(server_count):
    ranks = [0, 10, 10] + [1] * (server_count - 2)
    edges = [(1, 2, 1)]
    for index in range(3, server_count + 1):
        edges.append((1, index, 1))
        edges.append((2, index, 1))
    return server_count, len(edges), ranks, edges


def two_center_answer(server_count):
    return 3 * server_count - 2


def hierarchy_case(server_count):
    ranks = [0, 10] + [9] * 9 + [1] * (server_count - 10)
    edges = [(1, middle, 1) for middle in range(2, 11)]
    for leaf in range(11, server_count + 1):
        edges.append((2 + (leaf - 11) % 9, leaf, 1))
    return server_count, len(edges), ranks, edges


def hierarchy_answer(server_count):
    return 3 * server_count - 11


SAMPLE_TEXT = "1\n4 3\n2\n3\n1\n1\n1 4 30\n2 3 20\n3 4 20\n"
assert brute_force(SAMPLE_TEXT) == "9\n"
assert worked_example() == (
    "V=1: 1(0,r2)* 4(30,r1) 3(50,r1) 2(70,r3)*  -> 2\n"
    "V=2: 2(0,r3)* 3(20,r1) 4(40,r1) 1(70,r2)  -> 1\n"
    "V=3: 3(0,r1)* 2(20,r3)* 4(20,r1) 1(50,r2)  -> 2\n"
    "V=4: 4(0,r1)* 3(20,r1)* 1(30,r2)* 2(40,r3)*  -> 4")
for small_size in range(2, 8):
    assert brute_force(render([star_case(small_size, 10)])) == (
        str(star_answer(small_size, 10)) + "\n")
    assert brute_force(render([two_center_case(small_size)])) == (
        str(two_center_answer(small_size)) + "\n")
assert brute_force(render([(1, 0, [0, 10], [])])) == "1\n"
for small_size in range(10, 25):
    assert brute_force_answer(hierarchy_case(small_size)) == hierarchy_answer(small_size)


def random_case(rng, server_count, wire_target):
    ranks = [0] + [rng.randint(1, 10) for _ in range(server_count)]
    edges = []
    present = set()
    if server_count > 1:
        order = list(range(2, server_count + 1))
        rng.shuffle(order)
        for position in range(1, len(order)):
            endpoint_a = rng.randint(1, position)
            endpoint_b = order[position]
            edges.append((endpoint_a, endpoint_b, rng.randint(1, 10)))
            present.add((min(endpoint_a, endpoint_b), max(endpoint_a, endpoint_b)))
    possible = [(a, b) for a in range(1, server_count + 1)
                for b in range(a + 1, server_count + 1) if (a, b) not in present]
    rng.shuffle(possible)
    target = min(wire_target, len(edges) + len(possible))
    for endpoint_a, endpoint_b in possible[:target - len(edges)]:
        edges.append((endpoint_a, endpoint_b, rng.randint(1, 10)))
    return server_count, len(edges), ranks, edges


def build():
    edges_cases = [
        (1, 0, [0, 10], []),
        (1, 0, [0, 1], []),
        star_case(2, 10),
        two_center_case(3),
        (5, 4, [0, 1, 1, 1, 1, 1], [(1, 2, 1), (2, 3, 1), (3, 4, 1), (4, 5, 1)]),
        (6, 6, [0, 3, 3, 3, 3, 3, 3],
         [(1, 2, 7), (1, 3, 7), (1, 4, 7), (2, 5, 7), (3, 6, 7), (4, 5, 7)]),
        (6, 5, [0, 10, 9, 8, 7, 6, 5],
         [(1, 2, 1), (2, 3, 2), (3, 4, 3), (4, 5, 4), (5, 6, 5)]),
    ]
    write("2_edges", edges_cases, [brute_force_answer(case) for case in edges_cases])

    wide_specs = [
        (star_case(30000, 10), star_answer(30000, 10)),
        (two_center_case(30000), two_center_answer(30000)),
    ]
    wide_specs.append((hierarchy_case(30000), hierarchy_answer(30000)))
    wide_cases = [spec[0] for spec in wide_specs]
    wide_answers = [spec[1] for spec in wide_specs]
    for case, answer in zip(wide_cases, wide_answers):
        assert answer <= 30 * case[0], "wide case breaks the answer bound"
    write("3_wide", wide_cases, wide_answers)

    random.seed(2026)
    random_cases = [random_case(random, random.randint(2, 12), random.randint(2, 40))
                    for _ in range(120)]
    write("4_random", random_cases,
          [brute_force_answer(case) for case in random_cases])

    io_cases = [random_case(random, random.randint(2, 4), random.randint(2, 6))
                for _ in range(150000)]
    write("5_io", io_cases, [brute_force_answer(case) for case in io_cases])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_TEXT)
(ROOT / "out" / "1_sample.out").write_text(brute_force(SAMPLE_TEXT))
build()
