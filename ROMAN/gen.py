#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

DIGIT_WORDS = {
    'ZERO': 0, 'OH': 0, 'ONE': 1, 'TWO': 2, 'THREE': 3, 'FOUR': 4,
    'FIVE': 5, 'SIX': 6, 'SEVEN': 7, 'EIGHT': 8, 'NINE': 9, 'NINER': 9,
}
WORD_OF_DIGIT = ['ZERO', 'ONE', 'TWO', 'THREE', 'FOUR',
                 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE']
BASE_VALUE = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000}

PLACE_INFO = [
    ('I', 'I', 'V', 'X', ' ', ' ', ' ', ' '),
    ('X', 'X', 'L', 'C', ' ', ' ', ' ', ' '),
    ('C', 'C', 'D', 'M', ' ', ' ', ' ', ' '),
    ('M', 'I', 'V', 'X', ' ', '_', '_', '_'),
    ('X', 'X', 'L', 'C', '_', '_', '_', '_'),
    ('C', 'C', 'D', 'M', '_', '_', '_', '_'),
    ('M', 'i', 'v', 'x', '_', ' ', ' ', ' '),
    ('x', 'x', 'l', 'c', ' ', ' ', ' ', ' '),
    ('c', 'c', 'd', 'm', ' ', ' ', ' ', ' '),
    ('m', 'i', 'v', 'x', ' ', '_', '_', '_'),
]


def spell(value):
    if value == 0:
        return 'ZERO'
    reversed_digits = []
    while value:
        reversed_digits.append(value % 10)
        value //= 10
    return ' '.join(WORD_OF_DIGIT[d] for d in reversed(reversed_digits))


def parse_input(text):
    values = []
    for line in text.splitlines():
        words = line.split()
        if not words:
            continue
        value = 0
        for word in words:
            value = value * 10 + DIGIT_WORDS[word]
        values.append(value)
    return values


def fragment(place, digit):
    one, alt, five, ten, bar_one, bar_alt, bar_five, bar_ten = PLACE_INFO[place]
    if digit == 0:
        return '', ''
    if digit < 4:
        return one * digit, bar_one * digit
    if digit == 4:
        return alt + five, bar_alt + bar_five
    if digit == 5:
        return five, bar_five
    if digit < 9:
        return five + alt * (digit - 5), bar_five + bar_alt * (digit - 5)
    return alt + ten, bar_alt + bar_ten


def to_roman(value):
    if value == 0:
        return '_', ''
    reversed_digits = []
    while value:
        reversed_digits.append(value % 10)
        value //= 10
    numerals = []
    bars = []
    for place in range(len(reversed_digits) - 1, -1, -1):
        part_numeral, part_bar = fragment(place, reversed_digits[place])
        numerals.append(part_numeral)
        bars.append(part_bar)
    return ''.join(bars), ''.join(numerals)


def decode(bars, numerals):
    scaled = []
    for char, bar in zip(numerals, bars):
        factor = 1
        if char.islower():
            factor *= 1000000
        if bar == '_':
            factor *= 1000
        scaled.append(BASE_VALUE[char.upper()] * factor)
    total = 0
    for i, value in enumerate(scaled):
        if i + 1 < len(scaled) and scaled[i + 1] > value:
            total -= value
        else:
            total += value
    return total


def oracle(text):
    values = parse_input(text)
    case_count = values[0]
    lines = []
    for value in values[1:1 + case_count]:
        bars, numerals = to_roman(value)
        lines.append(bars + '\n' + numerals + '\n')
    return ''.join(lines)


def write(name, numbers):
    input_text = spell(len(numbers)) + '\n' + ''.join(
        spell(value) + '\n' for value in numbers)
    (ROOT / 'in' / f'{name}.txt').write_text(input_text)
    (ROOT / 'out' / f'{name}.out').write_text(oracle(input_text))


SAMPLE_INPUT = ('THREE\n'
                'FOUR OH\n'
                'ONE NINE NINE NINE NINE NINE NINE NINE NINE NINE\n'
                'ONE TWO THREE ZERO FOUR FIVE\n')
SAMPLE_OUTPUT = ('  \nXL\n'
                 '       ______      \n'
                 'mcmxcixCMXCIXCMXCIX\n'
                 '___      \n'
                 'CXXMMMXLV\n')

assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert to_roman(3999) == (' ' * 9, 'MMMCMXCIX')
assert to_roman(4000) == ('__', 'IV')
assert to_roman(123045) == ('___      ', 'CXXMMMXLV')
assert to_roman(4294967295) == ('__      _______     ',
                                'ivccxcivCMLXVIICCXCV')
for probe in range(0, 10000):
    assert decode(*to_roman(probe)) == probe
random.seed(7)
for _ in range(5000):
    probe = random.randint(0, 4294967295)
    assert decode(*to_roman(probe)) == probe


def build():
    write('2_edges', [0, 1, 3999, 4000, 999999, 1000000, 4000000,
                      4294967295, 123045, 40, 0, 1999999999])
    write('3_wide', [0, 4294967295] * 20)
    random.seed(2026)
    write('4_random', [random.randint(0, 4294967295) for _ in range(200)])
    write('5_io', [4294967295] * 3000)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE_INPUT)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUTPUT)
build()
