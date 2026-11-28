#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(maxsize=None)
def oracle_brute(matrix):
    n = len(matrix)

    @lru_cache(maxsize=None)
    def winners(mask):
        alive = [i for i in range(n) if mask >> i & 1]
        if len(alive) == 1:
            return frozenset(alive)
        answer = set()
        for position, p in enumerate(alive):
            q = alive[(position + 1) % len(alive)]
            winner = p if matrix[p][q] else q
            loser = q if winner == p else p
            answer |= winners(mask & ~(1 << loser))
        return frozenset(answer)

    return frozenset(winners((1 << n) - 1))


@lru_cache(maxsize=None)
def oracle_intervals(matrix):
    n = len(matrix)
    doubled = 2 * n
    table = [[set() for _ in range(doubled)] for _ in range(doubled)]
    for position in range(doubled):
        table[position][position].add(position % n)
    for length in range(2, n + 1):
        for left in range(doubled - length + 1):
            right = left + length - 1
            answer = set()
            for split in range(left, right):
                left_set = table[left][split]
                right_set = table[split + 1][right]
                for p in left_set:
                    if any(matrix[p][q] for q in right_set):
                        answer.add(p)
                for q in right_set:
                    if any(matrix[q][p] for p in left_set):
                        answer.add(q)
            table[left][right] = answer
    answer = set()
    for start in range(n):
        answer |= table[start][start + n - 1]
    return frozenset(answer)


@lru_cache(maxsize=None)
def oracle_fast(matrix):
    n = len(matrix)
    doubled = 2 * n
    columns = [sum(1 << i for i in range(n) if matrix[i][j]) for j in range(n)]
    win = [[0] * doubled for _ in range(doubled)]
    hit = [[0] * doubled for _ in range(doubled)]
    for position in range(doubled):
        player = position % n
        win[position][position] = 1 << player
        hit[position][position] = columns[player]
    for length in range(2, n + 1):
        for left in range(doubled - length):
            right = left + length - 1
            answer = 0
            for split in range(left, right):
                answer |= ((win[left][split] & hit[split + 1][right]) |
                           (win[split + 1][right] & hit[left][split]))
            win[left][right] = answer
            hit_mask = 0
            remaining = answer
            while remaining:
                lowest = remaining & -remaining
                hit_mask |= columns[lowest.bit_length() - 1]
                remaining ^= lowest
            hit[left][right] = hit_mask
    answer = 0
    for start in range(n):
        answer |= win[start][start + n - 1]
    return frozenset(i for i in range(n) if answer >> i & 1)


@lru_cache(maxsize=None)
def oracle(matrix):
    if len(matrix) <= 12:
        return oracle_brute(matrix)
    return oracle_fast(matrix)


def format_output(cases):
    lines = []
    for matrix in cases:
        winners = sorted(oracle(matrix))
        lines.append(str(len(winners)))
        lines.extend(str(winner + 1) for winner in winners)
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n"
    for matrix in cases:
        input_text += str(len(matrix)) + "\n"
        input_text += "".join("".join(map(str, row)) + "\n" for row in matrix)
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(format_output(cases))


def tournament(n, rng, upset=0.5):
    order = list(range(n))
    rng.shuffle(order)
    matrix = [[0] * n for _ in range(n)]
    for i in range(n):
        matrix[i][i] = 1
    for i in range(n):
        for j in range(i + 1, n):
            value = 1 if rng.random() < upset else 0
            matrix[order[i]][order[j]] = value
            matrix[order[j]][order[i]] = 1 - value
    return tuple(tuple(row) for row in matrix)


def chain(n, ascending=True):
    matrix = [[0] * n for _ in range(n)]
    for i in range(n):
        for j in range(n):
            if i == j:
                matrix[i][j] = 1
            elif ascending:
                matrix[i][j] = 1 if i < j else 0
            else:
                matrix[i][j] = 1 if i > j else 0
    return tuple(tuple(row) for row in matrix)


def cycle(n):
    assert n % 2 == 1
    matrix = [[0] * n for _ in range(n)]
    half = (n - 1) // 2
    for i in range(n):
        matrix[i][i] = 1
        for step in range(1, half + 1):
            matrix[i][(i + step) % n] = 1
    return tuple(tuple(row) for row in matrix)


SAMPLE = (
    (1, 1, 1, 1, 1, 0, 1),
    (0, 1, 0, 1, 1, 0, 0),
    (0, 1, 1, 1, 1, 1, 1),
    (0, 0, 0, 1, 1, 0, 1),
    (0, 0, 0, 0, 1, 0, 1),
    (1, 1, 0, 1, 1, 1, 1),
    (0, 1, 0, 0, 0, 0, 1),
)

assert oracle(SAMPLE) == frozenset({0, 2, 5})
assert oracle(chain(3)) == frozenset({0})
assert oracle(cycle(3)) == frozenset({0, 1, 2})
assert oracle(cycle(7)) == frozenset({0, 1, 2, 3, 4, 5, 6})

check_rng = random.Random(99)
for _ in range(150):
    small = tournament(check_rng.randint(3, 8), check_rng)
    assert oracle_brute(small) == oracle_intervals(small) == oracle_fast(small)
for _ in range(24):
    medium = tournament(check_rng.randint(13, 18), check_rng)
    assert oracle_intervals(medium) == oracle_fast(medium)


def build():
    edges = [
        chain(3), cycle(3), chain(4), tournament(4, random.Random(4)), chain(5),
        tournament(5, random.Random(7)), tournament(8, random.Random(8)),
        tournament(10, random.Random(10)), tournament(12, random.Random(12)),
        chain(100), chain(100, False), chain(99),
    ]
    write("2_edges", edges)

    wide_rng = random.Random(4242)
    write("3_wide", [tournament(100, wide_rng),
                     tournament(100, wide_rng, 0.1),
                     tournament(100, wide_rng, 0.9),
                     cycle(99)])

    random_rng = random.Random(20261124)
    random_cases = []
    for _ in range(24):
        size = random_rng.randint(3, 100)
        random_cases.append(tournament(size, random_rng))
    write("4_random", random_cases)

    io_rng = random.Random(555)
    io_cases = [cycle(3)] * 200000
    io_cases += [chain(100), tournament(100, io_rng), cycle(99)]
    write("5_io", io_cases)


def worked_example():
    lines = []
    for start in range(7):
        lines.append("%d %s" % (start + 1,
                     sorted(w + 1 for w in oracle_intervals_cut(SAMPLE, start))))
    return "\n".join(lines)


def oracle_intervals_cut(matrix, start):
    n = len(matrix)
    doubled = 2 * n
    table = [[set() for _ in range(doubled)] for _ in range(doubled)]
    for position in range(doubled):
        table[position][position].add(position % n)
    for length in range(2, n + 1):
        for left in range(doubled - length + 1):
            right = left + length - 1
            answer = set()
            for split in range(left, right):
                left_set = table[left][split]
                right_set = table[split + 1][right]
                for p in left_set:
                    if any(matrix[p][q] for q in right_set):
                        answer.add(p)
                for q in right_set:
                    if any(matrix[q][p] for p in left_set):
                        answer.add(q)
            table[left][right] = answer
    return table[start][start + n - 1]


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE])
build()
print(worked_example())
