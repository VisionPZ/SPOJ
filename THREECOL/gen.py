#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.setrecursionlimit(200000)

GREEN = 1


def random_spec(n):
    if n == 1:
        return '0'
    if n == 2 or random.random() < 0.35:
        return '1' + random_spec(n - 1)
    left_count = random.randint(1, n - 2)
    return ('2' + random_spec(left_count)
            + random_spec(n - 1 - left_count))


def oracle_spec(spec):
    pos = 0

    def parse():
        nonlocal pos
        digit = int(spec[pos])
        pos += 1
        gain = (0, 1, 0)
        if digit == 0:
            return (0, 1, 0, 0, 1, 0)
        if digit == 1:
            child = parse()
            child_max = child[:3]
            child_min = child[3:]
            result = []
            for color in range(3):
                allowed = [child_max[d] for d in range(3) if d != color]
                result.append(gain[color] + max(allowed))
            for color in range(3):
                allowed = [child_min[d] for d in range(3) if d != color]
                result.append(gain[color] + min(allowed))
            return tuple(result)
        left = parse()
        right = parse()
        left_max = left[:3]
        right_max = right[:3]
        left_min = left[3:]
        right_min = right[3:]
        result = []
        for color in range(3):
            pairs = [(x, y) for x in range(3) for y in range(3)
                     if x != color and y != color and x != y]
            result.append(gain[color] + max(left_max[x] + right_max[y]
                                           for x, y in pairs))
        for color in range(3):
            pairs = [(x, y) for x in range(3) for y in range(3)
                     if x != color and y != color and x != y]
            result.append(gain[color] + min(left_min[x] + right_min[y]
                                           for x, y in pairs))
        return tuple(result)

    result = parse()
    assert pos == len(spec)
    return max(result[:3]), min(result[3:])


def colorings_for(node, color):
    if not node:
        return [(1 if color == GREEN else 0,)]
    if len(node) == 1:
        return [(1 if color == GREEN else 0,) + tail
                for child_color in range(3) if child_color != color
                for tail in colorings_for(node[0], child_color)]
    result = []
    for left_color in range(3):
        for right_color in range(3):
            if left_color == color or right_color == color:
                continue
            if left_color == right_color:
                continue
            for left in colorings_for(node[0], left_color):
                for right in colorings_for(node[1], right_color):
                    result.append((1 if color == GREEN else 0,) + left + right)
    return result


def brute_spec(spec):
    pos = 0

    def parse():
        nonlocal pos
        digit = int(spec[pos])
        pos += 1
        if digit == 0:
            return ()
        if digit == 1:
            return (parse(),)
        left = parse()
        right = parse()
        return (left, right)

    tree = parse()
    assert pos == len(spec)
    greens = []
    for color in range(3):
        greens += [sum(c) for c in colorings_for(tree, color)]
    return max(greens), min(greens)


def all_specs(n):
    if n == 1:
        yield '0'
        return
    for sub in all_specs(n - 1):
        yield '1' + sub
    for left_count in range(1, n - 1):
        for left in all_specs(left_count):
            for right in all_specs(n - 1 - left_count):
                yield '2' + left + right


def worked_example():
    spec = '1122002010'
    pos = 0

    def parse():
        nonlocal pos
        digit = int(spec[pos])
        pos += 1
        if digit == 0:
            return ()
        if digit == 1:
            return (parse(),)
        return (parse(), parse())

    tree = parse()
    rows = []
    for color in range(3):
        greens = [sum(painted) for painted in colorings_for(tree, color)]
        rows.append((color, max(greens), min(greens)))
    return rows


example_rows = worked_example()
assert max(row[1] for row in example_rows) == 5
assert min(row[2] for row in example_rows) == 2

assert oracle_spec('0') == (1, 0)
assert oracle_spec('10') == (1, 0)
assert oracle_spec('110') == (2, 0)
assert oracle_spec('200') == (1, 1)
assert oracle_spec('1122002010') == (5, 2)
for length in range(1, 8):
    for candidate in all_specs(length):
        assert oracle_spec(candidate) == brute_spec(candidate), candidate

random.seed(207)
for trial in range(60):
    candidate = random_spec(random.randint(1, 9))
    assert oracle_spec(candidate) == brute_spec(candidate), candidate


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        answer = oracle_spec(tokens[cursor])
        cursor += 1
        answers.append(f'{answer[0]} {answer[1]}')
    return '\n'.join(answers) + '\n'


def write(name, specs):
    input_text = str(len(specs)) + '\n' + ''.join(s + '\n' for s in specs)
    (ROOT / 'in' / f'{name}.txt').write_text(input_text)
    (ROOT / 'out' / f'{name}.out').write_text(oracle(input_text))


write('1_sample', ['1122002010'])
write('2_edges', ['0', '10', '110', '200', '2100', '22000',
                  '1' * 40 + '0', '2' + '1' * 20 + '0' + '0'])
random.seed(2026)
write('3_wide', ['1' * 9999 + '0', random_spec(10000)])
write('4_random', [random_spec(random.randint(1, 2000)) for _ in range(300)])
write('5_io', ['0'] * 200000 + ['1' * 9999 + '0'] * 4)
