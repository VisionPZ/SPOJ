#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def postorder_of(left, right, root, count):
    result = []
    stack = [(root, 0)]
    while stack:
        node, state = stack.pop()
        if state == 0:
            stack.append((node, 1))
            if right[node]:
                stack.append((right[node], 0))
            if left[node]:
                stack.append((left[node], 0))
        else:
            result.append(node)
    assert len(result) == count
    return result


def can_match(pre, post, ino, count):
    left = [0] * (count + 1)
    right = [0] * (count + 1)
    stack = [pre[0]]
    in_index = 0
    try:
        for value in pre[1:]:
            if stack[-1] != ino[in_index]:
                left[stack[-1]] = value
            else:
                parent = 0
                while stack and stack[-1] == ino[in_index]:
                    parent = stack.pop()
                    in_index += 1
                right[parent] = value
            stack.append(value)
    except IndexError:
        return False
    if postorder_of(left, right, pre[0], count) != post:
        return False
    rebuilt_inorder = []
    stack = [(pre[0], 0)]
    while stack:
        node, state = stack.pop()
        if state == 0:
            if right[node]:
                stack.append((right[node], 0))
            stack.append((node, 1))
            if left[node]:
                stack.append((left[node], 0))
        else:
            rebuilt_inorder.append(node)
    return rebuilt_inorder == ino


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        count = tokens[cursor]
        cursor += 1
        pre = tokens[cursor:cursor + count]
        cursor += count
        post = tokens[cursor:cursor + count]
        cursor += count
        ino = tokens[cursor:cursor + count]
        cursor += count
        answers.append("yes" if can_match(pre, post, ino, count) else "no")
    return "\n".join(answers) + "\n"


SAMPLE = """6
1 2 4 5 3 6
4 5 2 6 3 1
4 2 5 1 3 6
"""
SAMPLE_OUT = "yes\n"
SECOND = """6
1 2 4 5 3 6
4 5 2 6 1 3
4 2 5 1 6 3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SECOND) == "no\n"
assert oracle(SAMPLE + SECOND) == "yes\nno\n"
assert oracle("1\n1\n1\n1\n") == "yes\n"
assert oracle("1\n1\n1\n2\n") == "no\n"


def traversals(pre, ino, count):
    left = [0] * (count + 1)
    right = [0] * (count + 1)
    stack = [pre[0]]
    in_index = 0
    for value in pre[1:]:
        if stack[-1] != ino[in_index]:
            left[stack[-1]] = value
        else:
            parent = 0
            while stack and stack[-1] == ino[in_index]:
                parent = stack.pop()
                in_index += 1
            right[parent] = value
        stack.append(value)
    return postorder_of(left, right, pre[0], count)


def random_case(count, rng, valid):
    labels = list(range(1, count + 1))
    rng.shuffle(labels)
    left = [0] * (count + 1)
    right = [0] * (count + 1)
    placed = [1]
    for node in range(2, count + 1):
        parent = rng.choice(placed)
        if left[parent] == 0:
            left[parent] = node
        elif right[parent] == 0:
            right[parent] = node
        else:
            target = rng.choice(placed)
            while left[target] and right[target]:
                target = rng.choice(placed)
            if left[target] == 0:
                left[target] = node
            else:
                right[target] = node
        placed.append(node)
    pre = []
    ino = []
    stack = [1]
    while stack:
        node = stack.pop()
        pre.append(labels[node - 1])
        if right[node]:
            stack.append(right[node])
        if left[node]:
            stack.append(left[node])
    stack = [(1, 0)]
    while stack:
        node, state = stack.pop()
        if state == 0:
            if right[node]:
                stack.append((right[node], 0))
            stack.append((node, 1))
            if left[node]:
                stack.append((left[node], 0))
        else:
            ino.append(labels[node - 1])
    post = traversals(pre, ino, count)
    if not valid:
        index_one = rng.randrange(count)
        index_two = (index_one + 1 + rng.randrange(count - 1)) % count
        post[index_one], post[index_two] = post[index_two], post[index_one]
    return pre, post, ino


def encode_case(pre, post, ino):
    count = len(pre)
    return (str(count) + "\n" + " ".join(map(str, pre)) + "\n" +
            " ".join(map(str, post)) + "\n" + " ".join(map(str, ino)) + "\n")


def write(name, cases):
    text = "".join(case for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["1\n1\n1\n1\n", "2\n1 2\n2 1\n1 2\n", "2\n1 2\n1 2\n2 1\n"])
    wide_pre = list(range(1, 8001))
    wide_ino = list(range(1, 8001))
    wide_post = list(range(8000, 0, -1))
    write("3_wide", [encode_case(wide_pre, wide_post, wide_ino)])
    rng = random.Random(20261126)
    cases = []
    for count in [2, 3, 5, 9, 17, 31]:
        pre, post, ino = random_case(count, rng, True)
        cases.append(encode_case(pre, post, ino))
        pre2, post2, ino2 = random_case(count, rng, False)
        cases.append(encode_case(pre2, post2, ino2))
    write("4_random", cases)
    io_cases = []
    for _ in range(1200):
        pre, post, ino = random_case(rng.randint(2, 12), rng, rng.random() < 0.5)
        io_cases.append(encode_case(pre, post, ino))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
