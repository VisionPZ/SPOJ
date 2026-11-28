#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_COEFFICIENT = 30000
MAX_DEGREE = 6
SAMPLE_INPUT = "2\nx^4-6*x^3+11*x^2-6*x\n-x^2+2*x-1\n"
SAMPLE_OUTPUT = "0.00 1.00 2.00 3.00\n1.00 1.00\n"


def expand_roots(roots, leading=1):
    coefficients = [leading]
    for root in roots:
        shifted = [0] * (len(coefficients) + 1)
        for power, coefficient in enumerate(coefficients):
            shifted[power + 1] += coefficient
            shifted[power] -= coefficient * root
        coefficients = shifted
    return coefficients


def format_term(coefficient, degree, first):
    sign = '-' if coefficient < 0 else '+'
    magnitude = abs(coefficient)
    if degree == 0:
        body = str(magnitude)
    else:
        body = ''
        if magnitude != 1:
            body += str(magnitude) + '*'
        body += 'x'
        if degree != 1:
            body += '^' + str(degree)
    return ('' if first and sign == '+' else sign) + body


def format_polynomial(coefficients):
    text = ''
    first = True
    for degree in range(len(coefficients) - 1, -1, -1):
        if coefficients[degree] == 0:
            continue
        text += format_term(coefficients[degree], degree, first)
        first = False
    return text if text else '0'


def expected_output(roots):
    return ' '.join(f'{value:.2f}' for value in sorted(roots)) + '\n'


def make_case(roots, leading=1):
    assert len(roots) <= MAX_DEGREE + 1
    expanded = expand_roots(roots, leading)
    assert all(abs(value - round(value)) < 1e-6 for value in expanded)
    coefficients = [int(round(value)) for value in expanded]
    assert len(coefficients) <= MAX_DEGREE + 1
    assert any(value != 0 for value in coefficients)
    assert all(abs(value) <= MAX_COEFFICIENT for value in coefficients)
    for root in roots:
        value = coefficients[-1]
        for power in range(len(coefficients) - 2, -1, -1):
            value = value * root + coefficients[power]
        assert abs(value) < 1e-4 * max(1.0, sum(abs(c) for c in coefficients))
    return format_polynomial(coefficients), expected_output(roots)


def quadratic_pair(value):
    return [math.sqrt(value), -math.sqrt(value)]


def write(name, cases):
    input_text = str(len(cases)) + '\n' + ''.join(text + '\n' for text, _ in cases)
    output_text = ''.join(answer for _, answer in cases)
    (ROOT / 'in' / f'{name}.txt').write_text(input_text)
    (ROOT / 'out' / f'{name}.out').write_text(output_text)


assert expected_output([3, 0, 2, 1]) == '0.00 1.00 2.00 3.00\n'
assert expected_output([1, 1]) == '1.00 1.00\n'
assert expand_roots([0, 1, 2, 3]) == [0, -6, 11, -6, 1]
assert expand_roots([1, 1]) == [1, -2, 1]
assert make_case([0, 1, 2, 3]) == ('x^4-6*x^3+11*x^2-6*x', '0.00 1.00 2.00 3.00\n')
assert make_case([1, 1]) == ('x^2-2*x+1', '1.00 1.00\n')

(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)

(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE_INPUT)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUTPUT)

edge_specs = [
    ([], 1),
    ([0], 1),
    ([-100], 1),
    ([100], 1),
    ([100, 100], 1),
    ([-100, -100], 1),
    ([0, 0, 0], 1),
    ([1, 1], 1),
    (quadratic_pair(2), 1),
    (quadratic_pair(2) + [0], 1),
    ([2, 2, 3, 3], 1),
    ([1, 2, 3], 300),
    ([1, 2, 3], -300),
]
write('2_edges', [make_case(roots, leading) for roots, leading in edge_specs])

wide_specs = [
    ([-8, -5, -2, 1, 4, 7], 1),
    ([-9, -6, -3, 2, 5, 8], 1),
    ([-4, -4, -1, 0, 3, 6], 1),
    (quadratic_pair(2) + quadratic_pair(3), 1),
    (quadratic_pair(5) + [0, 1, 2], 1),
    (quadratic_pair(7) + quadratic_pair(11), 1),
]
write('3_wide', [make_case(roots, leading) for roots, leading in wide_specs])

random.seed(2026)
random_cases = []
while len(random_cases) < 100:
    root_count = random.randint(1, 6)
    roots = [random.randint(-9, 9) for _ in range(root_count)]
    remaining = 6 - root_count
    if remaining >= 2 and random.random() < 0.5:
        roots += quadratic_pair(random.choice([2, 3, 5, 6, 7, 8, 10, 11]))
        remaining -= 2
    if remaining >= 2 and random.random() < 0.3:
        roots += quadratic_pair(random.choice([2, 3, 5, 7]))
        remaining -= 2
    leading = random.choice([1, 1, 1, -1, 2, -2, 5, -5, 10, -10, 25, -25])
    expanded = expand_roots(roots, leading)
    if any(abs(value) > MAX_COEFFICIENT for value in expanded):
        continue
    random_cases.append(make_case(roots, leading))
write('4_random', random_cases)

io_specs = []
for case_index in range(100):
    roots = [case_index % 19 - 9, case_index % 17 - 8, case_index % 13 - 6,
             case_index % 11 - 5, case_index % 7 - 3, case_index % 5 - 2]
    leading = 1 if case_index % 2 == 0 else -1
    io_specs.append(make_case(roots, leading))
write('5_io', io_specs)
