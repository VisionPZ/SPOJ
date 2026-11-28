#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def fits(first, second):
    return first[0] < second[0] and first[1] < second[1]


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        doll_count = tokens[cursor]
        cursor += 1
        dolls = []
        for _ in range(doll_count):
            dolls.append((tokens[cursor], tokens[cursor + 1]))
            cursor += 2
        match_right = [-1] * doll_count

        def augment(left, seen):
            for right in range(doll_count):
                if right in seen or not fits(dolls[left], dolls[right]):
                    continue
                seen.add(right)
                if match_right[right] == -1 or augment(match_right[right], seen):
                    match_right[right] = left
                    return True
            return False

        matching = 0
        for left in range(doll_count):
            if augment(left, set()):
                matching += 1
        answers.append(str(doll_count - matching))
    return "\n".join(answers) + ("\n" if answers else "")


SAMPLE = """4
3
20 30 40 50 30 40
4
20 30 10 10 30 20 40 50
3
10 30 20 20 30 10
4
10 10 20 30 40 50 39 51
"""
SAMPLE_OUT = """1
2
3
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n5 7\n") == "1\n"
assert oracle("1\n3\n5 5 5 5 5 5\n") == "3\n"
assert oracle("1\n2\n1 2 2 1\n") == "2\n"


def brute_antichain(dolls):
    best = 0
    for mask in range(1, 1 << len(dolls)):
        members = [index for index in range(len(dolls)) if mask >> index & 1]
        if all(not fits(dolls[left], dolls[right])
               for left in members for right in members if left != right):
            best = max(best, len(members))
    return best


rng = random.Random(20261126)
for _ in range(40):
    small = [(rng.randint(1, 6), rng.randint(1, 6)) for _ in range(rng.randint(1, 8))]
    text = "1\n" + str(len(small)) + "\n" + " ".join(
        str(value) for pair in small for value in pair) + "\n"
    assert int(oracle(text)) == brute_antichain(small)


def write(name, cases):
    lines = [str(len(cases))]
    for dolls in cases:
        lines.append(str(len(dolls)))
        lines.append(" ".join(str(value) for pair in dolls for value in pair))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        [(5, 5)],
        [(5, 5), (6, 6), (7, 7)],
        [(1, 5), (5, 1), (2, 2)],
        [(1, 1), (2, 3), (4, 5), (39, 51)],
    ])
    write("3_wide", [[(index, 10001 - index) for index in range(1, 501)]])
    rng = random.Random(20261127)
    write("4_random", [[(rng.randint(1, 10000), rng.randint(1, 10000))
                        for _ in range(rng.randint(1, 150))] for _ in range(10)])
    write("5_io", [[(rng.randint(1, 10000), rng.randint(1, 10000))
                    for _ in range(150)] for _ in range(20)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    [(20, 30), (40, 50), (30, 40)],
    [(20, 30), (10, 10), (30, 20), (40, 50)],
    [(10, 30), (20, 20), (30, 10)],
    [(10, 10), (20, 30), (40, 50), (39, 51)],
])
build()
