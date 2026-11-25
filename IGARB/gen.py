#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

ALLOWED = (0, 1, 2, 5, 6, 8, 9)
FIRST = (1, 2, 5, 6, 8, 9)
FLIP = {0: "0", 1: "1", 2: "2", 5: "5", 6: "9", 8: "8", 9: "6"}


def oracle_answer(rank):
    length = 1
    while 7 ** length - 1 < rank:
        length += 1
    index = rank - (7 ** (length - 1) - 1) - 1
    upright = []
    for position in range(length):
        choices = FIRST if position == 0 else ALLOWED
        place = 7 ** (length - 1 - position)
        choice = index // place
        index -= choice * place
        upright.append(choices[choice])
    return "".join(FLIP[digit] for digit in reversed(upright))


def brute_answers(count):
    answers = []
    number = 1
    while len(answers) < count:
        text = str(number)
        if all(char in "0125689" for char in text):
            answers.append("".join(FLIP[int(char)] for char in reversed(text)))
        number += 1
    return answers


assert oracle_answer(1) == "1"
assert [oracle_answer(rank) for rank in (2, 3, 4, 5, 6)] == ["2", "5", "9", "8", "6"]
assert oracle_answer(8) == "11" and oracle_answer(98) == "002"
assert 7 ** 2 - 1 == 48 and oracle_answer(48) == "66"
assert 7 ** 3 - 1 == 342 and oracle_answer(342) == "666"
assert [oracle_answer(rank) for rank in range(1, 2001)] == brute_answers(2000)


def write_pair(name, values):
    input_text = str(len(values)) + "\n" + "".join(str(value) + "\n" for value in values)
    output_text = "".join(oracle_answer(value) + "\n" for value in values)
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(output_text)


def random_rank(rng, digits):
    return int("".join(str(rng.randint(1, 9)) if index == 0 else str(rng.randint(0, 9))
                       for index in range(digits)))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

write_pair("1_sample", [1, 2, 3, 4, 5, 6, 8, 98])
write_pair("2_edges", [1, 6, 7, 8, 48, 49, 342, 343, 7 ** 236,
                       10 ** 200 - 1, 10 ** 200])
write_pair("3_wide", [10 ** 200, 10 ** 200 - 1, 9 * 10 ** 199,
                      7 ** 236, 10 ** 199, 8 * 10 ** 199 + 12345])

rng = random.Random(20261125)
write_pair("4_random", [random_rank(rng, rng.randint(1, 200)) for _ in range(2200)])
write_pair("5_io", [random_rank(rng, 200) for _ in range(2200)])

print("generated 5 test pairs")
