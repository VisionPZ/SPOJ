#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TARGETS = [137, 1315, 73, 136, 255, 1384, 16385]


def oracle_number(value):
    if value == 0:
        return '0'
    if value == 1:
        return '2(0)'
    if value == 2:
        return '2'
    terms = []
    remainder = value
    powers = []
    while remainder:
        powers.append(remainder % 2)
        remainder //= 2
    exponent = len(powers) - 1
    for bit in reversed(powers):
        if bit:
            if exponent == 1:
                terms.append('2')
            elif exponent == 0:
                terms.append('2(0)')
            else:
                terms.append('2(' + oracle_number(exponent) + ')')
        exponent -= 1
    return '+'.join(terms)


def oracle():
    return ''.join(f'{value}={oracle_number(value)}\n' for value in TARGETS)


def evaluate(text):
    if text == '0':
        return 0
    position = 0
    total = 0
    while position < len(text):
        assert text[position] == '2'
        position += 1
        if position < len(text) and text[position] == '(':
            position += 1
            depth = 1
            start = position
            while depth:
                if text[position] == '(':
                    depth += 1
                elif text[position] == ')':
                    depth -= 1
                if depth:
                    position += 1
            exponent_text = text[start:position]
            position += 1
            total += 2 ** evaluate(exponent_text)
        else:
            total += 2
        if position < len(text):
            assert text[position] == '+'
            position += 1
    return total


FULL_OUTPUT = oracle()
assert FULL_OUTPUT.splitlines()[0] == '137=2(2(2)+2+2(0))+2(2+2(0))+2(0)'
assert FULL_OUTPUT.splitlines()[1] == ('1315=2(2(2+2(0))+2)+2(2(2+2(0)))'
                                       '+2(2(2)+2(0))+2+2(0)')
assert len(FULL_OUTPUT.splitlines()) == 7
assert evaluate(oracle_number(137)) == 137
assert evaluate(oracle_number(1315)) == 1315
assert all(evaluate(oracle_number(value)) == value for value in range(1, 300))
assert oracle_number(0) == '0' and oracle_number(2) == '2'


def write(name):
    (ROOT / 'in' / f'{name}.txt').write_text('')
    (ROOT / 'out' / f'{name}.out').write_text(FULL_OUTPUT)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
for case_name in ['1_sample', '2_edges', '3_wide', '4_random', '5_io']:
    write(case_name)
