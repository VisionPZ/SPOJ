#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def evaluate(expression, assignment):
    stack = []
    for symbol in reversed(expression):
        if 'a' <= symbol <= 'z':
            stack.append(assignment[symbol])
        elif symbol == 'N':
            stack.append(not stack.pop())
        else:
            first = stack.pop()
            second = stack.pop()
            if symbol == 'C':
                stack.append(first and second)
            elif symbol == 'D':
                stack.append(first or second)
            elif symbol == 'I':
                stack.append((not first) or second)
            elif symbol == 'E':
                stack.append(first == second)
    return stack[0]


def parse_recursive(expression, position, assignment):
    symbol = expression[position]
    position += 1
    if 'a' <= symbol <= 'z':
        return assignment[symbol], position
    if symbol == 'N':
        value, position = parse_recursive(expression, position, assignment)
        return not value, position
    first, position = parse_recursive(expression, position, assignment)
    second, position = parse_recursive(expression, position, assignment)
    if symbol == 'C':
        return first and second, position
    if symbol == 'D':
        return first or second, position
    if symbol == 'I':
        return (not first) or second, position
    if symbol == 'E':
        return first == second, position
    raise ValueError('bad symbol ' + symbol)


def oracle_expression(expression):
    variables = sorted(set(c for c in expression if 'a' <= c <= 'z'))
    names = {name: index for index, name in enumerate(variables)}
    for mask in range(1 << len(names)):
        assignment = {name: bool((mask >> index) & 1) for name, index in names.items()}
        if not evaluate(expression, assignment):
            return 'NO'
    return 'YES'


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    expressions = tokens[1:1 + count]
    assert len(expressions) == count
    return '\n'.join(oracle_expression(e) for e in expressions) + '\n'


def write(name, expressions):
    input_text = str(len(expressions)) + '\n' + ''.join(e + '\n' for e in expressions)
    for expression in expressions:
        assert 1 <= len(expression) <= 111
        assert len(set(c for c in expression if 'a' <= c <= 'z')) <= 16
    (ROOT / 'in' / (name + '.txt')).write_text(input_text)
    (ROOT / 'out' / (name + '.out')).write_text(oracle(input_text))


def random_expression(rng, max_length, pool, depth=9):
    tokens = []
    pending = [depth]
    while pending:
        level = pending.pop()
        need = len(tokens) + len(pending)
        chance = rng.random()
        if level <= 0 or chance < 0.32 or need + 3 > max_length:
            tokens.append(rng.choice(pool))
        elif chance < 0.46 and need + 2 <= max_length:
            tokens.append('N')
            pending.append(level - 1)
        elif need + 3 <= max_length:
            tokens.append(rng.choice('CDIE'))
            pending.append(level - 1)
            pending.append(level - 1)
        else:
            tokens.append(rng.choice(pool))
    return ''.join(tokens)


SAMPLE = [
    'IIpqDpNp',
    'NCNpp',
    'Iaz',
    'NNNNNNNp',
    'IIqrIIpqIpr',
    'Ipp',
    'Ezz',
]
SAMPLE_EXPECTED = 'YES\nYES\nNO\nNO\nYES\nYES\nYES\n'
SAMPLE_TEXT = '7\n' + ''.join(e + '\n' for e in SAMPLE)

assert oracle(SAMPLE_TEXT) == SAMPLE_EXPECTED
assert oracle_expression('Ipp') == 'YES'
assert oracle_expression('Cpq') == 'NO'
assert oracle_expression('DpNp') == 'YES'
assert oracle_expression('IIqrIIpqIpr') == 'YES'
assert oracle_expression('NCNpp') == 'YES'
assert oracle_expression('p') == 'NO'

rng = random.Random(147)
for trial in range(300):
    candidates = 'abcdef'
    expression = random_expression(rng, 12, candidates, depth=4)
    variables = sorted(set(c for c in expression if 'a' <= c <= 'z'))
    names = {name: index for index, name in enumerate(variables)}
    for mask in range(1 << len(names)):
        assignment = {name: bool((mask >> index) & 1) for name, index in names.items()}
        fast = evaluate(expression, assignment)
        slow, end = parse_recursive(expression, 0, assignment)
        assert end == len(expression)
        assert fast == slow


def implication_chain(letters):
    chain = ''
    for letter in letters[:-1]:
        chain += 'I' + letter
    return chain + letters[-1]


def build():
    letters = 'abcdefghijklmnop'
    chain = implication_chain(letters)
    edges = [
        'CpNp',
        'Ipp',
        'NCNpp',
        'NNp',
        'NNNp',
        'DpNp',
        'Eaa',
        'IIpqDqNq',
        chain,
        'E' + chain + chain,
    ]
    write('2_edges', edges)

    wide = [random_expression(rng, 111, 'abcdefgh') for _ in range(35)]
    write('3_wide', wide)

    random.seed(2026)
    randomCases = []
    for _ in range(35):
        pool = 'abcdef'
        randomCases.append(random_expression(rng, rng.randint(1, 70), pool, depth=7))
    write('4_random', randomCases)

    ioCases = [random_expression(rng, 111, 'abcdefgh') for _ in range(35)]
    write('5_io', ioCases)


def worked_example():
    expression = 'IIpqDpNp'
    print('p q | I p q | D p N p | whole')
    for left in (0, 1):
        for right in (0, 1):
            assignment = {'p': bool(left), 'q': bool(right)}
            implication = evaluate('Ipq', assignment)
            disjunction = evaluate('DpNp', assignment)
            whole = evaluate(expression, assignment)
            print('{} {} |   {}   |    {}    |   {}'.format(
                left, right, int(implication), int(disjunction), int(whole)))


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
write('1_sample', SAMPLE)
build()
if __name__ == '__main__':
    worked_example()
