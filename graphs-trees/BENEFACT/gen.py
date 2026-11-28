#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def build_graph(node_count, edges):
    graph = [[] for _ in range(node_count + 1)]
    for first, second, length in edges:
        graph[first].append((second, length))
        graph[second].append((first, length))
    return graph


def brute_diameter(node_count, edges):
    graph = build_graph(node_count, edges)
    answer = 0
    for start in range(1, node_count + 1):
        seen = [-1] * (node_count + 1)
        seen[start] = 0
        queue = deque([start])
        while queue:
            node = queue.popleft()
            for neighbor, length in graph[node]:
                if seen[neighbor] < 0:
                    seen[neighbor] = seen[node] + length
                    queue.append(neighbor)
        answer = max(answer, max(seen[1:]))
    return answer


def oracle_diameter(node_count, edges):
    graph = build_graph(node_count, edges)
    parent = [0] * (node_count + 1)
    parent[1] = -1
    order = [1]
    for node in order:
        for neighbor, _ in graph[node]:
            if neighbor != parent[node]:
                parent[neighbor] = node
                order.append(neighbor)
    downward = [0] * (node_count + 1)
    answer = 0
    for node in reversed(order):
        longest = 0
        second_longest = 0
        for neighbor, length in graph[node]:
            if parent[neighbor] == node:
                candidate = downward[neighbor] + length
                if candidate >= longest:
                    second_longest = longest
                    longest = candidate
                elif candidate > second_longest:
                    second_longest = candidate
        downward[node] = longest
        answer = max(answer, longest + second_longest)
    return answer


def sweep_diameter(node_count, edges):
    graph = build_graph(node_count, edges)

    def farthest(start):
        seen = [-1] * (node_count + 1)
        seen[start] = 0
        queue = deque([start])
        while queue:
            node = queue.popleft()
            for neighbor, length in graph[node]:
                if seen[neighbor] < 0:
                    seen[neighbor] = seen[node] + length
                    queue.append(neighbor)
        farthest_node = max(range(1, node_count + 1), key=lambda node: seen[node])
        return farthest_node, seen[farthest_node]

    endpoint, _ = farthest(1)
    return farthest(endpoint)[1]


def random_tree(rng, node_count):
    edges = []
    for node in range(2, node_count + 1):
        parent = rng.randrange(1, node)
        length = rng.choice([0, 0, 1, 2, 17, 19998, 19999])
        edges.append((node, parent, length))
    return edges


def path_tree(node_count, length=19999):
    return [(node, node + 1, length) for node in range(1, node_count)]


def star_tree(node_count, length=19999):
    return [(1, node, length) for node in range(2, node_count + 1)]


SAMPLE_INPUT = "1\n6\n1 2 3\n2 3 4 \n2 6 2\n6 4 6\n6 5 5\n"
SAMPLE_EDGES = [(1, 2, 3), (2, 3, 4), (2, 6, 2), (6, 4, 6), (6, 5, 5)]

assert oracle_diameter(6, SAMPLE_EDGES) == 12
assert brute_diameter(6, SAMPLE_EDGES) == 12
assert oracle_diameter(50000, path_tree(50000)) == 49999 * 19999
assert oracle_diameter(5, star_tree(5, 0)) == 0

check_rng = random.Random(99)
for _ in range(250):
    count = check_rng.randint(2, 9)
    edges = random_tree(check_rng, count)
    expected = brute_diameter(count, edges)
    assert oracle_diameter(count, edges) == expected
    assert sweep_diameter(count, edges) == expected


def render(cases):
    parts = [str(len(cases)) + "\n"]
    for node_count, edges in cases:
        parts.append(str(node_count) + "\n")
        for first, second, length in edges:
            parts.append(f"{first} {second} {length}\n")
    return "".join(parts)


def write(name, cases, input_text=None):
    if input_text is None:
        input_text = render(cases)
    answers = [str(oracle_diameter(node_count, edges)) for node_count, edges in cases]
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text("".join(answer + "\n" for answer in answers))


def build():
    write("1_sample", [(6, SAMPLE_EDGES)], SAMPLE_INPUT)

    edges_cases = [
        (2, [(1, 2, 0)]),
        (2, [(1, 2, 19999)]),
        (5, star_tree(5, 0)),
        (6, path_tree(6, 1)),
        (6, [(1, 2, 0), (2, 3, 0), (3, 4, 19999), (1, 5, 0), (5, 6, 0)]),
        (6, star_tree(6, 19999)),
    ]
    write("2_edges", edges_cases)

    write("3_wide", [
        (50000, path_tree(50000)),
        (50000, star_tree(50000)),
    ])

    rng = random.Random(424242)
    random_cases = []
    for _ in range(5):
        node_count = rng.randint(2, 50000)
        random_cases.append((node_count, random_tree(rng, node_count)))
    write("4_random", random_cases)

    io_rng = random.Random(777)
    io_count = 160000
    io_parts = [str(io_count) + "\n"]
    io_answers = []
    for _ in range(io_count):
        length = io_rng.randrange(20000)
        io_parts.append("2\n1 2 " + str(length) + "\n")
        io_answers.append(str(length) + "\n")
    (ROOT / "in" / "5_io.txt").write_text("".join(io_parts))
    (ROOT / "out" / "5_io.out").write_text("".join(io_answers))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
build()
print("generated five test pairs")
