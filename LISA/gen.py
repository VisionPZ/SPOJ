#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LARGEST = (1 << 64) - 1


def digits_of(segment):
    return [ord(char) - 48 for char in segment if char >= '0' and char <= '9']


def brute(expr):
    numbers = digits_of(expr)
    operators = [char for char in expr if char == '+' or char == '*']
    count = len(numbers)
    memo = {}

    def walk(left, right):
        key = (left, right)
        if key in memo:
            return memo[key]
        if left == right:
            memo[key] = (numbers[left], numbers[left])
            return memo[key]
        lows = []
        highs = []
        for split in range(left, right):
            left_low, left_high = walk(left, split)
            right_low, right_high = walk(split + 1, right)
            if operators[split] == '+':
                lows.append(left_low + right_low)
                highs.append(left_high + right_high)
            else:
                for product in (left_low * right_low, left_low * right_high,
                                left_high * right_low, left_high * right_high):
                    lows.append(product)
                    highs.append(product)
        memo[key] = (min(lows), max(highs))
        return memo[key]

    small, large = walk(0, count - 1)
    return large, small


def closed_form(expr):
    largest = 1
    start = 0
    for pos, char in enumerate(expr):
        if char == '*':
            largest *= sum(digits_of(expr[start:pos]))
            start = pos + 1
    largest *= sum(digits_of(expr[start:]))

    smallest = 0
    start = 0
    for pos, char in enumerate(expr):
        if char == '+':
            term = 1
            for digit in digits_of(expr[start:pos]):
                term *= digit
            smallest += term
            start = pos + 1
    term = 1
    for digit in digits_of(expr[start:]):
        term *= digit
    smallest += term
    return largest, smallest


def oracle(expr):
    if '0' in expr:
        return brute(expr)
    return closed_form(expr)


assert oracle('1+2*3+4*5') == (105, 27)
assert closed_form('1+2+3') == (6, 6)
assert closed_form('2*3*4') == (24, 24)
assert oracle('0*9+9') == (9, 0)

checker = random.Random(7)
for trial in range(200):
    length = checker.randint(1, 8)
    expr = str(checker.randint(1, 9))
    for _ in range(length - 1):
        expr += checker.choice('+*') + str(checker.randint(1, 9))
    assert closed_form(expr) == brute(expr), expr


def write(name, expressions):
    (ROOT / 'in').mkdir(exist_ok=True)
    (ROOT / 'out').mkdir(exist_ok=True)
    input_text = '\n'.join([str(len(expressions))] + list(expressions)) + '\n'
    (ROOT / 'in' / (name + '.txt')).write_text(input_text)
    answers = []
    for expr in expressions:
        large, small = oracle(expr)
        assert 0 <= small <= large <= LARGEST
        answers.append(str(large) + ' ' + str(small))
    (ROOT / 'out' / (name + '.out')).write_text('\n'.join(answers) + '\n')


write('1_sample', ['1+2*3+4*5'])
write('2_edges', ['5', '0', '9', '0*9+9', '1+2*3+4*5', '9*9*9',
                  '0+0', '0*0', '1', '2*0+3*0+4', '9+0*9+9', '0*9*9+0'])

wide = ['+'.join(['9'] * 50), '+'.join(['1'] * 50), '*'.join(['1'] * 50),
        '+'.join(str((index % 9) + 1) for index in range(50))]
mixed = []
for index in range(50):
    mixed.append(('+' if index % 2 == 0 else '*') + '1')
wide.append('1' + ''.join(mixed))
write('3_wide', wide)

rng = random.Random(20261125)
random_exprs = []
while len(random_exprs) < 200:
    length = rng.randint(1, 25)
    expr = str(rng.randint(0, 9))
    for _ in range(length - 1):
        expr += rng.choice('+*') + str(rng.randint(0, 9))
    large, small = oracle(expr)
    if large <= LARGEST:
        random_exprs.append(expr)
write('4_random', random_exprs)

io_exprs = ['*'.join(['9'] * 20) for _ in range(4999)]
write('5_io', io_exprs)

print('generated', len(io_exprs), 'io cases')
