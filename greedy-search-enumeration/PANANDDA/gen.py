#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent

START, AFTER_P, AFTER_PA, AFTER_D = 0, 1, 2, 3
INS = {START: [AFTER_P, AFTER_D], AFTER_P: [AFTER_PA], AFTER_PA: [START], AFTER_D: [START]}
MATCH = {(START, 'P'): AFTER_P, (AFTER_P, 'A'): AFTER_PA,
         (AFTER_PA, 'N'): START, (AFTER_D, 'A'): START, (START, 'D'): AFTER_D}
INF = 10 ** 9


def oracle(text):
    letters = ''.join(value for value in text if value in 'PAND')
    dist = {(0, START): 0}
    queue = deque([(0, START)])
    while queue:
        position, state = queue.popleft()
        cost = dist[(position, state)]
        for next_state in INS[state]:
            candidate = cost + 1
            if candidate < dist.get((position, next_state), INF):
                dist[(position, next_state)] = candidate
                queue.append((position, next_state))
        if position < len(letters):
            next_state = MATCH.get((state, letters[position]))
            if next_state is not None and cost < dist.get((position + 1, next_state), INF):
                dist[(position + 1, next_state)] = cost
                queue.appendleft((position + 1, next_state))
    return str(dist.get((len(letters), START), INF)) + "\n"


def brute(text):
    letters = ''.join(value for value in text if value in 'PAND')
    best = INF
    limit = len(letters) + 5
    stack = [""]
    while stack:
        value = stack.pop()
        if len(value) > limit:
            continue
        cursor = 0
        matched = True
        for char in letters:
            while cursor < len(value) and value[cursor] != char:
                cursor += 1
            if cursor == len(value):
                matched = False
                break
            cursor += 1
        if matched:
            best = min(best, len(value) - len(letters))
        stack.append(value + "DA")
        stack.append(value + "PAN")
    return str(best) + "\n"


SAMPLE = """PANDA
"""
SAMPLE_OUT = """0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("DPANA\n") == "2\n" and brute("DPANA\n") == "2\n"
assert oracle("PA\n") == "1\n" and brute("PA\n") == "1\n"
assert oracle("N\n") == "2\n" and brute("N\n") == "2\n"
for probe in ["P", "A", "D", "N", "PP", "AN", "DD", "PAN", "DADA", "PAND"]:
    assert oracle(probe + "\n") == brute(probe + "\n"), probe


def write(name, text):
    input_text = text + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", "DPANA")
    write("3_wide", "PAND" * 20000)
    rng = random.Random(20261126)
    write("4_random", ''.join(rng.choice("PAND") for _ in range(100000)))
    write("5_io", "DA" * 20000 + "PAN" * 20000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "PANDA")
build()
