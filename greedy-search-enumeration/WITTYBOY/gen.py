#!/usr/bin/env python3
from collections import deque
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LIMIT = 40


def parse_case(tokens, cursor):
    channel_count = tokens[cursor]
    cursor += 1
    banned_count = tokens[cursor]
    cursor += 1
    banned = set(tokens[cursor:cursor + banned_count])
    cursor += banned_count
    target_count = tokens[cursor]
    cursor += 1
    targets = tokens[cursor:cursor + target_count]
    cursor += target_count
    return channel_count, banned, targets, cursor


def transition_data(channel_count, banned, targets):
    allowed = [False] + [True] * channel_count
    for channel in banned:
        allowed[channel] = False
    upward = [0] * (channel_count + 1)
    downward = [0] * (channel_count + 1)
    first = next(channel for channel in range(1, channel_count + 1)
                 if allowed[channel])
    last = max(channel for channel in range(1, channel_count + 1)
               if allowed[channel])
    for channel in range(1, channel_count + 1):
        if not allowed[channel]:
            continue
        up = channel + 1
        while up <= channel_count and not allowed[up]:
            up += 1
        upward[channel] = up if up <= channel_count else first
        down = channel - 1
        while down >= 1 and not allowed[down]:
            down -= 1
        downward[channel] = down if down >= 1 else last
    digit_options = set(targets)
    for channel in range(1, min(channel_count, 9) + 1):
        if allowed[channel]:
            digit_options.add(channel)
    for target in targets:
        text = str(target)
        for length in range(1, len(text)):
            prefix = int(text[:length])
            if 1 <= prefix <= channel_count and allowed[prefix]:
                digit_options.add(prefix)
        for neighbour in (target - 1, target + 1):
            if 1 <= neighbour <= channel_count and allowed[neighbour]:
                digit_options.add(neighbour)
    return allowed, upward, downward, digit_options


def moves(channel_count, allowed, upward, downward, digit_options,
          current, prior, digit_options_all):
    result = [(upward[current], 1), (downward[current], 1)]
    if prior > 0:
        result.append((prior, 1))
    if digit_options_all:
        choices = [channel for channel in range(1, channel_count + 1)
                   if allowed[channel]]
    else:
        choices = sorted(digit_options)
    divisor = 10 ** len(str(current))
    for channel in choices:
        if channel == current:
            continue
        cost = len(str(channel))
        if channel // divisor == current:
            cost -= len(str(current))
        result.append((channel, cost))
    return result


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        channel_count, banned, targets, cursor = parse_case(tokens, cursor)
        allowed, upward, downward, digit_options = transition_data(
            channel_count, banned, targets)
        all_digits = channel_count <= 12
        state_width = channel_count + 1
        progress_width = len(targets) + 1
        buckets = [dict() for _ in range(LIMIT + 1)]
        start = (0 * state_width + targets[0]) * progress_width + 1
        start_cost = len(str(targets[0]))
        buckets[start_cost][start] = (targets[0], 0)
        best = None
        for cost in range(LIMIT + 1):
            for state, (current, prior) in list(buckets[cost].items()):
                progress = state % progress_width
                if progress == len(targets):
                    best = cost
                    break
                wanted = targets[progress]
                for channel, step_cost in moves(
                        channel_count, allowed, upward, downward, digit_options,
                        current, prior, all_digits):
                    new_cost = cost + step_cost
                    if new_cost > LIMIT or (best is not None and new_cost >= best):
                        continue
                    advanced = progress + 1 if channel == wanted else progress
                    if advanced == len(targets):
                        best = new_cost
                        continue
                    new_state = (current * state_width + channel) * progress_width + advanced
                    if new_state not in buckets[new_cost]:
                        buckets[new_cost][new_state] = (channel, current)
            if best is not None:
                break
        answers.append(f"Case #{len(answers) + 1}: " +
                       str(best if best is not None else -1))
    return "\n".join(answers) + "\n"


def brute(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    bound = 8
    for _ in range(case_count):
        channel_count, banned, targets, cursor = parse_case(tokens, cursor)
        allowed, upward, downward, digit_options = transition_data(
            channel_count, banned, targets)
        queue = deque([(0, targets[0], 1, len(str(targets[0])))])
        best = None
        while queue:
            prior, current, progress, cost = queue.popleft()
            if cost > bound or (best is not None and cost >= best):
                continue
            if progress == len(targets):
                best = cost
                break
            wanted = targets[progress]
            for channel, step_cost in moves(
                    channel_count, allowed, upward, downward, digit_options,
                    current, prior, True):
                advanced = progress + 1 if channel == wanted else progress
                queue.append((current, channel, advanced, cost + step_cost))
        answers.append(f"Case #{len(answers) + 1}: " +
                       str(best if best is not None else -1))
    return "\n".join(answers) + "\n"


SAMPLE = """3
5 0

5
1 2 3 4 5
500 0

4
140 160 139 160
5 2
2 4
5
1 3 5 3 5
"""
SAMPLE_OUT = """Case #1: 5
Case #2: 9
Case #3: 5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5 0\n\n3\n1 2 3\n") == "Case #1: 3\n"
assert oracle("1\n5 2\n2 4\n\n3\n1 3 5\n") == "Case #1: 3\n"
assert oracle("1\n9 0\n\n2\n1 9\n") == "Case #1: 2\n"
tiny_cases = [
    "1\n5 0\n\n2\n1 5\n",
    "1\n6 1\n3\n\n3\n1 5 6\n",
    "1\n8 2\n2 7\n\n3\n1 4 8\n",
]
for case_text in tiny_cases:
    assert oracle(case_text) == brute(case_text)


def write(name, cases):
    chunks = [str(len(cases))]
    for channel_count, banned, targets in cases:
        chunks.append(f"{channel_count} {len(banned)}")
        if banned:
            chunks.append(" ".join(map(str, banned)))
        else:
            chunks.append("")
        chunks.append(str(len(targets)))
        chunks.append(" ".join(map(str, targets)))
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (5, [], [1, 2, 3, 4, 5]),
        (5, [2, 4], [1, 3, 5, 3, 5]),
        (9, [], [1, 9]),
        (6, [3], [1, 2, 4, 5]),
    ])
    write("3_wide", [
        (12, [], list(range(1, 11))),
        (12, [5, 6], [2, 4, 3, 11, 1]),
        (10, [], [9, 1, 10, 1, 10]),
    ])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(40):
        channel_count = rng.randint(3, 12)
        banned = sorted(rng.sample(range(1, channel_count + 1),
                                   rng.randint(0, max(0, channel_count // 3))))
        allowed = [channel for channel in range(1, channel_count + 1)
                   if channel not in banned]
        target_count = min(len(allowed), rng.randint(2, 5))
        targets = rng.sample(allowed, target_count)
        random_cases.append((channel_count, banned, targets))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(200):
        channel_count = rng.randint(2, 10)
        banned = []
        allowed = list(range(1, channel_count + 1))
        targets = rng.sample(allowed, min(len(allowed), 2))
        io_cases.append((channel_count, banned, targets))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
