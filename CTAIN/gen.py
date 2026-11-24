#!/usr/bin/env python3
import itertools
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def successors(state, caps):
    n = len(caps)
    for i in range(n):
        if state[i] == 0:
            continue
        drained = list(state)
        drained[i] = 0
        yield tuple(drained)
        for j in range(n):
            if i == j:
                continue
            room = caps[j] - state[j]
            if room <= 0:
                continue
            if state[i] <= room:
                poured = list(state)
                poured[i] = 0
                poured[j] = state[j] + state[i]
                yield tuple(poured)
            else:
                poured = list(state)
                poured[i] = state[i] - room
                poured[j] = caps[j]
                yield tuple(poured)


def distance_map(caps):
    start = tuple(caps)
    seen = {start: 0}
    queue = deque([start])
    while queue:
        state = queue.popleft()
        step = seen[state] + 1
        for following in successors(state, caps):
            if following not in seen:
                seen[following] = step
                queue.append(following)
    return seen


def oracle_answer(caps, targets):
    if list(caps) == list(targets):
        return 0
    seen = distance_map(caps)
    return seen.get(tuple(targets))


def relax_answer(caps, targets):
    n = len(caps)
    states = list(itertools.product(*(range(c + 1) for c in caps)))
    endless = 10 ** 6
    steps = {state: endless for state in states}
    steps[tuple(caps)] = 0
    changed = True
    while changed:
        changed = False
        for state in states:
            if steps[state] == endless:
                continue
            for following in successors(state, caps):
                if steps[state] + 1 < steps[following]:
                    steps[following] = steps[state] + 1
                    changed = True
    best = steps[tuple(targets)]
    return None if best == endless else best


def shortest_path(caps, targets):
    start = tuple(caps)
    goal = tuple(targets)
    parent = {start: None}
    queue = deque([start])
    while queue:
        state = queue.popleft()
        if state == goal:
            break
        for i in range(len(caps)):
            if state[i] == 0:
                continue
            label = f"drain {i + 1}"
            drained = list(state); drained[i] = 0
            moves = [(tuple(drained), label)]
            for j in range(len(caps)):
                if i == j:
                    continue
                room = caps[j] - state[j]
                if room <= 0:
                    continue
                poured = list(state)
                if state[i] <= room:
                    poured[i] = 0
                    poured[j] += state[i]
                    label = f"pour {i + 1} into {j + 1}"
                else:
                    poured[i] -= room
                    poured[j] = caps[j]
                    label = f"fill {j + 1} from {i + 1}"
                moves.append((tuple(poured), label))
            for following, move_label in moves:
                if following not in parent:
                    parent[following] = (state, move_label)
                    queue.append(following)
    lines = [f"start {start}"]
    path = []
    current = goal
    while parent[current] is not None:
        previous, label = parent[current]
        path.append((label, current))
        current = previous
    path.reverse()
    for step, (label, state) in enumerate(path, 1):
        lines.append(f"{step} {label} -> {state}")
    return "\n".join(lines)


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        n = int(tokens[cursor]); cursor += 1
        caps = [int(tokens[cursor + i]) for i in range(n)]
        cursor += n
        targets = [int(tokens[cursor + i]) for i in range(n)]
        cursor += n
        answer = oracle_answer(caps, targets)
        answers.append("NO" if answer is None else str(answer))
    return "\n".join(answers) + "\n"


def format_case(caps, targets):
    return f"{len(caps)}\n" + " ".join(map(str, caps)) + "\n" + " ".join(map(str, targets)) + "\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n\n" + "\n".join(
        format_case(caps, targets) for caps, targets in cases)
    if len(cases) > 1:
        input_text += "\n"
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def farthest(caps, minimum=0):
    seen = distance_map(caps)
    best = max(seen, key=lambda state: (seen[state] >= minimum, seen[state]))
    return list(best), seen[best]


SAMPLE = [([3, 5, 5], [0, 0, 4]), ([20, 25], [10, 16])]
SAMPLE_INPUT = "2\n\n" + "\n".join(format_case(c, t) for c, t in SAMPLE) + "\n"

assert oracle(SAMPLE_INPUT) == "6\nNO\n"
assert oracle_answer([7], [7]) == 0
assert oracle_answer([7], [0]) == 1
assert oracle_answer([7], [3]) is None
assert oracle_answer([3, 5, 5], [0, 0, 4]) == 6
assert oracle_answer([20, 25], [10, 16]) is None
assert len(distance_map([49, 49, 49, 49])) == 16
for small_caps, small_targets in [
    ([3, 4], [1, 2]), ([2, 3, 4], [0, 1, 3]), ([4], [0]), ([1, 1, 1], [0, 0, 1]),
]:
    assert oracle_answer(small_caps, small_targets) == relax_answer(small_caps, small_targets)


DEEP_TARGET, DEEP_STEPS = farthest([41, 17, 34, 41])


def build():
    edges = [
        ([7], [7]), ([7], [0]), ([7], [3]),
        ([1], [0]), ([1], [1]),
        ([4, 4], [4, 4]), ([4, 4], [0, 0]), ([4, 4], [4, 0]),
        ([3, 5, 5], [0, 0, 4]), ([3, 5, 5], [3, 5, 5]),
        ([9, 4], [0, 9]), ([6, 11], [1, 11]),
    ]
    write("2_edges", edges)

    wide_target, wide_steps = farthest([45, 42, 49, 30])
    assert wide_steps >= 20
    assert DEEP_STEPS >= 100
    write("3_wide", [
        ([49, 49, 49, 49], [49, 0, 0, 0]),
        ([45, 42, 49, 30], wide_target),
        ([1, 1, 1, 1], [0, 0, 0, 1]),
        ([41, 17, 34, 41], DEEP_TARGET),
        ([49, 49, 49], [1, 49, 49]),
    ])

    random.seed(2026)
    random_cases = []
    for _ in range(20):
        n = random.randint(1, 4)
        caps = [random.randint(1, 49) for _ in range(n)]
        if n <= 3:
            reachable = list(distance_map(caps))
            targets = random.choice(reachable)
        else:
            targets = [random.randint(0, c) for c in caps]
        random_cases.append((caps, list(targets)))
    write("4_random", random_cases)

    write("5_io", [([41, 17, 34, 41], list(DEEP_TARGET)) for _ in range(20)])


write("1_sample", SAMPLE)
build()
WORKED_PATH = shortest_path([3, 5, 5], [0, 0, 4])
assert len(WORKED_PATH.splitlines()) == 7
print(WORKED_PATH)
