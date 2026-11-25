#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCALE = 1000000
MAX_TOTAL = 2000
PRODUCT_LIMIT = 2000000000


def format_cents(amount):
    return f'{amount // 100}.{amount % 100:02d}'


def oracle(max_total=MAX_TOTAL):
    solutions = set()
    for first in range(1, max_total + 1):
        if first ** 4 > PRODUCT_LIMIT:
            break
        for second in range(first, max_total + 1):
            if first * second ** 3 > PRODUCT_LIMIT:
                break
            for fourth in range(second, max_total + 1):
                if first * second ** 2 * fourth > PRODUCT_LIMIT:
                    break
                divisor = first * second * fourth - SCALE
                if divisor <= 0:
                    continue
                numerator = SCALE * (first + second + fourth)
                if numerator % divisor:
                    continue
                third = numerator // divisor
                if third < second or third > fourth:
                    continue
                total = first + second + third + fourth
                if total > max_total:
                    continue
                if first * second * third * fourth != SCALE * total:
                    continue
                solutions.add((first, second, third, fourth))
    ordered = sorted(solutions)
    return ''.join(' '.join(format_cents(value) for value in row) + '\n'
                   for row in ordered)


def brute_force(max_total):
    found = set()
    for first in range(1, max_total + 1):
        for second in range(first, max_total + 1):
            for third in range(second, max_total + 1):
                for fourth in range(third, max_total + 1):
                    total = first + second + third + fourth
                    if total > max_total:
                        break
                    if first * second * third * fourth == SCALE * total:
                        found.add((first, second, third, fourth))
    ordered = sorted(found)
    return ''.join(' '.join(format_cents(value) for value in row) + '\n'
                   for row in ordered)


SAMPLE_LINES = [
    '0.50 1.00 2.50 16.00',
    '1.25 1.60 1.75 1.84',
    '1.25 1.40 1.86 2.00',
]
FULL_OUTPUT = oracle()
assert all(line in FULL_OUTPUT for line in SAMPLE_LINES)
assert oracle(200) == brute_force(200)
assert oracle(60) == brute_force(60)
assert format_cents(50) == '0.50'
assert format_cents(1600) == '16.00'
assert len(FULL_OUTPUT.splitlines()) == 949


def write(name, input_text):
    (ROOT / 'in' / f'{name}.txt').write_text(input_text)
    (ROOT / 'out' / f'{name}.out').write_text(FULL_OUTPUT)


def build():
    write('2_edges', '')
    write('3_wide', '')
    write('4_random', '')


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
write('1_sample', '')
build()
write('5_io', '')
