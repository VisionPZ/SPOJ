#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    question_count, first_cost, copy_cost, time_limit = tokens[0:4]
    pair_count = tokens[4]
    neighbours = [[] for _ in range(question_count + 1)]
    position = 5
    for _ in range(pair_count):
        left_question, right_question = tokens[position:position + 2]
        position += 2
        neighbours[left_question].append(right_question)
        neighbours[right_question].append(left_question)
    visited = [False] * (question_count + 1)
    components = 0
    for start in range(1, question_count + 1):
        if visited[start]:
            continue
        components += 1
        stack = [start]
        visited[start] = True
        while stack:
            current = stack.pop()
            for neighbour in neighbours[current]:
                if not visited[neighbour]:
                    visited[neighbour] = True
                    stack.append(neighbour)
    total = components * first_cost + (question_count - components) * copy_cost
    return "YES\n" if total <= time_limit else "NO\n"


SAMPLE = """6 3 1 10
4
1 2
1 3
4 3
5 6
"""
SAMPLE_OUT = "YES\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("6 3 1 9\n4\n1 2\n1 3\n4 3\n5 6\n") == "NO\n"
assert oracle("1 5 1 5\n1\n1 1\n") == "YES\n"
assert oracle("2 5 1 5\n1\n1 2\n") == "NO\n"


def write(name, question_count, first_cost, copy_cost, time_limit, pairs):
    lines = [f"{question_count} {first_cost} {copy_cost} {time_limit}",
             str(len(pairs))]
    lines.extend(f"{left} {right}" for left, right in pairs)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 5, 1, 5, [])
    write("3_wide", 10000, 100000, 100000, 1000000000,
          [(index, index + 1) for index in range(1, 10000)])
    rng = random.Random(20261126)
    pairs = [(rng.randint(1, 200), rng.randint(1, 200)) for _ in range(400)]
    write("4_random", 200, 3, 1, 400, pairs)
    write("5_io", 1000, 7, 2, 3000,
          [(rng.randint(1, 1000), rng.randint(1, 1000)) for _ in range(2000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 6, 3, 1, 10, [(1, 2), (1, 3), (4, 3), (5, 6)])
build()

if __name__ == "__main__":
    rng3 = random.Random(11)
    n_big = 1000000
    m_big = 1000000
    lines = ["%d 100000 1 1000000000" % n_big, str(m_big)]
    for _ in range(m_big):
        lines.append("%d %d" % (rng3.randint(1, n_big), rng3.randint(1, n_big)))
    Path("/tmp/MATHEXAM_big.txt").write_text("\n".join(lines) + "\n")
