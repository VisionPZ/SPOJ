#!/usr/bin/env python3
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def translate(pattern, position=0):
    if pattern[position] != '(':
        return re.escape(pattern[position]), position + 1
    position += 1
    first, position = translate(pattern, position)
    if pattern[position] == ')':
        return '(?:' + first + ')', position + 1
    operation = pattern[position]
    position += 1
    if operation == '*':
        while pattern[position] != ')':
            position += 1
        return '(?:' + first + ')*', position + 1
    second, position = translate(pattern, position)
    position += 1
    if operation == '.':
        return '(?:' + first + second + ')', position
    return '(?:' + first + '|' + second + ')', position


def matches(pattern, word):
    translated, _ = translate(pattern)
    return re.fullmatch(translated, word) is not None


def oracle(text):
    lines = text.split('\n')
    position = 0
    answers = []
    while position < len(lines):
        while position < len(lines) and not lines[position]:
            position += 1
        if position >= len(lines):
            break
        pattern = lines[position]
        position += 1
        while position < len(lines) and not lines[position]:
            position += 1
        if position >= len(lines):
            break
        query_count = int(lines[position])
        position += 1
        for _ in range(query_count):
            word = lines[position] if position < len(lines) else ''
            position += 1
            answers.append('Y' if matches(pattern, word) else 'N')
        answers.append('')
    return '\n'.join(answers) + '\n'


SAMPLE = """(a)
3
a
b
aa
(a.b)
3
a
ab
b
(a|b)
4
a
b
ab
ba
(a*)
3
a
aaaaaaaaaaaaaaaa
baaaaa
((a*).(b*))
3
bbba
aaaa
abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
"""
SAMPLE_OUT = """Y
N
N

N
Y
N

Y
Y
N
N

Y
Y
N

N
Y
Y

"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert matches('(a)', 'a') and not matches('(a)', 'b')
assert matches('(a.b)', 'ab') and not matches('(a.b)', 'ba')
assert matches('(a*)', '')
assert matches('((a*).(b*))', 'aaabbb')
assert not matches('((a*).(b*))', 'aba')


def render(cases):
    blocks = []
    for pattern, words in cases:
        blocks.append(pattern)
        blocks.append(str(len(words)))
        blocks.extend(words)
    return '\n'.join(blocks) + '\n'


def write(name, cases):
    text = render(cases)
    (ROOT / 'in' / f'{name}.txt').write_text(text)
    (ROOT / 'out' / f'{name}.out').write_text(oracle(text))


def build():
    write('2_edges', [
        ('(a)', ['', 'a', 'b', 'aa']),
        ('(b)', ['b', 'a', '']),
        ('(a*)', ['', 'a', 'aaaa', 'b', 'aab']),
        ('(a|b)', ['a', 'b', '', 'ab']),
        ('(a.b)', ['ab', 'a', 'ba', '']),
    ])
    write('3_wide', [
        ('((a*).(b*))', ['a' * 50, 'b' * 50, 'a' * 25 + 'b' * 25, 'b' * 25 + 'a' * 25, '']),
        ('(((a|b)*).(a*))', ['a' * 50, 'b' * 50, 'ab' * 25, 'ba' * 25]),
    ])
    rng = random.Random(20261126)

    def random_pattern(depth):
        if depth == 0 or rng.random() < 0.35:
            return rng.choice(['(a)', '(b)'])
        operation = rng.choice(['.', '|', '*'])
        if operation == '*':
            return '(' + random_pattern(depth - 1) + '*)'
        return '(' + random_pattern(depth - 1) + operation + random_pattern(depth - 1) + ')'

    cases = []
    for _ in range(8):
        pattern = random_pattern(3)
        words = [''.join(rng.choice('ab') for _ in range(rng.randint(0, 12))) for _ in range(10)]
        cases.append((pattern, words))
    write('4_random', cases)
    io_cases = []
    for _ in range(12):
        pattern = rng.choice(['(a*)', '(a.b)', '((a*).(b*))', '(a|b)'])
        words = [''.join(rng.choice('ab') for _ in range(rng.randint(0, 20))) for _ in range(100)]
        io_cases.append((pattern, words))
    write('5_io', io_cases)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUT)
build()
