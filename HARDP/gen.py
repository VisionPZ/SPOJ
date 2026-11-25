#!/usr/bin/env python3
import math
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def build_polynomials():
    polynomials = [[Fraction(0), Fraction(1)]]
    for degree in range(1, 51):
        current = [Fraction(0)] + [degree * value for value in polynomials[-1]]
        linear = Fraction(1)
        for index in range(2, len(current)):
            current[index] = current[index] / index
            linear -= current[index]
        current[1] = linear
        polynomials.append(current)
    denominators = []
    for degree in range(51):
        denominator = math.lcm(*(value.denominator for value in polynomials[degree]))
        denominators.append(denominator)
        polynomials[degree] = [(value * denominator).numerator for value in polynomials[degree]]
    return polynomials, denominators


POLYNOMIALS, DENOMINATORS = build_polynomials()


def answer(value):
    terms = ''.join(f'{POLYNOMIALS[value][index]:+d}'
                    for index in range(2, value + 2, 2))
    terms += ''.join(f'{POLYNOMIALS[value][index]:+d}'
                     for index in range(1, value + 2, 2))
    return f'{value}={DENOMINATORS[value]}*(0{terms})'


def oracle(text):
    values = [int(token) for token in text.split()]
    return ''.join(answer(value) + '\n' for value in values)


SAMPLE_IN = '8\n9\n10\n'
SAMPLE_OUT = ('''8=90*(0+0+0+0+45-3+20-42+60+10)
9=20*(0-3+10-14+15+2+0+0+0+0+10)
10=66*(0+0+0+0+0+33+5-33+66-66+55+6)
''')
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert answer(1) == '1=2*(0+1+1)'
assert answer(2) == '2=6*(0+3+1+2)'
assert answer(50).startswith('50=43758*(0')
assert len(oracle(''.join(f'{value}\n' for value in range(1, 51))).splitlines()) == 50


def write(name, values):
    text = ''.join(f'{value}\n' for value in values)
    (ROOT / 'in' / f'{name}.txt').write_text(text)
    (ROOT / 'out' / f'{name}.out').write_text(oracle(text))


def build():
    write('2_edges', [1, 2, 3, 50])
    write('3_wide', list(range(1, 51)))
    rng = random.Random(20261126)
    write('4_random', [rng.randint(1, 50) for _ in range(200)])
    write('5_io', list(range(1, 51)) * 40)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
write('1_sample', [8, 9, 10])
build()
