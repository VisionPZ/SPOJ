#!/usr/bin/env python3
import random
import sys
from collections import deque
from itertools import permutations
from pathlib import Path

sys.setrecursionlimit(200000)
ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = []
    for expression in tokens[1:1 + case_count]:
        tree_stack = []
        for char in expression:
            if char.islower():
                tree_stack.append(('leaf', char))
            else:
                right_child = tree_stack.pop()
                left_child = tree_stack.pop()
                tree_stack.append(('node', char, left_child, right_child))
        assert len(tree_stack) == 1
        tree = tree_stack[0]

        def encode(items):
            if not items:
                return []
            last = items[-1]
            if last[0] == 'leaf':
                return encode(items[:-1]) + [last[1]]
            operator, left_child, right_child = last[1], last[2], last[3]
            return encode([right_child, left_child] + items[:-1]) + [operator]

        answers.append(''.join(encode([tree])))
    return '\n'.join(answers) + '\n'


def stack_tree(text):
    stack = []
    for char in text:
        if char.islower():
            stack.append(char)
        else:
            right_child = stack.pop()
            left_child = stack.pop()
            stack.append('(' + left_child + char + right_child + ')')
    return stack[0]


def queue_tree(text):
    queue = deque()
    for char in text:
        if char.islower():
            queue.append(char)
        else:
            right_child = queue.popleft()
            left_child = queue.popleft()
            queue.append('(' + left_child + char + right_child + ')')
    return queue[0]


def brute_force(expression):
    target = stack_tree(expression)
    for arrangement in permutations(expression):
        candidate = ''.join(arrangement)
        try:
            if queue_tree(candidate) == target:
                return candidate
        except IndexError:
            pass
    return None


def random_tree(leaf_count, rng, depth=0):
    if leaf_count == 1:
        return chr(97 + rng.randrange(26))
    left_count = 1 + rng.randrange(leaf_count - 1)
    left_child = random_tree(left_count, rng, depth + 1)
    right_child = random_tree(leaf_count - left_count, rng, depth + 1)
    operator = chr(65 + rng.randrange(26))
    return left_child + right_child + operator


def balanced_tree(leaf_count, rng):
    if leaf_count == 1:
        return chr(97 + rng.randrange(26))
    half = leaf_count // 2
    left_child = balanced_tree(half, rng)
    right_child = balanced_tree(leaf_count - half, rng)
    operator = chr(65 + rng.randrange(26))
    return left_child + right_child + operator


def write(name, expressions):
    input_text = str(len(expressions)) + '\n' + ''.join(
        expression + '\n' for expression in expressions)
    (ROOT / 'in' / f'{name}.txt').write_text(input_text)
    (ROOT / 'out' / f'{name}.out').write_text(oracle(input_text))


SAMPLE = ['xyPzwIM', 'abcABdefgCDEF']
SAMPLE_OUT = 'wzyxIPM\ngfCecbDdAaEBF\n'
assert oracle('2\n' + '\n'.join(SAMPLE) + '\n') == SAMPLE_OUT
assert oracle('1\na\n') == 'a\n'
assert oracle('1\nabP\n') == 'baP\n'
assert oracle('1\nabcPQ\n') == brute_force('abcPQ') + '\n'
assert brute_force('xyPzwIM') == 'wzyxIPM'


def build():
    write('2_edges', ['a', 'abP', 'abcPQ', 'abcdPQR', 'abcdefgHIJKLM'])
    write('3_wide', [random_tree(500, random.Random(901))])
    rng = random.Random(20261126)
    write('4_random', [random_tree(rng.randint(1, 40), rng) for _ in range(40)])
    rng = random.Random(1177)
    write('5_io', [balanced_tree(512, rng) for _ in range(200)])


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
write('1_sample', SAMPLE)
build()
