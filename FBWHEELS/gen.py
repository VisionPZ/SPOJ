#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def minimum_costs(word_length, deals, combine_cost):
    best = [None] * word_length
    deal_count = len(deals)

    def search(index, used, total_length, total_cost):
        if index == deal_count:
            if total_length > 0:
                actual = total_cost + combine_cost * (used - 1)
                if best[total_length] is None or actual < best[total_length]:
                    best[total_length] = actual
            return
        cost, length = deals[index]
        for count in range((word_length - 1 - total_length) // length + 1):
            search(index + 1, used + count, total_length + count * length,
                   total_cost + count * cost)

    search(0, 0, 0, 0)
    return best


def oracle(text):
    tokens = text.split()
    position = 0
    case_count = int(tokens[position])
    position += 1
    answers = []
    for _ in range(case_count):
        deal_count = int(tokens[position])
        answer_count = int(tokens[position + 1])
        combine_cost = int(tokens[position + 2])
        target = int(tokens[position + 3])
        scale = int(tokens[position + 4])
        bonus = int(tokens[position + 5])
        position += 6
        secret = tokens[position]
        position += 1
        deals = []
        for _ in range(deal_count):
            deals.append((int(tokens[position]), int(tokens[position + 1])))
            position += 2
        word_length = len(secret)
        costs = minimum_costs(word_length, deals, combine_cost)
        finite = [cost for cost in costs[1:] if cost is not None]
        filler = -min(finite) if finite else 0
        values = []
        for length in range(1, word_length):
            cost = costs[length]
            if cost is None:
                continue
            starts = word_length - length + 1
            visited = set()
            reward = scale * (word_length - abs(target - length)) ** 2 + bonus
            for start in range(starts):
                sequence = secret[start:start + length]
                if sequence in visited:
                    continue
                visited.add(sequence)
                occurrence = sum(1 for other in range(starts)
                                 if secret[other:other + length] == sequence)
                if occurrence >= 2:
                    factor = occurrence * (occurrence - 1) / (starts * (starts - 1))
                    values.append(reward * factor - cost)
        values.extend([filler] * answer_count)
        values.sort(reverse=True)
        answers.append(" ".join(f"{value:.5f}" for value in values[:answer_count]) + "\n")
    return "".join(answers)


SAMPLE = """2
1 3 0 1 5 6
ZZ
2 1
3 4 1 4 3 2
FOXENINBOXEN
5 2
1000 11
2 2
"""
SAMPLE_OUT = """24.00000 -2.00000 -2.00000
7.05556 3.49091 3.49091 3.49091
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 2 0 1 1 0\nZZ\n1 1\n") == "3.00000 -1.00000\n"
assert oracle("1\n1 2 0 1 1 0\nAB\n1 1\n") == "-1.00000 -1.00000\n"
assert oracle("1\n1 3 0 1 0 5\nAAA\n1 1\n") == "4.00000 3.00000 -1.00000\n"
assert oracle("1\n2 2 3 2 4 7\nAAAA\n2 1\n3 2\n") != ""


def write(name, cases):
    lines = [str(len(cases))]
    for header, secret, deals in cases:
        lines.append(" ".join(str(value) for value in header))
        lines.append(secret)
        for cost, length in deals:
            lines.append(f"{cost} {length}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        ((1, 2, 0, 1, 0, 0), "AB", [(1, 1)]),
        ((1, 2, 0, 1, 1, 0), "AA", [(1, 1)]),
        ((2, 2, 100, 1, 1, 0), "AAAA", [(2, 1), (5, 3)]),
        ((2, 3, 0, 2, 3, 1), "ABCABC", [(2, 2), (4, 3)]),
    ])
    write("3_wide", [((3, 5, 1, 2, 1000000, 7), "ABABABAB", [(3, 1), (5, 2), (9, 4)])])
    random_cases = []
    for _ in range(4):
        word_length = rng.randint(2, 9)
        secret = "".join(rng.choice("ABCD") for _ in range(word_length))
        deals = [(rng.randint(1, 20), rng.randint(1, max(1, word_length - 1)))
                 for _ in range(rng.randint(1, 3))]
        header = (len(deals), rng.randint(1, 5), rng.randint(0, 5),
                  rng.randint(1, word_length - 1), rng.randint(0, 100),
                  rng.randint(0, 20))
        random_cases.append((header, secret, deals))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(6):
        word_length = rng.randint(3, 8)
        secret = "".join(rng.choice("AB") for _ in range(word_length))
        deals = [(rng.randint(1, 8), rng.randint(1, max(1, word_length - 1)))]
        header = (1, 8, 0, rng.randint(1, word_length - 1), rng.randint(1, 50), 3)
        io_cases.append((header, secret, deals))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    ((1, 3, 0, 1, 5, 6), "ZZ", [(2, 1)]),
    ((3, 4, 1, 4, 3, 2), "FOXENINBOXEN", [(5, 2), (1000, 11), (2, 2)]),
])
build()
