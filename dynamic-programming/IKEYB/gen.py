#!/usr/bin/env python3
import os
import random
from itertools import combinations

import numpy as np

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT_DIR = os.path.join(BASE_DIR, "in")
OUTPUT_DIR = os.path.join(BASE_DIR, "out")
LARGE_VALUE = 10 ** 15
FIRST_ASCII = 33
LAST_ASCII = 126
SAMPLE_KEYS = list("23456789")
SAMPLE_LETTERS = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
SAMPLE_FREQUENCIES = [
    3371, 589, 1575, 1614, 6212, 971, 773, 1904, 2989, 123, 209,
    1588, 1513, 2996, 3269, 1080, 121, 2726, 3083, 4368, 1334, 518,
    752, 427, 733, 871,
]
EXPECTED_SAMPLE_GROUPS = [
    "ABCD", "EFG", "HIJK", "LM", "NOPQ", "RS", "TUV", "WXYZ",
]


def segment_cost_direct(freqs, left, right):
    total = 0
    for idx in range(left, right + 1):
        total += freqs[idx] * (idx - left + 1)
    return total


def brute_solve(keys, letters, freqs):
    letter_count = len(letters)
    key_count = len(keys)
    best_rank = None
    best_groups = None
    for cuts in combinations(range(1, letter_count), key_count - 1):
        bounds = (0,) + cuts + (letter_count,)
        groups = ["".join(letters[bounds[g]:bounds[g + 1]]) for g in range(key_count)]
        total_cost = 0
        for g in range(key_count):
            total_cost += segment_cost_direct(freqs, bounds[g], bounds[g + 1] - 1)
        rank = (total_cost, tuple(-len(groups[g]) for g in range(key_count - 1, -1, -1)))
        if best_rank is None or rank < best_rank:
            best_rank = rank
            best_groups = groups
    return best_groups


def build_cost_table(freqs):
    letter_count = len(freqs)
    table = np.full((letter_count + 1, letter_count + 1), LARGE_VALUE, dtype=np.int64)
    for left in range(letter_count):
        running = 0
        for right in range(left, letter_count):
            running += freqs[right] * (right - left + 1)
            table[left][right + 1] = running
    return table


def dp_core(keys, letters, freqs):
    letter_count = len(freqs)
    key_count = len(keys)
    cost_table = build_cost_table(freqs)
    dp_tables = [None] * (key_count + 1)
    previous = np.full(letter_count + 1, LARGE_VALUE, dtype=np.int64)
    previous[0] = 0
    dp_tables[0] = previous
    for key_index in range(1, key_count + 1):
        candidates = previous[:, None] + cost_table
        current = candidates.min(axis=0)
        for used in range(key_index):
            current[used] = LARGE_VALUE
        dp_tables[key_index] = current
        previous = current
    optimum = int(dp_tables[key_count][letter_count])
    groups = [""] * key_count
    remaining = letter_count
    budget = optimum
    for key_index in range(key_count, 0, -1):
        chosen_start = -1
        largest_size = remaining - (key_index - 1)
        for size in range(largest_size, 0, -1):
            start = remaining - size
            value = int(dp_tables[key_index - 1][start]) + int(cost_table[start][remaining])
            if value == budget:
                chosen_start = start
                break
        assert chosen_start >= 0
        groups[key_index - 1] = "".join(letters[chosen_start:remaining])
        budget = int(dp_tables[key_index - 1][chosen_start])
        remaining = chosen_start
    return groups


def oracle_solve(keys, letters, freqs):
    if len(letters) <= 12:
        return brute_solve(keys, letters, freqs)
    return dp_core(keys, letters, freqs)


def case_text(keys, letters, freqs):
    parts = ["%d %d" % (len(keys), len(letters)), "".join(keys), "".join(letters)]
    parts.extend(str(value) for value in freqs)
    return "\n".join(parts) + "\n"


def answer_text(keys, groups, case_number):
    lines = ["Keypad #%d:" % case_number]
    for idx in range(len(keys)):
        lines.append("%s: %s" % (keys[idx], groups[idx]))
    return "\n".join(lines) + "\n\n"


def distinct_chars(count, rng):
    pool = [chr(code) for code in range(FIRST_ASCII, LAST_ASCII + 1)]
    if rng is None:
        return pool[:count]
    return rng.sample(pool, count)


