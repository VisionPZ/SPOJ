#!/usr/bin/env python3
import os
import random


def oracle_case(vertex_count, edges):
    value = [0] * (vertex_count + 1)
    for iteration in range(vertex_count):
        changed = False
        for from_vertex, to_vertex, weight in edges:
            if value[to_vertex] < value[from_vertex] + weight:
                value[to_vertex] = value[from_vertex] + weight
                changed = True
        if iteration == vertex_count - 1 and changed:
            return "NO"
        if not changed:
            break
    return str(max(value))


def edge_list(vertex_count, pairs):
    result = []
    for from_vertex, to_vertex, label in pairs:
        if label == 0:
            result.append((from_vertex, to_vertex, 0))
            result.append((to_vertex, from_vertex, 0))
        elif label < 0:
            result.append((from_vertex, to_vertex, 1))
        else:
            result.append((to_vertex, from_vertex, 1))
    return result


def emit(name, cases):
    input_lines = [str(len(cases))]
    output_lines = []
    for vertex_count, pairs in cases:
        assert 1 <= vertex_count <= 1000
        assert len(pairs) <= 10000
        seen = set()
        for from_vertex, to_vertex, label in pairs:
            assert 1 <= from_vertex <= vertex_count
            assert 1 <= to_vertex <= vertex_count
            assert from_vertex != to_vertex
            assert (from_vertex, to_vertex) not in seen
            seen.add((from_vertex, to_vertex))
            assert label in (-1, 0, 1)
        input_lines.append("%d %d" % (vertex_count, len(pairs)))
        tokens = []
        for from_vertex, to_vertex, label in pairs:
            tokens.extend((str(from_vertex), str(to_vertex), str(label)))
        input_lines.append(" ".join(tokens))
        output_lines.append(oracle_case(vertex_count, edge_list(vertex_count, pairs)))
    with open(os.path.join("in", name + ".txt"), "w") as handle:
        handle.write("\n".join(input_lines) + "\n")
    with open(os.path.join("out", name + ".out"), "w") as handle:
        handle.write("\n".join(output_lines) + "\n")


def chain_edges(vertex_count):
    return [(index, index + 1, -1) for index in range(1, vertex_count)]


def full_case(vertex_count, edge_count):
    pairs = chain_edges(vertex_count)
    seen = set((from_vertex, to_vertex) for from_vertex, to_vertex, label in pairs)
    for from_vertex in range(1, vertex_count + 1):
        for to_vertex in range(from_vertex + 1, vertex_count + 1):
            if (from_vertex, to_vertex) in seen:
                continue
            seen.add((from_vertex, to_vertex))
            pairs.append((from_vertex, to_vertex, -1))
            if len(pairs) == edge_count:
                return pairs
    return pairs


def grouped_case(group_count, edge_count):
    vertex_count = group_count * 4
    pairs = []
    for first_vertex in range(1, vertex_count + 1, 4):
        for left in range(first_vertex, first_vertex + 4):
            for right in range(left + 1, first_vertex + 4):
                pairs.append((left, right, 0))
    for group in range(group_count - 1):
        for left in range(group * 4 + 1, group * 4 + 5):
            for right in range(group * 4 + 5, group * 4 + 9):
                pairs.append((left, right, -1))
    for left_group in range(group_count):
        for right_group in range(left_group + 2, group_count):
            for left in range(left_group * 4 + 1, left_group * 4 + 5):
                for right in range(right_group * 4 + 1, right_group * 4 + 5):
                    pairs.append((left, right, -1))
                    if len(pairs) == edge_count:
                        return pairs
    return pairs


def check_known_values():
    sample = build_sample()
    sample_answers = [oracle_case(n, edge_list(n, pairs)) for n, pairs in sample]
    assert sample_answers == ["2", "NO", "1", "0"]
    base = [(1, 2, -1), (2, 3, -1), (3, 4, -1), (5, 6, -1), (6, 4, -1), (3, 5, 0)]
    assert oracle_case(6, edge_list(6, base)) == "4"
    assert oracle_case(6, edge_list(6, base + [(5, 3, 1)])) == "NO"
    assert oracle_case(6, edge_list(6, base + [(3, 2, -1)])) == "NO"
    assert oracle_case(1000, edge_list(1000, chain_edges(1000))) == "999"


def build_sample():
    return [
        (4, [(1, 2, -1), (2, 3, 0), (2, 4, -1), (3, 4, -1)]),
        (2, [(1, 2, -1), (2, 1, -1)]),
        (2, [(1, 2, -1), (2, 1, 1)]),
        (3, [(1, 2, 0), (3, 2, 0), (3, 1, 0)]),
    ]


def build_edges():
    base = [(1, 2, -1), (2, 3, -1), (3, 4, -1), (5, 6, -1), (6, 4, -1), (3, 5, 0)]
    return [
        (1, []),
        (5, []),
        (3, [(1, 2, 0), (2, 3, 0)]),
        (4, chain_edges(4)),
        (2, [(1, 2, -1), (2, 1, -1)]),
        (2, [(1, 2, 0), (2, 1, -1)]),
        (2, [(1, 2, 1)]),
        (6, base),
        (6, base + [(5, 3, 1)]),
        (6, base + [(3, 2, -1)]),
    ]


def build_wide():
    forward = full_case(1000, 9999)
    cyclic = list(forward)
    cyclic.append((2, 1, -1))
    assert len(forward) == 9999
    assert len(cyclic) == 10000
    return [
        (1000, full_case(1000, 10000)),
        (1000, cyclic),
        (1000, grouped_case(250, 10000)),
    ]


def build_random():
    rng = random.Random(20261123)
    cases = []
    for case_index in range(10):
        vertex_count = rng.randint(1, 60)
        limit = min(10000, vertex_count * (vertex_count - 1), 300)
        edge_count = rng.randint(0, limit)
        if case_index % 2 == 0:
            levels = [rng.randint(0, min(30, vertex_count)) for _ in range(vertex_count + 1)]
        else:
            levels = list(range(1, vertex_count + 1)) + [0]
            rng.shuffle(levels)
        pairs = []
        seen = set()
        attempts = 0
        while len(pairs) < edge_count and attempts < 10000:
            attempts += 1
            from_vertex = rng.randint(1, vertex_count)
            to_vertex = rng.randint(1, vertex_count)
            if from_vertex == to_vertex or (from_vertex, to_vertex) in seen:
                continue
            if case_index % 3 == 0:
                label = rng.choice((-1, 0, 1))
            elif levels[from_vertex] < levels[to_vertex]:
                label = -1
            elif levels[from_vertex] > levels[to_vertex]:
                label = 1
            else:
                label = 0
            seen.add((from_vertex, to_vertex))
            pairs.append((from_vertex, to_vertex, label))
        cases.append((vertex_count, pairs))
    return cases


def build_io():
    return [(1000, chain_edges(1000)) for _ in range(10)]


def main():
    check_known_values()
    emit("1_sample", build_sample())
    emit("2_edges", build_edges())
    emit("3_wide", build_wide())
    emit("4_random", build_random())
    emit("5_io", build_io())


if __name__ == "__main__":
    main()
