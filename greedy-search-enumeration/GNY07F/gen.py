#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.splitlines()
    count = int(lines[0])
    answers = []
    for case in range(1, count + 1):
        vine = lines[case] if case < len(lines) else ""
        stack = [[]]
        for char in vine:
            if char == '[':
                stack.append([])
            elif char == ']':
                children = stack.pop()
                value = 2 * max(children) if children else 2
                stack[-1].append(value)
        root = stack[0]
        monkeys = max(root) if root else 1
        answers.append(f"{case} {monkeys}")
    return "\n".join(answers) + "\n"


SAMPLE = """3
[]

[[][[]]]
"""
SAMPLE_OUT = """1 2
2 1
3 8
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n[]\n") == "1 2\n"
assert oracle("1\n[[]]\n") == "1 4\n"
assert oracle("1\n[[]][[]]\n") == "1 4\n"
assert oracle("1\n\n") == "1 1\n"


def write(name, vines):
    text = str(len(vines)) + "\n" + "\n".join(vines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_vine(rng, depth):
    if depth <= 0 or rng.random() < 0.3:
        return ""
    child_count = rng.choice([1, 2])
    children = [make_vine(rng, depth - 1) for _ in range(child_count)]
    if child_count == 1:
        children.append("")
    return "[" + children[0] + children[1] + "]"


def build():
    write("2_edges", ["", "[]", "[[]]", "[[][]]"])
    rng = random.Random(20261126)
    write("3_wide", [make_vine(rng, 10) for _ in range(200)])
    write("4_random", [make_vine(rng, 6) for _ in range(200)])
    write("5_io", [make_vine(rng, 12) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
