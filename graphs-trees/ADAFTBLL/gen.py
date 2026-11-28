#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    friend_count = tokens[cursor]
    query_count = tokens[cursor + 1]
    cursor += 2
    teams = tokens[cursor:cursor + friend_count]
    cursor += friend_count
    adjacency = [[] for _ in range(friend_count)]
    for _ in range(friend_count - 1):
        endpoint_one = tokens[cursor]
        endpoint_two = tokens[cursor + 1]
        cursor += 2
        adjacency[endpoint_one].append(endpoint_two)
        adjacency[endpoint_two].append(endpoint_one)
    parents = [-1] * friend_count
    depths = [0] * friend_count
    parents[0] = 0
    queue = deque([0])
    while queue:
        current = queue.popleft()
        for neighbor in adjacency[current]:
            if neighbor != parents[current]:
                parents[neighbor] = current
                depths[neighbor] = depths[current] + 1
                queue.append(neighbor)
    answers = []
    for _ in range(query_count):
        kind = tokens[cursor]
        cursor += 1
        if kind == 1:
            target = tokens[cursor]
            new_team = tokens[cursor + 1]
            cursor += 2
            teams[target] = new_team
        else:
            start = tokens[cursor]
            finish = tokens[cursor + 1]
            cursor += 2
            left_side = []
            right_side = []
            while start != finish:
                if depths[start] >= depths[finish]:
                    left_side.append(start)
                    start = parents[start]
                else:
                    right_side.append(finish)
                    finish = parents[finish]
            left_side.append(start)
            path_nodes = left_side + right_side[::-1]
            seen = {}
            happiness = 0
            for node in path_nodes:
                team = teams[node]
                happiness += seen.get(team, 0)
                seen[team] = seen.get(team, 0) + 1
            answers.append(str(happiness))
    return "\n".join(answers) + "\n" if answers else ""


SAMPLE = """7 8
0 0 1 2 1 1 2
0 1
1 5
1 2
2 4
2 3
3 6
2 4 5
2 0 6
2 1 3
1 1 2
1 2 2
2 4 5
2 0 6
2 1 3
"""
SAMPLE_OUT = """3
2
0
2
6
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n0\n2 0 0\n") == "0\n"
assert oracle("2 2\n0 0\n0 1\n2 0 1\n1 0 1\n") == "1\n"
assert oracle("3 3\n0 0 0\n0 1\n1 2\n2 0 2\n1 2 0\n2 0 2\n") == "3\n3\n"
assert oracle("4 2\n0 1 0 1\n0 1\n1 2\n2 3\n2 0 3\n1 1 0\n") == "2\n"


def write(name, friend_count, teams, edges, queries):
    lines = [f"{friend_count} {len(queries)}", " ".join(str(team) for team in teams)]
    lines.extend(f"{endpoint_one} {endpoint_two}" for endpoint_one, endpoint_two in edges)
    lines.extend(f"{kind} {first} {second}" for kind, first, second in queries)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 5, [0, 1, 0, 1, 0], [(0, 1), (1, 2), (2, 3), (3, 4)],
          [(2, 0, 4), (1, 2, 0), (2, 0, 4), (2, 3, 3)])
    write("3_wide", 12, [index % 4 for index in range(12)],
          [(index - 1, index) for index in range(1, 12)],
          [(2, 0, 11), (2, 5, 9), (1, 6, 2), (2, 5, 9), (2, 1, 10)])
    rng = random.Random(20261126)
    friend_count = 24
    teams = [rng.randint(0, 7) for _ in range(friend_count)]
    edges = [(rng.randint(0, index - 1), index) for index in range(1, friend_count)]
    queries = []
    for query_index in range(50):
        if query_index % 4 == 0:
            queries.append((1, rng.randint(0, friend_count - 1), rng.randint(0, 7)))
        else:
            queries.append((2, rng.randint(0, friend_count - 1), rng.randint(0, friend_count - 1)))
    write("4_random", friend_count, teams, edges, queries)
    friend_count = 30
    teams = [index % 6 for index in range(friend_count)]
    edges = [(index - 1, index) for index in range(1, friend_count)]
    queries = []
    for query_index in range(120):
        if query_index % 5 == 0:
            queries.append((1, rng.randint(0, friend_count - 1), rng.randint(0, 6)))
        else:
            queries.append((2, rng.randint(0, friend_count - 1), rng.randint(0, friend_count - 1)))
    write("5_io", friend_count, teams, edges, queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 7, [0, 0, 1, 2, 1, 1, 2],
      [(0, 1), (1, 5), (1, 2), (2, 4), (2, 3), (3, 6)],
      [(2, 4, 5), (2, 0, 6), (2, 1, 3), (1, 1, 2), (1, 2, 2),
       (2, 4, 5), (2, 0, 6), (2, 1, 3)])
build()
