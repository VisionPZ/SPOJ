#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_total = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_total):
        people_total = int(tokens[cursor])
        boy_target = int(tokens[cursor + 1])
        cursor += 2
        lineup = tokens[cursor]
        cursor += 1
        assert len(lineup) == people_total
        ones = [index for index, char in enumerate(lineup) if char == '1']
        if boy_target == 0:
            gaps = []
            previous = -1
            for position in ones + [people_total]:
                gaps.append(position - previous - 1)
                previous = position
            answer = sum(gap * (gap + 1) // 2 for gap in gaps)
        elif boy_target > len(ones):
            answer = 0
        else:
            answer = 0
            for start in range(len(ones) - boy_target + 1):
                left_choices = ones[start] - (ones[start - 1] if start > 0 else -1)
                right_choices = (ones[start + boy_target] if start + boy_target < len(ones)
                                 else people_total) - ones[start + boy_target - 1]
                answer += left_choices * right_choices
        answers.append(str(answer))
    return "\n".join(answers) + "\n"


SAMPLE = """3
4 1
0101
5 2
01010
5 4
01010
"""
SAMPLE_OUT = """6
4
0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n4 0\n0101\n") == "2\n"
assert oracle("1\n5 1\n01010\n") == "8\n"
assert oracle("1\n5 0\n00000\n") == "15\n"


def render(cases):
    parts = [str(len(cases))]
    for people_total, boy_target, lineup in cases:
        parts.append(f"{people_total} {boy_target}")
        parts.append(lineup)
    return "\n".join(parts) + "\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 0, "0"), (1, 1, "1"), (4, 0, "0101"),
                      (5, 2, "01010"), (5, 4, "01010")])
    rng = random.Random(20261127)
    write("3_wide", [(1000, 100, "".join(rng.choice("01") for _ in range(1000)))])
    random_cases = []
    for _ in range(10):
        case_length = rng.randint(1, 400)
        random_cases.append((case_length, rng.randint(0, 60),
                             "".join(rng.choice("01") for _ in range(case_length))))
    write("4_random", random_cases)
    write("5_io", [(400, 0, "0" * 400), (400, 1, "1" * 400),
                   (400, 200, "01" * 200), (400, 400, "1" * 400),
                   (400, 3, "".join(rng.choice("01") for _ in range(400)))])
    big = random.Random(9283746)
    huge = "".join(big.choice("01") for _ in range(1000000))
    Path("/tmp/CRAN04_big.txt").write_text(render([(1000000, 1000, huge)]))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(4, 1, "0101"), (5, 2, "01010"), (5, 4, "01010")])
build()
