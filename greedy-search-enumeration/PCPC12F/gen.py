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


def format_fixed3(value):
    scaled = int(value * 1000 + 0.5)
    whole = scaled // 1000
    fraction = scaled % 1000
    return f"{whole}.{fraction:03d}"


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
        values = [0.0] * (top + 1)
        for _ in range(200000):
            largest_change = 0.0
            for square in range(top):
                total = 0.0
                for die in range(1, 7):
                    raw = square + die
                    following = final[raw] if raw <= top else square
                    total += values[following]
                updated = 1.0 + total / 6.0
                largest_change = max(largest_change, abs(updated - values[square]))
                values[square] = updated
            if largest_change < 1e-13:
                break
        answers.append(format_fixed3(values[0]))
    return "\n".join(answers) + "\n"


SAMPLE_INPUT = "5 10 3 5\n16 6\n47 26\n49 11\n1 38\n4 14\n9 31\n40 42\n36 44\n"
SAMPLE_OUTPUT = "30.198\n"
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1 1 0 0\n") == "6.000\n"
assert oracle("1 2 0 0\n") == "6.000\n"
assert format_fixed3(30.1978227) == "30.198"
assert format_fixed3(1.0) == "1.000"


def write(name, cases):
    text = "".join(case + "\n" for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_case(rng, rows, cols, snake_count, ladder_count):
    top = rows * cols
    for _ in range(2000):
        heads = rng.sample(range(2, top), snake_count)
        bottoms = rng.sample(range(1, top - 1), ladder_count)
        sources = set(heads) | set(bottoms)
        if len(sources) != snake_count + ladder_count:
            continue
        destination_pool = [square for square in range(1, top) if square not in sources]
        lines = [f"{rows} {cols} {snake_count} {ladder_count}"]
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
    write("2_edges", ["1 1 0 0", "1 2 0 0", "1 3 0 1\n1 2", "2 2 1 0\n3 1"])
    rng = random.Random(20261126)
    write("3_wide", [make_case(rng, 10, 10, 6, 6) for _ in range(4)])
    random_cases = []
    for _ in range(20):
        rows = rng.randint(1, 6)
        cols = rng.randint(1, 6)
        top = rows * cols
        snake_count = min(rng.randint(0, 3), max(0, top - 3))
        ladder_count = min(rng.randint(0, 3), max(0, top - 3 - snake_count))
        random_cases.append(make_case(rng, rows, cols, snake_count, ladder_count))
    write("4_random", random_cases)
    write("5_io", ["1 1 0 0"] * 30000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
