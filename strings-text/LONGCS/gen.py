#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse(text):
    values = text.split()
    if not values:
        return []
    position = 0
    case_count = int(values[position])
    position += 1
    cases = []
    for _ in range(case_count):
        count = int(values[position])
        position += 1
        strings = values[position:position + count]
        position += count
        cases.append(strings)
    return cases


def longest_common(strings):
    low, high = 0, min(len(text) for text in strings)
    best = 0
    while low <= high:
        middle = (low + high) // 2
        if middle == 0:
            works = True
        else:
            sets = [set(text[index:index + middle] for index in range(len(text) - middle + 1))
                    for text in strings]
            works = bool(set.intersection(*sets))
        if works:
            best = middle
            low = middle + 1
        else:
            high = middle - 1
    return best


def oracle(text):
    return ''.join(str(longest_common(strings)) + '\n' for strings in parse(text))


SAMPLE = """2
2
aaabbb
bbaabb
3
icode
coder
contest
"""
SAMPLE_OUT = """4
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert longest_common(['abc', 'abc', 'abc']) == 3
assert longest_common(['abc', 'def']) == 0
assert longest_common(['aaaa', 'aa']) == 2
assert longest_common(['xyzabc', 'abcxyz']) == 3


def render(cases):
    blocks = [str(len(cases))]
    for strings in cases:
        blocks.append(str(len(strings)))
        blocks.extend(strings)
    return '\n'.join(blocks) + '\n'


def write(name, cases):
    text = render(cases)
    (ROOT / 'in' / f'{name}.txt').write_text(text)
    (ROOT / 'out' / f'{name}.out').write_text(oracle(text))


def build():
    write('2_edges', [
        ['alone'],
        ['aaaa', 'aaaa'],
        ['abcdef', 'xyz'],
        ['abcabc', 'bcabc', 'abc'],
    ])
    write('3_wide', [
        ['a' * 300, 'a' * 250 + 'b' + 'a' * 49],
        ['ab' * 150, 'ba' * 150, 'ab' * 100 + 'ba' * 50],
    ])
    rng = random.Random(20261126)
    cases = []
    for _ in range(10):
        count = rng.randint(1, 8)
        template = ''.join(rng.choice('abcde') for _ in range(rng.randint(8, 60)))
        strings = []
        for _ in range(count):
            letters = list(template)
            for _ in range(rng.randint(0, 6)):
                position = rng.randrange(len(letters))
                letters[position] = rng.choice('abcde')
            strings.append(''.join(letters))
        cases.append(strings)
    write('4_random', cases)
    io_cases = []
    for _ in range(60):
        template = ''.join(rng.choice('abc') for _ in range(12))
        io_cases.append([template, template[:8] + 'abc', template[2:]])
    write('5_io', io_cases)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUT)
build()