def build_cases():
    sample_cases = [(SAMPLE_KEYS, SAMPLE_LETTERS, SAMPLE_FREQUENCIES)]

    edge_cases = [
        (list("!"), list("!"), [100000]),
        (list("a"), list("XY"), [1, 100000]),
        (list("#$"), list("#$"), [100000, 1]),
        (list("~!@"), list("}|:\""), [1, 1, 1, 1]),
        (list("12345"), list("ABCDE"), [100000] * 5),
        (list("abcde"), list("EDCBA"), [100000, 1, 99999, 2, 50000]),
        (list("9876543210"), list("ZYXWVUTSRQ"), list(range(1, 11))),
        (list("()[]{}"), list("<>?/|\\"), [7, 3, 9, 1, 8, 2]),
        (list("!@#$%^"), list("QWERTYUIOP"), [3, 1, 4, 1, 5, 9, 2, 6, 5, 3]),
        (list("ABCDEFGHIJKL"), list("0123456789ab"), [1] * 12),
        (list("0123456789ab"), list("ABCDEFGHIJKL"), [100000] * 12),
        (list("!"), list("ABCDEFGHIJKL"), [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]),
        (list("abc"), list("!@#"), [100000, 1, 50000]),
        (list("+*"), list("-_="), [2, 3, 4]),
        (list(".,;"), list("abcde"), [5, 4, 3, 2, 1]),
        (list("xyz"), list("UVWXYZ"), [6, 6, 6, 6, 6, 6]),
        (list("789456"), list("!@#$%^&*()"), [100000, 1] * 5),
        (list("mnopqrstuv"), list("0123456789"), [1, 100000] * 5),
    ]
    edge_rng = random.Random(7001)
    for _ in range(8):
        count = edge_rng.randint(1, 12)
        keys = distinct_chars(count, edge_rng)
        letters = distinct_chars(edge_rng.randint(count, 12), edge_rng)
        freqs = [edge_rng.randint(1, 100000) for unused in letters]
        edge_cases.append((keys, letters, freqs))

    wide_cases = []
    wide_rng = random.Random(5150)
    for pattern in range(6):
        keys = distinct_chars(90, wide_rng)
        letters = distinct_chars(90, wide_rng)
        if pattern == 0:
            freqs = [100000] * 90
        elif pattern == 1:
            freqs = [1] * 90
        elif pattern == 2:
            freqs = [100000 if idx % 2 == 0 else 1 for idx in range(90)]
        elif pattern == 3:
            freqs = list(range(100000, 99910, -1))
        elif pattern == 4:
            freqs = [1 + (idx * 1097) % 100000 for idx in range(90)]
        else:
            freqs = [wide_rng.randint(1, 100000) for unused in range(90)]
        wide_cases.append((keys, letters, freqs))

    random_rng = random.Random(20261123)
    random_cases = []
    for unused in range(250):
        key_count = random_rng.randint(1, 90)
        letter_count = random_rng.randint(key_count, 90)
        keys = distinct_chars(key_count, random_rng)
        letters = distinct_chars(letter_count, random_rng)
        freqs = [random_rng.randint(1, 100000) for position in range(letter_count)]
        random_cases.append((keys, letters, freqs))

    io_rng = random.Random(909090)
    io_cases = []
    for unused in range(2000):
        keys = distinct_chars(90, io_rng)
        letters = distinct_chars(90, io_rng)
        freqs = [io_rng.randint(1, 100000) for position in range(90)]
        io_cases.append((keys, letters, freqs))

    return [
        ("1_sample", sample_cases),
        ("2_edges", edge_cases),
        ("3_wide", wide_cases),
        ("4_random", random_cases),
        ("5_io", io_cases),
    ]


def verify_oracle(groups):
    sample_groups = oracle_solve(SAMPLE_KEYS, SAMPLE_LETTERS, SAMPLE_FREQUENCIES)
    assert sample_groups == EXPECTED_SAMPLE_GROUPS
    sample_cost = 0
    frequency_index = 0
    for group in sample_groups:
        for offset, unused in enumerate(group):
            sample_cost += SAMPLE_FREQUENCIES[frequency_index + offset] * (offset + 1)
        frequency_index += len(group)
    assert sample_cost == 77933
    check_rng = random.Random(424242)
    for unused in range(150):
        key_count = check_rng.randint(1, 11)
        letter_count = check_rng.randint(key_count, 11)
        keys = distinct_chars(key_count, check_rng)
        letters = distinct_chars(letter_count, check_rng)
        freqs = [check_rng.randint(1, 100000) for position in range(letter_count)]
        assert brute_solve(keys, letters, freqs) == dp_core(keys, letters, freqs)
    assert len(groups) == 5


def validate_case(keys, letters, freqs):
    assert 1 <= len(keys) <= len(letters) <= 90
    assert len(set(keys)) == len(keys)
    assert len(set(letters)) == len(letters)
    assert len(freqs) == len(letters)
    assert all(1 <= value <= 100000 for value in freqs)
    assert all(FIRST_ASCII <= ord(char) <= LAST_ASCII for char in keys + letters)


def write_group(name, cases):
    input_parts = []
    output_parts = []
    for case_index, (keys, letters, freqs) in enumerate(cases, start=1):
        validate_case(keys, letters, freqs)
        input_parts.append(case_text(keys, letters, freqs))
        output_parts.append(answer_text(keys, oracle_solve(keys, letters, freqs), case_index))
    with open(os.path.join(INPUT_DIR, name + ".txt"), "w") as handle:
        handle.write(str(len(cases)) + "\n" + "".join(input_parts))
    with open(os.path.join(OUTPUT_DIR, name + ".out"), "w") as handle:
        handle.write("".join(output_parts))


def main():
    os.makedirs(INPUT_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    groups = build_cases()
    verify_oracle(groups)
    for name, cases in groups:
        write_group(name, cases)


if __name__ == "__main__":
    main()
