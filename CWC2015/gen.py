#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for case_index in range(1, case_count + 1):
        player_count = tokens[cursor]; cursor += 1
        values = tokens[cursor:cursor + player_count]; cursor += player_count
        total = sum(values)
        possible = False
        if player_count % 2 == 0 and total % 2 == 0:
            half = player_count // 2
            target = total // 2
            achievable = [0] * (half + 1)
            achievable[0] = 1
            for value in values:
                for count in range(half - 1, -1, -1):
                    achievable[count + 1] |= achievable[count] << value
            possible = ((achievable[half] >> target) & 1) == 1
        answers.append("Case %d: %s" % (case_index, "Yes" if possible else "No"))
    return "\n".join(answers) + "\n"


SAMPLE = """2
6
1 2 3 4 5 6
4
2 3 4 5
"""
SAMPLE_OUT = """Case 1: No
Case 2: Yes
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n5\n") == "Case 1: No\n"
assert oracle("1\n2\n5 5\n") == "Case 1: Yes\n"
assert oracle("1\n3\n1 2 3\n") == "Case 1: No\n"
assert oracle("1\n4\n1 1 1 1\n") == "Case 1: Yes\n"
assert 1 << 20 == 1048576


def write(name, cases):
    lines = [str(len(cases))]
    for values in cases:
        lines.append(str(len(values)))
        lines.append(" ".join(str(value) for value in values))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[5], [5, 5], [5, 7], [1, 2, 3], [1, 1, 1, 1]])
    rng = random.Random(20261126)
    write("3_wide", [[rng.randint(1, 10000) for _ in range(40)]
                     for _ in range(10)])
    write("4_random", [[rng.randint(1, 1000) for _ in range(rng.randint(2, 40))]
                       for _ in range(50)])
    write("5_io", [[rng.randint(1, 10000) for _ in range(40)]
                   for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[1, 2, 3, 4, 5, 6], [2, 3, 4, 5]])
build()
