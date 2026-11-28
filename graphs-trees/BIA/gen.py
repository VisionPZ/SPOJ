#!/usr/bin/env python3
import random
import os

ROOT = os.path.dirname(os.path.abspath(__file__))


def oracle(vertex_count, edges):
    predecessors = [[] for _ in range(vertex_count + 1)]
    for source, target in edges:
        predecessors[target].append(source)
    full_set = (1 << (vertex_count + 1)) - 2
    dom = [full_set] * (vertex_count + 1)
    dom[1] = 2
    adjacency = [[] for _ in range(vertex_count + 1)]
    for source, target in edges:
        adjacency[source].append(target)
    visit_order = []
    visited = [False] * (vertex_count + 1)
    stack = [1]
    visited[1] = True
    while stack:
        current = stack.pop()
        visit_order.append(current)
        for target in adjacency[current]:
            if not visited[target]:
                visited[target] = True
                stack.append(target)
    changed = True
    passes = 0
    while changed:
        changed = False
        passes += 1
        assert passes <= vertex_count + 5, "dominator fixpoint did not converge"
        for vertex in visit_order:
            if vertex == 1:
                continue
            new_set = full_set
            for parent in predecessors[vertex]:
                new_set &= dom[parent]
            new_set |= 1 << vertex
            if new_set != dom[vertex]:
                dom[vertex] = new_set
                changed = True
    strict_union = 0
    for vertex in range(1, vertex_count + 1):
        strict_union |= dom[vertex] & ~(1 << vertex)
    return [vertex for vertex in range(1, vertex_count + 1) if (strict_union >> vertex) & 1]


def format_case(vertex_count, edges):
    lines = ["%d %d" % (vertex_count, len(edges))]
    for source, target in edges:
        lines.append("%d %d" % (source, target))
    return "\n".join(lines) + "\n"


def format_answer(critical):
    return "%d\n%s\n" % (len(critical), " ".join(str(value) for value in critical))


def chain_edges(vertex_count, extra_edges, rng):
    edges = [(value, value + 1) for value in range(1, vertex_count)]
    seen = set(edges)
    while len(edges) < extra_edges:
        source = rng.randint(1, vertex_count)
        target = rng.randint(1, source)
        if (source, target) in seen:
            continue
        seen.add((source, target))
        edges.append((source, target))
    return edges


def random_edges(vertex_count, extra_edges, rng):
    edges = []
    seen = set()
    for vertex in range(2, vertex_count + 1):
        parent = rng.randint(1, vertex - 1)
        edges.append((parent, vertex))
        seen.add((parent, vertex))
    while len(edges) < extra_edges:
        source = rng.randint(1, vertex_count)
        target = rng.randint(1, vertex_count)
        if (source, target) in seen:
            continue
        seen.add((source, target))
        edges.append((source, target))
    return edges


def write_pair(name, cases):
    input_lines = []
    output_lines = []
    for vertex_count, edges in cases:
        input_lines.append(format_case(vertex_count, edges).rstrip("\n"))
        output_lines.append(format_answer(oracle(vertex_count, edges)).rstrip("\n"))
    with open(os.path.join(ROOT, "in", name + ".txt"), "w") as handle:
        handle.write("\n".join(input_lines) + "\n")
    with open(os.path.join(ROOT, "out", name + ".out"), "w") as handle:
        handle.write("\n".join(output_lines) + "\n")


assert oracle(4, [(1, 2), (1, 4), (2, 3), (3, 4), (4, 2)]) == [1, 2]
assert oracle(5, [(1, 2), (2, 3), (3, 4), (4, 5)]) == [1, 2, 3, 4]
assert oracle(6, [(1, value) for value in range(2, 7)]) == [1]
assert oracle(3, [(1, 2), (2, 3), (3, 2)]) == [1, 2]

write_pair("1_sample", [(4, [(1, 2), (1, 4), (2, 3), (3, 4), (4, 2)])])

edge_cases = []
edge_cases.append((2, [(1, 2)]))
edge_cases.append((5, [(1, 2), (2, 3), (3, 4), (4, 5)]))
edge_cases.append((6, [(1, value) for value in range(2, 7)]))
edge_cases.append((7, [(1, value) for value in range(2, 8)] + [(2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 2)]))
edge_cases.append((3, [(1, 2), (1, 3), (2, 3)]))
edge_cases.append((3, [(1, 2), (2, 3), (3, 2)]))
edge_cases.append((8, [(1, 2), (2, 3), (2, 4), (2, 5), (3, 6), (4, 6), (5, 6), (6, 7), (6, 8), (7, 8)]))
edge_cases.append((4, [(1, 2), (1, 4), (2, 3), (3, 4), (4, 2)]))
edge_cases.append((10, [(1, value) for value in range(2, 11)] + [(value, value + 1) for value in range(2, 10)]))
edge_cases.append((11, [(value, value + 1) for value in range(1, 11)] + [(value, 1) for value in range(2, 12)]))
write_pair("2_edges", edge_cases)

wide_rng = random.Random(91001)
wide_cases = []
wide_cases.append((5000, chain_edges(5000, 200000, wide_rng)))
wide_cases.append((5000, random_edges(5000, 200000, wide_rng)))
wide_cases.append((5000, chain_edges(5000, 100000, wide_rng)))
wide_cases.append((5000, chain_edges(5000, 4999, wide_rng)))
wide_cases.append((5000, random_edges(5000, 200000, wide_rng)))
wide_cases.append((5000, chain_edges(5000, 200000, wide_rng)))
wide_cases.append((5000, random_edges(5000, 150000, wide_rng)))
wide_cases.append((5000, chain_edges(5000, 120000, wide_rng)))
wide_cases.append((5000, random_edges(5000, 200000, wide_rng)))
wide_cases.append((5000, chain_edges(5000, 200000, wide_rng)))
write_pair("3_wide", wide_cases)

random_rng = random.Random(424242)
random_cases = []
for case_index in range(10):
    vertex_count = random_rng.randint(2, 5000)
    max_edges = min(200000, vertex_count * (vertex_count - 1))
    extra_edges = random_rng.randint(vertex_count - 1, max_edges)
    random_cases.append((vertex_count, random_edges(vertex_count, extra_edges, random_rng)))
write_pair("4_random", random_cases)

io_rng = random.Random(777)
io_cases = []
for case_index in range(10):
    io_cases.append((5000, chain_edges(5000, 4999, io_rng)))
write_pair("5_io", io_cases)
