#!/usr/bin/env python3
import random
from array import array
from pathlib import Path

ROOT = Path(__file__).resolve().parent

ONES = [
    "zero", "one", "two", "three", "four", "five", "six", "seven", "eight",
    "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
    "sixteen", "seventeen", "eighteen", "nineteen",
]
TENS = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
WORD_TO_VALUE = {word: value for value, word in enumerate(ONES)}
for tens_value in range(2, 10):
    WORD_TO_VALUE[TENS[tens_value]] = tens_value * 10
WORD_TO_VALUE["hundred"] = 100
WORD_TO_VALUE["thousand"] = 1000
WORD_TO_VALUE["million"] = 1000000

NODE_OF_STATE = [0, 2, 4, 6, 7, 8, 9, 9]
STATE_OF_NODE = {0: 0, 2: 1, 4: 2, 6: 3, 7: 4, 8: 5}
SQUARE_TARGET = {0: 2, 1: 6, 2: 8, 4: 0}


def to_words(value):
    def below_hundred(part):
        if part < 20:
            return ONES[part]
        tens_part, ones_part = divmod(part, 10)
        if ones_part == 0:
            return TENS[tens_part]
        return TENS[tens_part] + "-" + ONES[ones_part]

    def below_thousand(part):
        hundreds_part, rest_part = divmod(part, 100)
        pieces = []
        if hundreds_part:
            pieces.append(ONES[hundreds_part] + "-hundred")
        if rest_part:
            if hundreds_part:
                pieces.append("and")
            pieces.append(below_hundred(rest_part))
        return "-".join(pieces)

    pieces = []
    millions_part, remainder = divmod(value, 1000000)
    if millions_part:
        pieces.append(below_thousand(millions_part) + "-million")
    thousands_part, rest_part = divmod(remainder, 1000)
    if thousands_part:
        pieces.append(below_thousand(thousands_part) + "-thousand")
    if rest_part:
        pieces.append(below_thousand(rest_part))
    return "-".join(pieces)


def parse_values(text):
    values = []
    for line in text.splitlines():
        if not line.strip():
            continue
        smaller_part = 0
        total_value = 0
        for word in line.replace("-", " ").split():
            if word == "and":
                continue
            word_value = WORD_TO_VALUE[word]
            if word_value == 100:
                smaller_part *= 100
            elif word_value == 1000:
                total_value += smaller_part * 1000
                smaller_part = 0
            elif word_value == 1000000:
                total_value += smaller_part * 1000000
                smaller_part = 0
            else:
                smaller_part += word_value
        values.append(total_value + smaller_part)
    return values


def next_node(state, value):
    node = NODE_OF_STATE[state]
    if node == 0:
        return 7 if (value // 100) % 10 <= 7 else 9
    if node == 2:
        return [7, 1, 4][value % 3]
    if node == 4:
        reversed_value = int(str(value)[::-1])
        return 6 if reversed_value > value else 2
    if node == 6:
        return 4 if len(str(value)) % 2 == 0 else 7
    if node == 7:
        return SQUARE_TARGET[(value * value) % 7]
    if node == 8:
        return 7 if value % 5 in (2, 3) else 9
    return 0 if state == 6 else 8


def build_answers(max_value):
    answers = [array("i", [-1]) * (max_value + 1) for _ in range(8)]
    for value in range(1, max_value + 1):
        for state in range(8):
            chosen_node = next_node(state, value)
            if value == 1:
                result = -1
            elif chosen_node == 1:
                result = value - 1
            else:
                if chosen_node == 9:
                    following_state = 6 if NODE_OF_STATE[state] == 8 else 7
                else:
                    following_state = STATE_OF_NODE[chosen_node]
                result = answers[following_state][value - 1]
            answers[state][value] = result
    return answers[0]


SAMPLE_VALUES = [13, 14, 1000, 1325979]
SAMPLE = """thirteen
fourteen
one-thousand
one-million-three-hundred-and-twenty-five-thousand-nine-hundred-and-seventy-nine
"""
SAMPLE_OUT = """-1
9
789
1325784
"""
assert [to_words(value) for value in SAMPLE_VALUES] == SAMPLE.strip().splitlines()
assert parse_values(SAMPLE) == SAMPLE_VALUES

ALL_VALUES = list(SAMPLE_VALUES)
ALL_VALUES += [1, 2, 3, 4, 5, 9, 10, 99, 100, 101, 999, 1001]
ALL_VALUES += [1325979, 1000000, 999999, 500000, 250000]
rng = random.Random(20261126)
ALL_VALUES += [rng.randint(1, 200000) for _ in range(200)]
ALL_VALUES += [rng.randint(1, 100000) for _ in range(20000)]
START_ANSWERS = build_answers(max(ALL_VALUES))


def oracle(text):
    values = parse_values(text)
    return "\n".join(str(START_ANSWERS[value]) for value in values) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(to_words(1) + "\n") == "-1\n"
assert oracle(to_words(14) + "\n") == "9\n"
assert oracle(to_words(1000) + "\n") == "789\n"


def write(name, values):
    text = "\n".join(to_words(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 9, 10, 99, 100, 101, 999, 1001])
    write("3_wide", [1325979, 1000000, 999999, 500000, 250000])
    write("4_random", [value for value in ALL_VALUES[17:217]])
    write("5_io", [value for value in ALL_VALUES[217:]])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_VALUES)
build()
