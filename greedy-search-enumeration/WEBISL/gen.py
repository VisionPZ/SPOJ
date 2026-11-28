#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(token) for token in text.split()]
    page_count = tokens[0]
    link_count = tokens[1]
    adjacency = [[] for _ in range(page_count)]
    for link_index in range(link_count):
        source = tokens[2 + 2 * link_index]
        target = tokens[3 + 2 * link_index]
        adjacency[source].append(target)
    reachable = []
    for start in range(page_count):
        seen = [False] * page_count
        seen[start] = True
        queue = deque([start])
        while queue:
            current = queue.popleft()
            for target in adjacency[current]:
                if not seen[target]:
                    seen[target] = True
                    queue.append(target)
        reachable.append(seen)
    answers = []
    for page in range(page_count):
        members = [other for other in range(page_count)
                   if reachable[page][other] and reachable[other][page]]
        answers.append(str(min(members)))
    return "\n".join(answers) + "\n"


SAMPLE = """3 3
0 1
1 0
1 2
"""
SAMPLE_OUT = """0
0
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 0\n") == "0\n1\n2\n"
assert oracle("2 2\n0 1\n1 0\n") == "0\n0\n"
assert oracle("4 4\n0 1\n1 2\n2 3\n3 0\n") == "0\n0\n0\n0\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "6 0\n")
    cycles = []
    for group in range(6):
        members = list(range(group * 12, group * 12 + 12))
        for position, member in enumerate(members):
            cycles.append((member, members[(position + 1) % 12]))
    write("3_wide", f"{72} {len(cycles)}\n" +
          "".join(f"{source} {target}\n" for source, target in cycles))
    rng = random.Random(20261126)
    edges = [(rng.randrange(30), rng.randrange(30)) for _ in range(60)]
    write("4_random", "30 " + str(len(edges)) + "\n" +
          "".join(f"{source} {target}\n" for source, target in edges))
    islands = []
    for group in range(100):
        members = list(range(group * 20, group * 20 + 20))
        for position, member in enumerate(members):
            islands.append((member, members[(position + 1) % 20]))
    write("5_io", f"{2000} {len(islands)}\n" +
          "".join(f"{source} {target}\n" for source, target in islands))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
