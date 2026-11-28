#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def canonical(order):
    start = order.index(1)
    rotated = order[start:] + order[:start]
    before = rotated[-1]
    after = rotated[1]
    if before < after:
        return [rotated[0]] + list(reversed(rotated[1:]))
    return rotated


def brute(vertex_count, edges):
    edge_set = {frozenset(pair) for pair in edges}
    for permutation in itertools.permutations(range(2, vertex_count + 1)):
        order = (1,) + permutation
        if all(frozenset((order[index], order[(index + 1) % vertex_count])) in edge_set
               for index in range(vertex_count)):
            return canonical(list(order))
    return []


def make_case(vertex_count, diagonal_count, seed):
    rng = random.Random(seed)
    order = list(range(1, vertex_count + 1))
    rng.shuffle(order)
    if order[0] != 1:
        order.remove(1)
        order.insert(0, 1)
    result = canonical(order)

    forward = [(position + 1) % vertex_count for position in range(vertex_count)]
    backward = [(position - 1) % vertex_count for position in range(vertex_count)]
    alive_positions = list(range(vertex_count))
    chords = []
    for size in range(vertex_count, 3, -1):
        pick = rng.randrange(size)
        position = alive_positions[pick]
        left = backward[position]
        right = forward[position]
        forward[left] = right
        backward[right] = left
        first = result[left]
        second = result[right]
        chords.append((min(first, second), max(first, second)))
        alive_positions[pick] = alive_positions[size - 1]
        alive_positions.pop()

    diagonals = rng.sample(chords, diagonal_count)
    sides = []
    for position in range(vertex_count):
        first = result[position]
        second = result[(position + 1) % vertex_count]
        sides.append((min(first, second), max(first, second)))

    assert len(sides) == vertex_count
    assert len(set(sides)) == vertex_count
    assert len(diagonals) == diagonal_count
    assert len(set(diagonals)) == diagonal_count
    assert not (set(sides) & set(diagonals))
    assert set(result) == set(range(1, vertex_count + 1))
    assert result[0] == 1
    assert result[1] < result[-1]

    edges = sides + diagonals
    rng.shuffle(edges)
    verify_order(vertex_count, edges, result)
    if vertex_count <= 9:
        assert brute(vertex_count, edges) == result
    return vertex_count, edges, diagonal_count, result


def verify_order(vertex_count, edges, order):
    edge_set = {frozenset(pair) for pair in edges}
    assert len(order) == vertex_count
    assert set(order) == set(range(1, vertex_count + 1))
    assert order[0] == 1
    assert order[1] < order[-1]
    assert len(edge_set) == vertex_count + (len(edges) - vertex_count)
    for position in range(vertex_count):
        pair = (order[position], order[(position + 1) % vertex_count])
        assert frozenset(pair) in edge_set


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        vertex_count = int(tokens[cursor])
        cursor += 1
        diagonal_count = int(tokens[cursor])
        cursor += 1
        edges = []
        for _ in range(vertex_count + diagonal_count):
            first = int(tokens[cursor])
            cursor += 1
            second = int(tokens[cursor])
            cursor += 1
            edges.append((first, second))
        answers.append(" ".join(map(str, brute(vertex_count, edges))))
    return "\n".join(answers) + "\n"


def write_raw(name, text, expected):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(expected)


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        f"{vertex_count} {diagonal_count}\n" +
        " ".join(str(value) for pair in edges for value in pair) + "\n"
        for vertex_count, edges, diagonal_count, _ in cases)
    expected = "\n".join(
        " ".join(map(str, order)) for _, _, _, order in cases) + "\n"
    if all(vertex_count <= 9 for vertex_count, _, _, _ in cases):
        assert oracle(text) == expected
    write_raw(name, text, expected)


def build():
    write("2_edges", [
        make_case(3, 0, 10),
        make_case(4, 0, 11),
        make_case(5, 0, 12),
        make_case(5, 1, 13),
        make_case(6, 3, 14),
        make_case(7, 2, 15),
        make_case(8, 4, 16),
        make_case(9, 6, 17),
    ])

    write("3_wide", [
        make_case(9, 6, 100 + seed) for seed in range(6)
    ] + [
        make_case(12, 9, 200 + seed) for seed in range(6)
    ])

    chooser = random.Random(2024)
    random_cases = []
    for seed in range(90):
        vertex_count = chooser.randint(3, 12)
        diagonal_count = chooser.randint(0, vertex_count - 3)
        random_cases.append(make_case(vertex_count, diagonal_count, 500 + seed))
    write("4_random", random_cases)

    io_cases = []
    for seed in range(20):
        io_cases.append(make_case(10000, 9997, 900 + seed))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

SAMPLE_TEXT = "1\n4 1\n1 3 4 2 1 2\n4 1 2 3\n"
SAMPLE_EDGES = [(1, 3), (4, 2), (1, 2), (4, 1), (2, 3)]
assert brute(4, SAMPLE_EDGES) == [1, 3, 2, 4]
assert oracle(SAMPLE_TEXT) == "1 3 2 4\n"
write_raw("1_sample", SAMPLE_TEXT, "1 3 2 4\n")
build()
