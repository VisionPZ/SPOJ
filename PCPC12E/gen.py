#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def resolve_all(top, destination):
    final = [0] * (top + 1)
    for square in range(1, top + 1):
        if final[square] != 0:
            continue
        path = []
        current = square
        while destination[current] != 0 and final[current] == 0:
            path.append(current)
            current = destination[current]
        base = final[current] if final[current] != 0 else current
        for node in path:
            final[node] = base
        final[square] = base
    return final


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        rows, cols, snake_count, ladder_count = tokens[cursor:cursor + 4]
        cursor += 4
        top = rows * cols
        destination = [0] * (top + 1)
        for _ in range(snake_count):
            head = tokens[cursor]
            tail = tokens[cursor + 1]
            cursor += 2
            destination[head] = tail
        for _ in range(ladder_count):
            bottom = tokens[cursor]
            upper = tokens[cursor + 1]
            cursor += 2
            destination[bottom] = upper
        final = resolve_all(top, destination)
        seen = {0}
        frontier = {0}
        throws = 0
        while top not in seen and frontier:
            following = set()
            for square in frontier:
                for die in range(1, 7):
                    landing = square + die
                    if landing <= top:
                        following.add(final[landing])
            throws += 1
            frontier = following - seen
            seen |= following
        answers.append(str(throws) if top in seen else "-1")
    return "\n".join(answers) + "\n"


SAMPLE_INPUT = "1 1 0 0\n1 2 1 0\n2 1\n5 10 3 5\n16 6\n47 26\n49 11\n1 38\n4 14\n9 31\n40 42\n36 44\n"
SAMPLE_OUTPUT = "1\n-1\n3\n"
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1 1 0 0\n") == "1\n"
assert oracle("1 2 1 0\n2 1\n") == "-1\n"
assert oracle("1 100 6 0\n10 2\n11 3\n12 4\n13 5\n14 6\n15 7\n") == "-1\n"
assert oracle("10 10 0 3\n6 66\n66 88\n88 99\n") == "2\n"


def write(name, cases):
    text = "".join(case + "\n" for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def case_lines(rows, cols, snakes, ladders):
    return [f"{rows} {cols} {snakes} {ladders}"]


def make_case(rng, rows, cols, snake_count, ladder_count):
    top = rows * cols
    for _ in range(2000):
        heads = rng.sample(range(2, top + 1), snake_count)
        bottoms = rng.sample(range(1, top), ladder_count)
        sources = set(heads) | set(bottoms)
        if len(sources) != snake_count + ladder_count:
            continue
        destination_pool = [square for square in range(1, top + 1) if square not in sources]
        lines = case_lines(rows, cols, snake_count, ladder_count)
        valid = True
        for head in heads:
            tails = [square for square in destination_pool if square < head]
            if not tails:
                valid = False
                break
            lines.append(f"{head} {rng.choice(tails)}")
        if not valid:
            continue
        for bottom in bottoms:
            uppers = [square for square in destination_pool if square > bottom]
            if not uppers:
                valid = False
                break
            lines.append(f"{bottom} {rng.choice(uppers)}")
        if valid:
            return "\n".join(lines)
    raise RuntimeError("could not build a case")


def build():
    edges = []
    edges.append("\n".join(case_lines(1, 1, 0, 0)))
    edges.append("\n".join(case_lines(1, 2, 1, 0)) + "\n2 1")
    edges.append("\n".join(case_lines(1, 3, 0, 1)) + "\n1 2")
    edges.append("\n".join(case_lines(1, 3, 1, 0)) + "\n3 1")
    edges.append("\n".join(case_lines(1, 100, 6, 0)) + "\n10 2\n11 3\n12 4\n13 5\n14 6\n15 7")
    edges.append("\n".join(case_lines(10, 10, 0, 3)) + "\n6 66\n66 88\n88 99")
    write("2_edges", edges)
    rng = random.Random(20261126)
    wide = [make_case(rng, 10, 20, 8, 8) for _ in range(4)]
    write("3_wide", wide)
    random_cases = []
    for _ in range(25):
        rows = rng.randint(1, 8)
        cols = rng.randint(1, 8)
        top = rows * cols
        snake_count = min(rng.randint(0, 4), max(0, top - 2))
        ladder_count = min(rng.randint(0, 4), max(0, top - 2 - snake_count))
        random_cases.append(make_case(rng, rows, cols, snake_count, ladder_count))
    write("4_random", random_cases)
    write("5_io", ["\n".join(case_lines(1, 1, 0, 0))] * 70000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
