#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    output = []
    for case_index in range(1, case_count + 1):
        node_count = int(tokens[cursor]); cursor += 1
        road_count = int(tokens[cursor]); cursor += 1
        plan_count = int(tokens[cursor]); cursor += 1
        graph = [[] for _ in range(node_count + 1)]
        for _ in range(road_count):
            road_from = int(tokens[cursor]); cursor += 1
            road_to = int(tokens[cursor]); cursor += 1
            road_length = int(tokens[cursor]); cursor += 1
            graph[road_from].append((road_to, road_length))
            graph[road_to].append((road_from, road_length))
        plans = []
        for _ in range(plan_count):
            meet = int(tokens[cursor]); cursor += 1
            target = int(tokens[cursor]); cursor += 1
            plans.append((meet, target))
        sources = sorted({meet for meet, _ in plans})
        distances_by_source = {}
        for source in sources:
            distances = [10 ** 18] * (node_count + 1)
            distances[source] = 0
            queue = [(0, source)]
            while queue:
                distance, node = heapq.heappop(queue)
                if distance != distances[node]:
                    continue
                for neighbor, length in graph[node]:
                    candidate = distance + length
                    if candidate < distances[neighbor]:
                        distances[neighbor] = candidate
                        heapq.heappush(queue, (candidate, neighbor))
            distances_by_source[source] = distances
        output.append(f"Case {case_index}:")
        output.extend(str(distances_by_source[meet][target]) for meet, target in plans)
    return "\n".join(output) + "\n"


SAMPLE = """1
7 9 5
7 6 6114
5 3 5473
2 4 2601
5 4 8525
7 3 291
2 7 3363
1 6 399
6 4 4477
1 7 3075
6 3
4 4
3 1
2 3
7 3
"""
SAMPLE_OUT = """Case 1:
3765
0
3366
3654
291
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 0 1\n1 1\n") == "Case 1:\n0\n"
assert oracle("1\n2 1 1\n1 2 7\n2 1\n") == "Case 1:\n7\n"
assert oracle("1\n3 3 1\n1 2 4\n2 3 5\n1 3 3\n3 1\n") == "Case 1:\n3\n"
assert 2 + 2 == 4


def case_text(node_count, edges, plans):
    text = f"{node_count} {len(edges)} {len(plans)}\n"
    text += "".join(f"{u} {v} {length}\n" for u, v, length in edges)
    text += "".join(f"{meet} {target}\n" for meet, target in plans)
    return text


def random_case(rng, node_count, extra_count, plan_count):
    edges = []
    for node in range(2, node_count + 1):
        edges.append((node, rng.randint(1, node - 1), rng.randint(1, 10000)))
    for _ in range(extra_count):
        first = rng.randint(1, node_count)
        second = rng.randint(1, node_count)
        if first == second:
            continue
        edges.append((first, second, rng.randint(1, 10000)))
    plans = [(rng.randint(1, node_count), rng.randint(1, node_count))
             for _ in range(plan_count)]
    return (node_count, edges, plans)


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(case_text(*case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, [], [(1, 1)]),
        (2, [(1, 2, 7)], [(2, 1), (1, 2)]),
        (3, [(1, 2, 4), (2, 3, 5), (1, 3, 3)], [(3, 1), (1, 3), (2, 2)]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [random_case(rng, 60, 8, 40) for _ in range(6)])
    write("4_random", [random_case(rng, rng.randint(2, 25), rng.randint(0, 6), 20)
                       for _ in range(20)])
    plans = [(rng.randint(1, 100), rng.randint(1, 100)) for _ in range(30000)]
    write("5_io", [(100, [(node, rng.randint(1, node - 1), rng.randint(1, 10000))
                          for node in range(2, 101)], plans)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
