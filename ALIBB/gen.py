#!/usr/bin/env python3
import heapq
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 18


def parse(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    cases = []
    for _ in range(case_count):
        n = int(tokens[cursor])
        cursor += 1
        pos = [0]
        due = [0]
        for _ in range(n):
            pos.append(int(tokens[cursor]))
            cursor += 1
            due.append(int(tokens[cursor]))
            cursor += 1
        cases.append((n, pos, due))
    return cases


def subset_search(n, pos, due):
    full = (1 << n) - 1
    best = {}
    queue = []
    for start in range(1, n + 1):
        if due[start] > 0:
            state = (1 << (start - 1), start)
            best[state] = 0
            heapq.heappush(queue, (0, state))
    while queue:
        time, state = heapq.heappop(queue)
        if best.get(state) != time:
            continue
        mask, last = state
        if mask == full:
            return str(time)
        for nxt in range(1, n + 1):
            if mask & (1 << (nxt - 1)):
                continue
            arrival = time + abs(pos[nxt] - pos[last])
            if arrival >= due[nxt]:
                continue
            following = (mask | (1 << (nxt - 1)), nxt)
            if arrival < best.get(following, INF):
                best[following] = arrival
                heapq.heappush(queue, (arrival, following))
    return "No solution"


def interval_dp(n, pos, due):
    if n == 1:
        return "0"
    prev_left = [INF] * (n + 2)
    prev_right = [INF] * (n + 2)
    prev_left[1] = 0
    prev_right[1] = 0
    for right in range(2, n + 1):
        cur_left = [INF] * (n + 2)
        cur_right = [INF] * (n + 2)
        cur_left[right] = 0
        cur_right[right] = 0
        for left in range(right - 1, 0, -1):
            value = min(cur_left[left + 1] + pos[left + 1] - pos[left],
                        cur_right[left + 1] + pos[right] - pos[left])
            cur_left[left] = INF if value >= due[left] else value
            value = min(prev_left[left] + pos[right] - pos[left],
                        prev_right[left] + pos[right] - pos[right - 1])
            cur_right[left] = INF if value >= due[right] else value
        prev_left, prev_right = cur_left, cur_right
    result = min(prev_left[1], prev_right[1])
    return str(result) if result < INF else "No solution"


def oracle_case(n, pos, due):
    if n <= 11:
        brute = subset_search(n, pos, due)
        dynamic = interval_dp(n, pos, due)
        assert brute == dynamic, (brute, dynamic, pos, due)
        if min(due[1:n + 1]) > pos[n] - pos[1]:
            assert brute == str(pos[n] - pos[1])
        return brute
    span = pos[n] - pos[1]
    if min(due[1:n + 1]) > span:
        return str(span)
    return interval_dp(n, pos, due)


def oracle(text):
    answers = []
    for n, pos, due in parse(text):
        answers.append(oracle_case(n, pos, due))
    return "\n".join(answers) + "\n"


def render(cases):
    lines = [str(len(cases))]
    for n, pos, due in cases:
        lines.append(str(n))
        for k in range(1, n + 1):
            lines.append(f"{pos[k]} {due[k]}")
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [
    (5, [0, 1, 3, 5, 8, 10], [0, 3, 1, 8, 19, 15]),
    (5, [0, 1, 2, 3, 4, 5], [0, 5, 1, 4, 2, 3]),
]

assert oracle(render(SAMPLE)) == "11\nNo solution\n"
assert oracle_case(1, [0, 7], [0, 1]) == "0"
assert oracle_case(2, [0, 0, 10], [0, 1, 11]) == "10"
assert oracle_case(2, [0, 0, 10], [0, 5, 5]) == "No solution"
assert oracle_case(3, [0, 0, 5, 10], [0, 6, 1, 20]) == "15"
assert oracle_case(3, [0, 0, 5, 10], [0, 6, 1, 6]) == "No solution"


def build():
    write("2_edges", [
        (1, [0, 7], [0, 1]),
        (1, [0, 0], [0, 1]),
        (2, [0, 0, 10], [0, 1, 11]),
        (2, [0, 0, 10], [0, 5, 5]),
        (2, [0, 0, 1], [0, 2, 2]),
        (3, [0, 0, 5, 10], [0, 6, 1, 20]),
        (3, [0, 0, 5, 10], [0, 6, 1, 6]),
        (4, [0, 0, 1, 2, 3], [0, 1, 2, 3, 4]),
    ])

    write("3_wide", [
        (10000, [0] + list(range(1, 10001)), [0] + [10 ** 9] * 10000),
        (10000, [0] + [k * 1000 for k in range(1, 10001)], [0] + [10 ** 9] * 10000),
        (10000, [0] + [k * 7 for k in range(1, 10001)], [0] + [10 ** 7] * 10000),
    ])

    rng = random.Random(20261124)
    random_cases = []
    for _ in range(200):
        n = rng.randint(1, 9)
        cursor = rng.randint(0, 50)
        pos = [0]
        due = [0]
        for _ in range(n):
            cursor += rng.randint(1, 20)
            pos.append(cursor)
            due.append(rng.randint(1, cursor + 30))
        random_cases.append((n, pos, due))
    write("4_random", random_cases)

    io_cases = []
    for case_index in range(10):
        pos = [0] + [k * 100 + (k + case_index) % 7 for k in range(1, 10001)]
        due = [0] + [10 ** 12] * 10000
        io_cases.append((10000, pos, due))
    write("5_io", io_cases)


def worked_example():
    n, pos, due = SAMPLE[0]
    table = {}
    for right in range(1, n + 1):
        table[(right, right)] = (0, 0)
    for right in range(2, n + 1):
        for left in range(right - 1, 0, -1):
            to_left = min(table[(left + 1, right)][0] + pos[left + 1] - pos[left],
                          table[(left + 1, right)][1] + pos[right] - pos[left])
            to_right = min(table[(left, right - 1)][0] + pos[right] - pos[left],
                           table[(left, right - 1)][1] + pos[right] - pos[right - 1])
            table[(left, right)] = (
                INF if to_left >= due[left] else to_left,
                INF if to_right >= due[right] else to_right)
    def show(left, right):
        pair = table[(left, right)]
        return f"{'inf' if pair[0] == INF else pair[0]}, {'inf' if pair[1] == INF else pair[1]}"
    lines = [f"right {right}, left 1 -> ({show(1, right)})" for right in range(1, n + 1)]
    lines += [f"right 5, left {left} -> ({show(left, 5)})" for left in range(2, 5)]
    result = min(table[(1, n)])
    assert result == 11
    lines.append(f"answer {result}")
    return "\n".join(lines)


if __name__ == "__main__":
    if "--example" in sys.argv:
        print(worked_example())
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", SAMPLE)
        build()
