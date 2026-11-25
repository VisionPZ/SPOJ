#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    name_count = int(tokens[cursor]); cursor += 1
    relation_count = int(tokens[cursor]); cursor += 1
    edges = []
    for _ in range(relation_count):
        first = tokens[cursor]; second = tokens[cursor + 1]; cursor += 2
        edges.append((first, second))
    query_count = int(tokens[cursor]); cursor += 1
    queries = []
    for _ in range(query_count):
        kind = int(tokens[cursor]); cursor += 1
        if kind == 1:
            queries.append((kind, tokens[cursor], tokens[cursor + 1], tokens[cursor + 2], tokens[cursor + 3]))
            cursor += 4
        else:
            queries.append((kind, tokens[cursor], tokens[cursor + 1], tokens[cursor + 2], None))
            cursor += 3

    def reachable(start, target, removed_vertex=None, removed_edge=None):
        if start == removed_vertex or target == removed_vertex:
            return False
        if start == target:
            return True
        graph = {}
        for first, second in edges:
            if removed_edge is not None and {first, second} == removed_edge:
                continue
            if first == removed_vertex or second == removed_vertex:
                continue
            graph.setdefault(first, []).append(second)
            graph.setdefault(second, []).append(first)
        seen = {start}
        queue = deque([start])
        while queue:
            current = queue.popleft()
            for neighbor in graph.get(current, []):
                if neighbor == target:
                    return True
                if neighbor not in seen:
                    seen.add(neighbor)
                    queue.append(neighbor)
        return False

    lines = []
    for kind, first, second, third, fourth in queries:
        if kind == 1:
            stable = reachable(first, second, removed_edge={third, fourth})
        else:
            stable = reachable(first, second, removed_vertex=third)
        lines.append("STABLE" if stable else "NOT STABLE")
    return "\n".join(lines) + "\n" if lines else ""


SAMPLE = """3 2
Person1 Person2
Person1 Person3
2
2 Person2 Person3 Person1
1 Person1 Person2 Person1 Person3
"""
SAMPLE_OUT = """NOT STABLE
STABLE
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 1\nA B\n2\n1 A B C D\n2 A B A\n") == "STABLE\nNOT STABLE\n"
assert oracle("3 2\nA B\nB C\n2\n1 A C B C\n2 A C B\n") == "NOT STABLE\nNOT STABLE\n"
assert oracle("4 3\nA B\nB C\nC D\n2\n1 A D B C\n2 A D B\n") == "NOT STABLE\nNOT STABLE\n"


def write(name, people, relations, queries):
    lines = [f"{people} {len(relations)}"]
    lines.extend(f"{first} {second}" for first, second in relations)
    lines.append(str(len(queries)))
    lines.extend(" ".join(str(token) for token in query) for query in queries)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE2 = """17 18
Person1 Person2
Person1 Person4
Person2 Person4
Person4 Person6
Person2 Person6
Person2 Person3
Person3 Person5
Person1 Person7
Person7 Person8
Person7 Person9
Person7 Person10
Person9 Person12
Person8 Person12
Person8 Person11
Person12 Person13
Person14 Person15
Person15 Person16
Person16 Person17
8
2 Person1 Person14 Person7
2 Person1 Person2 Person2
1 Person1 Person14 Person2 Person4
1 Person5 Person13 Person1 Person2
1 Person6 Person2 Person1 Person4
1 Person13 Person6 Person7 Person8
2 Person13 Person6 Person7
2 Person13 Person6 Person8
2 Person13 Person8 Person7
"""
SAMPLE2_OUT = """NOT STABLE
NOT STABLE
NOT STABLE
STABLE
STABLE
STABLE
NOT STABLE
STABLE
"""
assert oracle(SAMPLE2) == SAMPLE2_OUT


def build():
    write("2_edges", 4, [("A", "B"), ("B", "C"), ("C", "D")],
          [(1, "A", "D", "B", "C"), (1, "A", "B", "X", "Y"),
           (2, "A", "D", "B"), (2, "B", "C", "C"), (2, "A", "A", "B")])
    chain = [(f"Person{index}", f"Person{index + 1}") for index in range(7)]
    wide_queries = [
        (2, "Person0", "Person7", "Person3"),
        (2, "Person1", "Person2", "Person0"),
        (1, "Person0", "Person7", "Person3", "Person4"),
        (2, "Person5", "Person6", "Person2"),
        (1, "Person0", "Person7", "Person2", "Person3"),
    ]
    write("3_wide", 8, chain, wide_queries)
    rng = random.Random(20261126)
    people = [f"Person{index}" for index in range(10)]
    relations = [(f"Person{index}", f"Person{index + 1}") for index in range(9)]
    for _ in range(6):
        first = rng.randint(0, 9)
        second = rng.randint(0, 9)
        if first != second:
            relations.append((f"Person{first}", f"Person{second}"))
    random_queries = []
    for _ in range(25):
        picked = [rng.choice(people) for _ in range(4)]
        if rng.random() < 0.5:
            random_queries.append((1, *picked))
        else:
            random_queries.append((2, *picked[:3]))
    write("4_random", 10, relations, random_queries)

    big_people = [f"Person{index}" for index in range(40)]
    big_relations = [(f"Person{index}", f"Person{index + 1}") for index in range(39)]
    for _ in range(40):
        first = rng.randint(0, 39)
        second = rng.randint(0, 39)
        if first != second:
            big_relations.append((f"Person{first}", f"Person{second}"))
    io_queries = []
    for _ in range(300):
        picked = [rng.choice(big_people) for _ in range(4)]
        if rng.random() < 0.5:
            io_queries.append((1, *picked))
        else:
            io_queries.append((2, *picked[:3]))
    write("5_io", 40, big_relations, io_queries)

    huge_lines = ["10000 50000"]
    huge_lines.append("\n".join(f"Person{index} Person{index + 1}" for index in range(9999)))
    rng = random.Random(20261127)
    for _ in range(40001):
        first = rng.randrange(10000)
        second = rng.randrange(10000)
        if first == second:
            second = (second + 1) % 10000
        huge_lines.append(f"Person{first} Person{second}")
    huge_lines.append("10000")
    for _ in range(10000):
        first = rng.randrange(10000)
        second = rng.randrange(10000)
        cut = rng.randrange(10000)
        if rng.random() < 0.5:
            other = rng.randrange(10000)
            huge_lines.append(f"1 Person{first} Person{second} Person{cut} Person{other}")
        else:
            huge_lines.append(f"2 Person{first} Person{second} Person{cut}")
    Path("/tmp/QSTABLE_big.txt").write_text("\n".join(huge_lines) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 3, [("Person1", "Person2"), ("Person1", "Person3")],
      [(2, "Person2", "Person3", "Person1"), (1, "Person1", "Person2", "Person1", "Person3")])
build()
