#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse_signed(bits):
    value = int(bits, 2)
    if bits and bits[0] == '1':
        value -= 1 << len(bits)
    return value


def oracle(text):
    lines = text.split()
    cursor = 0
    answers = []
    while True:
        width = int(lines[cursor]); cursor += 1
        if width == 0:
            break
        first_bits = lines[cursor]; cursor += 1
        second_bits = lines[cursor]; cursor += 1
        product = parse_signed(first_bits) * parse_signed(second_bits)
        if product < -(1 << (width - 1)) or product >= (1 << (width - 1)):
            answers.append('overflow')
        else:
            answers.append(format(product % (1 << width), '0{}b'.format(width)))
    return ''.join(answer + '\n' for answer in answers)


SAMPLE_IN = '''3
110
011
4
0011
1110
0
'''
SAMPLE_OUT = '''overflow
1010
'''
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle('1\n1\n1\n0\n') == 'overflow\n'
assert oracle('1\n1\n0\n0\n') == '0\n'
assert oracle('2\n11\n11\n0\n') == '01\n'
assert oracle('4\n0100\n0100\n0\n') == 'overflow\n'
assert parse_signed('1110') == -2


def write(name, cases):
    text = ''.join('{}\n{}\n{}\n'.format(width, first, second)
                   for width, first, second in cases) + '0\n'
    (ROOT / 'in' / '{}.txt'.format(name)).write_text(text)
    (ROOT / 'out' / '{}.out'.format(name)).write_text(oracle(text))


def build():
    write('2_edges', [
        (1, '0', '0'), (1, '1', '1'), (2, '11', '11'), (2, '10', '11'),
        (3, '100', '111'), (3, '101', '101'), (4, '1000', '1111'),
        (5, '11111', '11111'),
    ])
    write('3_wide', [
        (64, '1' * 64, '0' * 63 + '1'),
        (64, '0' * 63 + '1', '0' * 63 + '1'),
        (127, '1' + '0' * 126, '0' * 126 + '1'),
    ])
    rng = random.Random(20261126)
    cases = []
    for _ in range(40):
        width = rng.randint(1, 64)
        cases.append((width,
                      ''.join(rng.choice('01') for _ in range(width)),
                      ''.join(rng.choice('01') for _ in range(width))))
    write('4_random', cases)
    cases = []
    for _ in range(30):
        width = 1024
        first = [0] * width
        second = [0] * width
        for array in (first, second):
            for _ in range(rng.randint(1, 3)):
                array[rng.randrange(width)] = 1
        cases.append((width, ''.join(map(str, first)), ''.join(map(str, second))))
    write('5_io', cases)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE_IN)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUT)
build()
