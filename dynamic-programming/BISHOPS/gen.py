#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_force(board_size):
    squares = [(row, col) for row in range(board_size) for col in range(board_size)]
    best = 0

    def search(square_index, placed, down_used, up_used):
        nonlocal best
        if placed + len(squares) - square_index <= best:
            return
        if square_index == len(squares):
            best = placed
            return
        row, col = squares[square_index]
        down = row - col
        up = row + col
        if down not in down_used and up not in up_used:
            down_used.add(down)
            up_used.add(up)
            search(square_index + 1, placed + 1, down_used, up_used)
            down_used.remove(down)
            up_used.remove(up)
        search(square_index + 1, placed, down_used, up_used)

    search(0, 0, set(), set())
    return best


def oracle(board_text):
    value = int(board_text)
    if value == 0:
        return 0
    if value == 1:
        return 1
    return 2 * value - 2


assert [brute_force(size) for size in range(1, 6)] == [1, 2, 4, 6, 8]
assert [oracle(str(size)) for size in range(1, 6)] == [1, 2, 4, 6, 8]
assert oracle("2") == 2 and oracle("3") == 4
assert oracle("1" + "0" * 100) == 2 * 10 ** 100 - 2
assert len(str(oracle("9" * 100))) == 101


def write_cases(name, boards):
    input_text = "".join(f"{board}\n" for board in boards)
    output_text = "".join(f"{oracle(board)}\n" for board in boards)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


SAMPLE = ["2", "3"]
assert "".join(f"{oracle(board)}\n" for board in SAMPLE) == "2\n4\n"

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_cases("1_sample", SAMPLE)
write_cases("2_edges", [
    "1", "2", "3", "4", "5", "6", "10", "11", "100", "101",
    "1" + "0" * 99, "9" * 100, "1" + "0" * 100,
])
write_cases("3_wide", [
    "1" + "0" * 100, "9" * 100, "1234567890" * 10,
    "8" + "0" * 99, "5" * 100, "1" + "0" * 99,
    "9" * 99, "7" + "0" * 99,
])

rng = random.Random(20261125)


def random_board():
    length = rng.randint(1, 100)
    return str(rng.randint(1, 9)) + "".join(str(rng.randint(0, 9)) for _ in range(length - 1))


write_cases("4_random", [random_board() for _ in range(200)])


def wide_board():
    return str(rng.randint(1, 9)) + "".join(str(rng.randint(0, 9)) for _ in range(99))


write_cases("5_io", [wide_board() for _ in range(15000)])
