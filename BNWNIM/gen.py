#!/usr/bin/env python3
import itertools
import random
from collections import defaultdict
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def grundy_sequence(sequence):
    memo = {}

    def recurse(remaining):
        if not remaining:
            return 0
        if remaining in memo:
            return memo[remaining]
        moves = set()
        leading_whites = 0
        while leading_whites < len(remaining) and remaining[leading_whites] == 'W':
            leading_whites += 1
        for removed in range(1, leading_whites + 1):
            moves.add(recurse(remaining[removed:]))
        if leading_whites < len(remaining):
            moves.add(recurse(remaining[leading_whites + 1:]))
        candidate = 0
        while candidate in moves:
            candidate += 1
        memo[remaining] = candidate
        return candidate

    return recurse(sequence)


def row_distribution(black_count, white_count):
    tally = defaultdict(int)
    for black_positions in itertools.combinations(range(black_count + white_count), black_count):
        black_set = set(black_positions)
        sequence = ''.join('B' if index in black_set else 'W'
                           for index in range(black_count + white_count))
        tally[grundy_sequence(sequence)] += 1
    total = sum(tally.values())
    return {grundy: Fraction(count, total) for grundy, count in tally.items()}


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        row_count = tokens[cursor]
        cursor += 1
        black_counts = tokens[cursor:cursor + row_count]
        cursor += row_count
        white_counts = tokens[cursor:cursor + row_count]
        cursor += row_count
        combined = {0: Fraction(1)}
        for black_count, white_count in zip(black_counts, white_counts):
            single_row = row_distribution(black_count, white_count)
            next_combined = defaultdict(Fraction)
            for state, state_probability in combined.items():
                for grundy, grundy_probability in single_row.items():
                    next_combined[state ^ grundy] += state_probability * grundy_probability
            combined = next_combined
        win = 1 - combined.get(0, Fraction(0))
        scaled = (win.numerator * 1000000 * 2 + win.denominator) // (2 * win.denominator)
        answers.append(f"{scaled // 1000000}.{scaled % 1000000:06d}")
    return "\n".join(answers) + "\n"


SAMPLE = """4
1
0
2
1
2
0
1
2
2
2
2 5
2 0
"""
SAMPLE_OUT = """1.000000
0.000000
0.666667
0.666667
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n0\n2\n") == "1.000000\n"
assert oracle("1\n1\n2\n0\n") == "0.000000\n"
assert oracle("1\n2\n0 0\n2 2\n") == "0.000000\n"
assert row_distribution(1, 2) == {0: Fraction(1, 3), 2: Fraction(1, 3), 3: Fraction(1, 3)}


def render(cases):
    lines = [str(len(cases))]
    for black_counts, white_counts in cases:
        lines.append(str(len(black_counts)))
        lines.append(" ".join(str(value) for value in black_counts))
        lines.append(" ".join(str(value) for value in white_counts))
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edge_cases = [
        ([0], [2]),
        ([2], [0]),
        ([1], [2]),
        ([0, 0], [2, 2]),
        ([1, 1], [1, 1]),
        ([7], [0]),
    ]
    write("2_edges", edge_cases)
    rng = random.Random(20261126)
    wide_blacks = [rng.randint(0, 7) for _ in range(50)]
    wide_whites = [rng.randint(0, 7) for _ in range(50)]
    write("3_wide", [(wide_blacks, wide_whites)])
    random_cases = []
    for _ in range(6):
        row_count = rng.randint(1, 8)
        blacks = [rng.randint(0, 7) for _ in range(row_count)]
        whites = [rng.randint(0, 7) for _ in range(row_count)]
        random_cases.append((blacks, whites))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(120):
        row_count = rng.randint(1, 5)
        blacks = [rng.randint(0, 5) for _ in range(row_count)]
        whites = [rng.randint(0, 5) for _ in range(row_count)]
        io_cases.append((blacks, whites))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
