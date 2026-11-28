#!/usr/bin/env python3
import random
import sys
from functools import lru_cache
from pathlib import Path

sys.setrecursionlimit(1000000)
ROOT = Path(__file__).resolve().parent
SOLVERS = {}


def make_solver(move_limit):
    if move_limit in SOLVERS:
        return SOLVERS[move_limit]

    @lru_cache(maxsize=None)
    def play(box_left, steve_side, digit_side, steve_turn):
        if box_left == 0:
            return (0, 0)
        top = move_limit if move_limit < box_left else box_left
        if steve_turn:
            best = None
            for taken in range(1, top + 1):
                if taken < box_left:
                    steve, digit = play(box_left - taken, steve_side + taken,
                                        digit_side, False)
                else:
                    steve, digit = play(digit_side, 0, 0, False)
                    steve += steve_side + taken
                if best is None or steve > best[0]:
                    best = (steve, digit)
            return best
        best = None
        for taken in range(1, top + 1):
            if taken < box_left:
                steve, digit = play(box_left - taken, steve_side,
                                    digit_side + taken, True)
            else:
                steve, digit = play(steve_side, 0, 0, True)
                digit += digit_side + taken
            if best is None or digit > best[1]:
                best = (steve, digit)
        return best

    SOLVERS[move_limit] = play
    return play


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        donuts = int(tokens[cursor]); cursor += 1
        limit = int(tokens[cursor]); cursor += 1
        answers.append(str(make_solver(limit)(donuts, 0, 0, True)[0]))
    return "\n".join(answers) + "\n"


def write(name, pairs):
    input_text = str(len(pairs)) + "\n" + "".join(
        f"{donuts} {limit}\n" for donuts, limit in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_INPUT = "1\n5 2 \n"
SAMPLE_OUTPUT = "3\n"
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("3\n1 1\n2 1\n2 2\n") == "1\n1\n2\n"
assert oracle("1\n100 100\n") == "100\n"
assert oracle("1\n9 2\n") == "3\n"


def print_worked_example():
    play = make_solver(2)
    box, steve_side, digit_side, steve_turn = 5, 0, 0, True
    while box > 0:
        actor = "Steve" if steve_turn else "Digit"
        top = 2 if 2 < box else box
        choices = []
        for taken in range(1, top + 1):
            if taken < box:
                if steve_turn:
                    steve, digit = play(box - taken, steve_side + taken,
                                        digit_side, False)
                else:
                    steve, digit = play(box - taken, steve_side,
                                        digit_side + taken, True)
            else:
                if steve_turn:
                    steve, digit = play(digit_side, 0, 0, False)
                    steve += steve_side + taken
                else:
                    steve, digit = play(steve_side, 0, 0, True)
                    digit += digit_side + taken
            choices.append((taken, steve, digit))
        chosen = max(choices, key=lambda entry: entry[1] if steve_turn else entry[2])[0]
        if chosen == box:
            eaten = (steve_side if steve_turn else digit_side) + chosen
            print(f"box {box}, sides {steve_side}/{digit_side}, {actor} takes {chosen} and eats {eaten}")
            if steve_turn:
                box, steve_side, digit_side, steve_turn = digit_side, 0, 0, False
            else:
                box, steve_side, digit_side, steve_turn = steve_side, 0, 0, True
        else:
            print(f"box {box}, sides {steve_side}/{digit_side}, {actor} takes {chosen}")
            if steve_turn:
                steve_side += chosen
            else:
                digit_side += chosen
            box -= chosen
            steve_turn = not steve_turn
    print("Steve 3, Digit 2")


def build():
    edges = [
        (1, 1), (2, 1), (2, 2), (3, 1), (3, 2), (3, 3),
        (4, 2), (5, 2), (6, 2), (7, 2), (8, 2), (9, 2),
        (10, 1), (50, 50), (99, 1), (99, 98), (99, 99),
        (100, 1), (100, 50), (100, 98), (100, 99), (100, 100),
    ]
    write("2_edges", edges)

    wide = [(100, 100), (100, 99), (100, 1), (100, 50),
            (99, 99), (99, 98), (1, 1), (100, 100)] * 3
    write("3_wide", wide)

    grid = [(donuts, limit) for donuts in range(1, 46)
            for limit in range(1, donuts + 1)]
    random.seed(2026)
    random_pairs = []
    for _ in range(300):
        donuts = random.randint(1, 45)
        random_pairs.append((donuts, random.randint(1, donuts)))
    write("4_random", grid + random_pairs)

    random.seed(122)
    io_pairs = []
    for _ in range(80000):
        donuts = random.randint(1, 20)
        io_pairs.append((donuts, random.randint(1, donuts)))
    write("5_io", io_pairs)


def main():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
    (ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
    build()
    print_worked_example()


if __name__ == "__main__":
    main()
