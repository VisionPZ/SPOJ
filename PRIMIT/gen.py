#!/usr/bin/env python3
from collections import defaultdict, deque
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def trail_answer(edges):
    if not edges:
        return 1
    out_degree = defaultdict(int)
    in_degree = defaultdict(int)
    neighbours = defaultdict(set)
    for left, right in edges:
        out_degree[left] += 1
        in_degree[right] += 1
        neighbours[left].add(right)
        neighbours[right].add(left)
    unseen = set(neighbours)
    component_count = 0
    while unseen:
        start = unseen.pop()
        stack = [start]
        component = [start]
        while stack:
            vertex = stack.pop()
            for neighbour in neighbours[vertex]:
                if neighbour in unseen:
                    unseen.remove(neighbour)
                    stack.append(neighbour)
                    component.append(neighbour)
        surplus = 0
        for vertex in component:
            extra = out_degree[vertex] - in_degree[vertex]
            if extra > 0:
                surplus += extra
        component_count += surplus if surplus else 1
    return len(edges) + component_count


def brute_walk(edges):
    if not edges:
        return 1
    vertices = sorted({vertex for edge in edges for vertex in edge})
    index = {vertex: number for number, vertex in enumerate(vertices)}
    full = (1 << len(edges)) - 1
    start_states = [(number, 0) for number in range(len(vertices))]
    distance = {state: 1 for state in start_states}
    queue = deque(start_states)
    outgoing = defaultdict(list)
    for number, (left, right) in enumerate(edges):
        outgoing[index[left]].append((number, index[right]))
    while queue:
        vertex, mask = queue.popleft()
        steps = distance[(vertex, mask)]
        if mask == full:
            return steps
        for target in range(len(vertices)):
            state = (target, mask)
            if state not in distance:
                distance[state] = steps + 1
                queue.append(state)
        for number, target in outgoing[vertex]:
            if not (mask >> number) & 1:
                state = (target, mask | (1 << number))
                if state not in distance:
                    distance[state] = steps + 1
                    queue.append(state)
    return -1


SAMPLE = [
    (2, 3), (3, 9), (9, 6), (8, 5), (5, 7), (7, 6),
    (4, 5), (5, 1), (1, 4), (4, 2), (2, 8), (8, 6),
]


def case_text(edges):
    lines = [str(len(edges))]
    lines.extend(f"{left} {right}" for left, right in edges)
    return "\n".join(lines) + "\n"


def write_cases(name, cases):
    input_text = str(len(cases)) + "\n" + "\n".join(case_text(c) for c in cases)
    output_text = "\n".join(str(trail_answer(c)) for c in cases) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


def check_known():
    assert trail_answer(SAMPLE) == 15
    assert trail_answer([(1, 2)]) == 2
    assert trail_answer([(1, 2), (3, 4)]) == 4
    assert trail_answer([(1, 2), (2, 3), (3, 1)]) == 4
    assert trail_answer([(1, 2), (1, 3), (1, 4)]) == 6
    assert trail_answer([(2, 1), (3, 1), (4, 1)]) == 6
    assert trail_answer([(1, 2), (2, 1), (3, 4), (4, 3)]) == 6
    complete = [(left, right) for left in range(1, 1001)
                for right in range(1, 1001) if left != right]
    assert len(complete) == 999000
    assert trail_answer(complete) == 999001
    random.seed(31337)
    for _ in range(300):
        vertex_count = random.randint(2, 5)
        pool = [(left, right) for left in range(1, vertex_count + 1)
                for right in range(1, vertex_count + 1) if left != right]
        edges = random.sample(pool, random.randint(1, min(8, len(pool))))
        assert trail_answer(edges) == brute_walk(edges), edges
    return complete


def build_edges():
    return [
        [(1, 2)],
        [(1, 2), (3, 4)],
        [(1, 2), (2, 3), (3, 1)],
        [(1, 2), (1, 3), (1, 4)],
        [(2, 1), (3, 1), (4, 1)],
        [(1, 2), (2, 1), (3, 4), (4, 3)],
        [(1, 1000), (1000, 1)],
        [(1, 2), (1, 3), (4, 5), (5, 4)],
        [(1000, 999), (999, 1000), (999, 998), (998, 999)],
        [(1, 1000)],
    ]


def build_wide(complete):
    small_square = [(left, right) for left in range(1, 5)
                    for right in range(1, 5) if left != right]
    return [
        [(1, right) for right in range(2, 1001)],
        [(left, 1) for left in range(2, 1001)],
        [(left, left + 1) for left in range(1, 1000)],
        small_square,
        complete,
    ]


def build_random():
    random.seed(2026)
    pool = [(left, right) for left in range(1, 13)
            for right in range(1, 13) if left != right]
    cases = []
    for _ in range(300):
        edges = random.sample(pool, random.randint(1, 9))
        assert trail_answer(edges) == brute_walk(edges), edges
        cases.append(edges)
    return cases


def build_io():
    random.seed(777)
    pool = [(left, right) for left in range(1, 9)
            for right in range(1, 9) if left != right]
    return [random.sample(pool, random.randint(1, 4)) for _ in range(200000)]


def main():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    complete = check_known()
    write_cases("1_sample", [SAMPLE])
    write_cases("2_edges", build_edges())
    write_cases("3_wide", build_wide(complete))
    write_cases("4_random", build_random())
    write_cases("5_io", build_io())


if __name__ == "__main__":
    main()
