#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.strip().split('\n')
    row_count, column_count, chat_time, burr_time = map(int, lines[0].split())
    grid = [line.strip() for line in lines[1:1 + row_count]]
    cells = row_count * column_count
    fox_start = wolf_start = fox_home = wolf_home = -1
    for cell in range(cells):
        mark = grid[cell // column_count][cell % column_count]
        if mark == 'f':
            fox_start = cell
        elif mark == 'w':
            wolf_start = cell
        elif mark == 'F':
            fox_home = cell
        elif mark == 'W':
            wolf_home = cell
    if -1 in (fox_start, wolf_start, fox_home, wolf_home):
        return '-1\n'

    def moves(cell, kind):
        result = [cell]
        row, col = divmod(cell, column_count)
        for delta_row, delta_col in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            next_row, next_col = row + delta_row, col + delta_col
            if not (0 <= next_row < row_count and 0 <= next_col < column_count):
                continue
            nxt = next_row * column_count + next_col
            mark = grid[next_row][next_col]
            if mark == 'T':
                continue
            if kind == 0 and mark == 'W':
                continue
            if kind == 1 and mark == 'F':
                continue
            result.append(nxt)
        return result

    fox_moves = [moves(cell, 0) for cell in range(cells)]
    wolf_moves = [moves(cell, 1) for cell in range(cells)]

    def penalty(cell, nxt):
        return burr_time if grid[cell // column_count][cell % column_count] == 'B' and grid[nxt // column_count][nxt % column_count] == '.' else 0

    def successors(state):
        chatted = state[4]
        fox_cell, wolf_cell, fox_busy, wolf_busy = state[:4]
        result = []
        if fox_busy and wolf_busy:
            result.append((fox_cell, wolf_cell, fox_busy - 1, wolf_busy - 1, chatted))
        elif fox_busy:
            for nxt in wolf_moves[wolf_cell]:
                cost = penalty(wolf_cell, nxt)
                meet = nxt == fox_cell
                if meet and not chatted:
                    result.append((fox_cell, nxt, max(fox_busy - 1, chat_time), max(cost, chat_time), 1))
                else:
                    result.append((fox_cell, nxt, fox_busy - 1, cost, chatted))
        elif wolf_busy:
            for nxt in fox_moves[fox_cell]:
                cost = penalty(fox_cell, nxt)
                meet = nxt == wolf_cell
                if meet and not chatted:
                    result.append((nxt, wolf_cell, max(cost, chat_time), max(wolf_busy - 1, chat_time), 1))
                else:
                    result.append((nxt, wolf_cell, cost, wolf_busy - 1, chatted))
        else:
            for fox_next in fox_moves[fox_cell]:
                fox_cost = penalty(fox_cell, fox_next)
                for wolf_next in wolf_moves[wolf_cell]:
                    wolf_cost = penalty(wolf_cell, wolf_next)
                    meet = fox_next == wolf_next or (fox_next == wolf_cell and wolf_next == fox_cell)
                    if meet and not chatted:
                        delay = max(fox_cost, wolf_cost, chat_time)
                        result.append((fox_next, wolf_next, delay, delay, 1))
                    else:
                        result.append((fox_next, wolf_next, fox_cost, wolf_cost, chatted))
        return result

    start = (fox_start, wolf_start, 0, 0, 0)
    memo = {}

    def possible(state, remaining):
        if state[0] == fox_home and state[1] == wolf_home:
            return True
        if remaining == 0:
            return False
        key = (state, remaining)
        if key in memo:
            return memo[key]
        for nxt in successors(state):
            if possible(nxt, remaining - 1):
                memo[key] = True
                return True
        memo[key] = False
        return False

    upper = 5 * (row_count + column_count) + 4 * (chat_time + burr_time) + 20
    if not possible(start, upper):
        return '-1\n'
    low, high = 0, upper
    while low < high:
        middle = (low + high) // 2
        if possible(start, middle):
            high = middle
        else:
            low = middle + 1
    return str(low) + '\n'


SAMPLE = """5 6 5 1
......
BWTTTB
B.TB..
BBT..T
.FTfw.
"""
SAMPLE_OUT = """17
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 3 1 10\nf.w\nTBT\nW.F\n") == "15\n"
assert oracle("1 6 5 1\nWf..wF\n") == "9\n"
assert oracle("2 2 1 1\nfF\nwW\n") == "1\n"


def write(name, row_count, column_count, chat_time, burr_time, grid):
    text = f"{row_count} {column_count} {chat_time} {burr_time}\n" + "\n".join(grid) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 6, 5, 1, ["Wf..wF"])
    write("3_wide", 5, 5, 2, 2, ["f.B.T", ".T.B.", "B.T..", "w.T..", "W...F"])
    rng = random.Random(20261202)
    grid = [["." for _ in range(5)] for _ in range(5)]
    for mark, cell in zip("fFwW", rng.sample(range(25), 4)):
        grid[cell // 5][cell % 5] = mark
    for row in range(5):
        for col in range(5):
            if grid[row][col] == '.' and rng.random() < 0.3:
                grid[row][col] = rng.choice("BT")
    write("4_random", 5, 5, 2, 3, ["".join(row) for row in grid])
    write("5_io", 5, 5, 3, 4, ["f..BT", ".T.T.", "wT.TF", "B....", "W...."])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 5, 6, 5, 1, ["......", "BWTTTB", "B.TB..", "BBT..T", ".FTfw."])
build()
