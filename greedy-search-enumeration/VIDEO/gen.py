#!/usr/bin/env python3
import itertools
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LETTERS = "ABC"
NEGATIVE = -1000000000


def automaton(words):
    nodes = [{"next": {}, "fail": 0, "score": 0}]
    for word in words:
        current = 0
        for letter in word:
            if letter not in nodes[current]["next"]:
                nodes[current]["next"][letter] = len(nodes)
                nodes.append({"next": {}, "fail": 0, "score": 0})
            current = nodes[current]["next"][letter]
        nodes[current]["score"] += 1
    for letter in LETTERS:
        child = nodes[0]["next"].get(letter)
        if child is None:
            nodes[0]["next"][letter] = 0
        else:
            nodes[child]["fail"] = 0
    queue = deque(nodes[0]["next"][letter] for letter in LETTERS)
    queue = deque([node for node in queue if node != 0])
    while queue:
        current = queue.popleft()
        nodes[current]["score"] += nodes[nodes[current]["fail"]]["score"]
        for letter in LETTERS:
            child = nodes[current]["next"].get(letter)
            if child is None:
                nodes[current]["next"][letter] = nodes[nodes[current]["fail"]]["next"][letter]
            else:
                nodes[child]["fail"] = nodes[nodes[current]["fail"]]["next"][letter]
                queue.append(child)
    return nodes


def matrix_multiply(left, right, size):
    result = [[NEGATIVE] * size for _ in range(size)]
    for row in range(size):
        for middle in range(size):
            left_value = left[row][middle]
            if left_value <= NEGATIVE // 2:
                continue
            for column in range(size):
                right_value = right[middle][column]
                if right_value <= NEGATIVE // 2:
                    continue
                value = left_value + right_value
                if value > result[row][column]:
                    result[row][column] = value
    return result


def oracle(text):
    values = text.split()
    combo_count = int(values[0])
    press_count = int(values[1])
    words = values[2:2 + combo_count]
    nodes = automaton(words)
    size = len(nodes)
    transition = [[NEGATIVE] * size for _ in range(size)]
    for state in range(size):
        for letter in LETTERS:
            target = nodes[state]["next"][letter]
            transition[state][target] = max(transition[state][target], nodes[target]["score"])
    vector = [NEGATIVE] * size
    vector[0] = 0
    remaining = press_count
    while remaining > 0:
        if remaining & 1:
            updated = [NEGATIVE] * size
            for state in range(size):
                if vector[state] <= NEGATIVE // 2:
                    continue
                for target in range(size):
                    if transition[state][target] > NEGATIVE // 2:
                        updated[target] = max(updated[target], vector[state] + transition[state][target])
            vector = updated
        transition = matrix_multiply(transition, transition, size)
        remaining //= 2
    return str(max(vector)) + "\n"


def brute(words, press_count):
    best = 0
    for letters in itertools.product(LETTERS, repeat=press_count):
        sequence = "".join(letters)
        score = 0
        for word in words:
            for end in range(1, len(sequence) + 1):
                if sequence[:end].endswith(word):
                    score += 1
        if score > best:
            best = score
    return best


SAMPLE = """3 7
ABA
CB
ABACB
"""
SAMPLE_OUT = """4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 3\nA\n") == "3\n"
assert oracle("1 1\nAB\n") == "0\n"
assert oracle("2 5\nA\nAA\n") == "9\n"
assert brute(["ABA", "CB", "ABACB"], 7) == 4
assert brute(["A"], 3) == 3


def write(name, combos, press_count, expected=None):
    text = f"{len(combos)} {press_count}\n" + "\n".join(combos) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    answer = oracle(text)
    if expected is not None:
        assert answer == expected + "\n", (name, answer)
    (ROOT / "out" / f"{name}.out").write_text(answer)


def build():
    write("2_edges", ["A"], 1, "1")
    write("3_wide", ["A", "B", "C", "AB", "BC", "CA", "ABA", "ABC", "CAB", "BBB"], 1000)
    rng = random.Random(20261126)
    combos = []
    for _ in range(5):
        length = rng.randint(1, 3)
        combos.append("".join(rng.choice(LETTERS) for _ in range(length)))
    combos = sorted(set(combos))
    press_count = rng.randint(4, 7)
    text = f"{len(combos)} {press_count}\n" + "\n".join(combos) + "\n"
    assert oracle(text) == str(brute(combos, press_count)) + "\n"
    write("4_random", combos, press_count)
    write("5_io", ["AAAAA", "BBBBB", "CCCCC", "ABCABC", "CABCAB"], 1000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", ["ABA", "CB", "ABACB"], 7, "4")
build()
