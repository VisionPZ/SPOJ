#!/usr/bin/env python3
import bisect
import random
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def segments(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    dimension = tokens[1]
    result = []
    position = 2
    for _ in range(count):
        result.append(tuple(tokens[position:position + 4]))
        position += 4
    return count, dimension, result


def oracle(text):
    count, dimension, words = segments(text)
    answers = []
    for index, (first_row, first_col, last_row, last_col) in enumerate(words):
        overlaps = 0
        for other_index, (other_row_start, other_col_start, other_row_end, other_col_end) in enumerate(words):
            if index == other_index:
                continue
            if first_row == last_row and other_row_start == other_row_end and first_row == other_row_start:
                if max(first_col, other_col_start) <= min(last_col, other_col_end):
                    overlaps += 1
            elif first_col == last_col and other_col_start == other_col_end and first_col == other_col_start:
                if max(first_row, other_row_start) <= min(last_row, other_row_end):
                    overlaps += 1
            elif first_row == last_row and other_col_start == other_col_end:
                if other_row_start <= first_row <= other_row_end and first_col <= other_col_start <= last_col:
                    overlaps += 1
            elif first_col == last_col and other_row_start == other_row_end:
                if first_row <= other_row_start <= last_row and other_col_start <= first_col <= other_col_end:
                    overlaps += 1
        answers.append(str(overlaps))
    return "\n".join(answers) + "\n"


def oracle_fast(text):
    count, dimension, words = segments(text)
    answers = [0] * count
    horizontals = defaultdict(list)
    verticals = defaultdict(list)
    for index, (first_row, first_col, last_row, last_col) in enumerate(words):
        if first_row == last_row:
            horizontals[first_row].append((first_col, last_col, index))
        else:
            verticals[first_col].append((first_row, last_row, index))
    for row_words in horizontals.values():
        starts = sorted(word[0] for word in row_words)
        ends = sorted(word[1] for word in row_words)
        for word_start, word_end, index in row_words:
            answers[index] += bisect.bisect_right(starts, word_end) - bisect.bisect_left(ends, word_start) - 1
    for column_words in verticals.values():
        starts = sorted(word[0] for word in column_words)
        ends = sorted(word[1] for word in column_words)
        for word_start, word_end, index in column_words:
            answers[index] += bisect.bisect_right(starts, word_end) - bisect.bisect_left(ends, word_start) - 1
    vertical_index = {}
    for column, column_words in verticals.items():
        vertical_index[column] = (sorted(word[0] for word in column_words),
                                  sorted(word[1] for word in column_words))
    horizontal_index = {}
    for row, row_words in horizontals.items():
        horizontal_index[row] = (sorted(word[0] for word in row_words),
                                 sorted(word[1] for word in row_words))
    for index, (first_row, first_col, last_row, last_col) in enumerate(words):
        if first_row == last_row:
            total = 0
            for column in range(first_col, last_col + 1):
                if column in vertical_index:
                    starts, ends = vertical_index[column]
                    total += bisect.bisect_right(starts, first_row) - bisect.bisect_left(ends, first_row)
            answers[index] += total
        else:
            total = 0
            for row in range(first_row, last_row + 1):
                if row in horizontal_index:
                    starts, ends = horizontal_index[row]
                    total += bisect.bisect_right(starts, first_col) - bisect.bisect_left(ends, first_col)
            answers[index] += total
    return "\n".join(str(value) for value in answers) + "\n"


SAMPLE = """5
4
2 1 2 4
2 1 2 4
4 1 4 3
1 3 3 3
2 3 4 3
"""
SAMPLE_OUT = """3
3
1
3
4
"""
SECOND = """5
10
2 4 9 4
2 7 9 7
6 7 8 7
4 2 4 9
7 2 7 9
"""
SECOND_OUT = """2
3
2
2
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_fast(SAMPLE) == SAMPLE_OUT
assert oracle(SECOND) == SECOND_OUT
assert oracle_fast(SECOND) == SECOND_OUT
assert oracle("1\n2\n1 1 1 2\n") == "0\n"
assert oracle("2\n2\n1 1 1 2\n1 1 1 2\n") == "1\n1\n"
assert oracle_fast("2\n2\n1 1 1 2\n1 1 1 2\n") == "1\n1\n"

check = """8
6
1 1 1 6
1 3 1 5
2 2 5 2
3 3 3 6
6 2 6 6
2 5 6 5
4 1 4 4
1 2 6 2
"""
assert oracle(check) == oracle_fast(check)


def write(name, words, dimension, use_fast=False):
    lines = [str(len(words)), str(dimension)]
    for first_row, first_col, last_row, last_col in words:
        lines.append(f"{first_row} {first_col} {last_row} {last_col}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle_fast(text) if use_fast else oracle(text))


def random_words(rng, count, dimension):
    words = []
    for _ in range(count):
        row = rng.randrange(1, dimension + 1)
        column = rng.randrange(1, dimension)
        if rng.randrange(2):
            words.append((row, column, row, rng.randrange(column + 1, dimension + 1)))
        else:
            words.append((column, row, rng.randrange(column + 1, dimension + 1), row))
    return words


def build():
    write("2_edges", [(1, 1, 1, 2), (1, 1, 1, 2), (2, 1, 5, 1), (1, 2, 1, 4)], 5)
    rng = random.Random(20261126)
    write("3_wide", random_words(rng, 40, 100000), 100000)
    write("4_random", random_words(rng, 60, 14), 14)
    write("5_io", random_words(rng, 4000, 60), 60, use_fast=True)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
