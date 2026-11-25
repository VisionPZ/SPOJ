#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LINES = ((0, 1, 2), (3, 4, 5), (6, 7, 8),
         (0, 3, 6), (1, 4, 7), (2, 5, 8),
         (0, 4, 8), (2, 4, 6))
LINE_MASKS = [sum(1 << cell for cell in line) for line in LINES]
MEMO = {}


def destroyed(mask):
    return any((mask & line_mask) == line_mask for line_mask in LINE_MASKS)


def winning(state):
    active = tuple(sorted(mask for mask in state if not destroyed(mask)))
    if not active:
        return False
    if active in MEMO:
        return MEMO[active]
    result = False
    for index, mask in enumerate(active):
        for cell in range(9):
            if not (mask >> cell) & 1:
                successor = list(active)
                successor[index] = mask | (1 << cell)
                if not winning(successor):
                    result = True
                    break
        if result:
            break
    MEMO[active] = result
    return result


def oracle(text):
    tokens = text.split()
    cursor = 0
    game_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(game_count):
        board_count = int(tokens[cursor]); cursor += 1
        boards = []
        for _ in range(board_count):
            boards.append(int(tokens[cursor], 2))
            cursor += 1
        answers.append("Kang" if winning(boards) else "Kung")
    return "\n".join(answers) + "\n"


SAMPLE = """3
1
000000000
2
000000000
000000000
2
100010000
101000000
"""
SAMPLE_OUT = """Kang
Kung
Kung
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n000000000\n") == "Kang\n"
assert oracle("1\n2\n000000000\n000000000\n") == "Kung\n"
assert oracle("1\n2\n100010000\n101000000\n") == "Kung\n"
assert oracle("1\n1\n111111111\n") == "Kung\n"
assert LINE_MASKS[0] == 7 and LINE_MASKS[7] == 84


def game_text(boards):
    return str(len(boards)) + "\n" + "\n".join(boards) + "\n"


def write(name, games):
    text = str(len(games)) + "\n" + "".join(game_text(boards) for boards in games)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ["000000000"], ["111111111"], ["111000111"], ["000000001"],
    ])
    rng = random.Random(20261126)
    write("3_wide", [
        [format(rng.randrange(512), "09b"), format(rng.randrange(512), "09b")]
        for _ in range(1000)
    ])
    write("4_random", [
        [format(rng.randrange(512), "09b"), format(rng.randrange(512), "09b")]
        for _ in range(200)
    ])
    write("5_io", [
        [format(rng.randrange(512), "09b"), format(rng.randrange(512), "09b")]
        for _ in range(1000)
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [["000000000"], ["000000000", "000000000"],
                   ["100010000", "101000000"]])
build()
