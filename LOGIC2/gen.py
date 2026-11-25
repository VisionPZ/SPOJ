#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']


def parse_cases(text):
    lines = text.splitlines()
    cursor = 0
    cases = []
    while cursor < len(lines):
        while cursor < len(lines) and not lines[cursor].strip():
            cursor += 1
        if cursor >= len(lines):
            break
        person_count, liar_count, sentence_count = map(int, lines[cursor].split())
        cursor += 1
        names = lines[cursor:cursor + person_count]
        cursor += person_count
        speeches = []
        for _ in range(sentence_count):
            speaker, statement = lines[cursor].split(':', 1)
            speeches.append((speaker, statement.strip()))
            cursor += 1
        cases.append((person_count, liar_count, names, speeches))
    return cases


def parse_statement(statement, names):
    if statement == 'I am guilty.':
        return ('self_guilty', -1)
    if statement == 'I am not guilty.':
        return ('self_innocent', -1)
    if statement.startswith('Today is '):
        day = statement[9:-1]
        if day in DAYS:
            return ('day', DAYS.index(day))
        return (None, -1)
    if statement.endswith(' is guilty.'):
        name = statement[:-11]
        if name in names:
            return ('other_guilty', names.index(name))
    if statement.endswith(' is not guilty.'):
        name = statement[:-15]
        if name in names:
            return ('other_innocent', names.index(name))
    return (None, -1)


def statement_true(kind, target, culprit_index, day_index, speaker_index):
    if kind == 'self_guilty':
        return speaker_index == culprit_index
    if kind == 'self_innocent':
        return speaker_index != culprit_index
    if kind == 'other_guilty':
        return target == culprit_index
    if kind == 'other_innocent':
        return target != culprit_index
    return target == day_index


def oracle(text):
    answers = []
    for person_count, liar_count, names, speeches in parse_cases(text):
        statements = []
        for speaker, statement in speeches:
            kind, target = parse_statement(statement, names)
            if kind is None:
                continue
            statements.append((names.index(speaker), kind, target))
        possible = set()
        for culprit_index, culprit in enumerate(names):
            for day_index in range(7):
                for mask in range(1 << person_count):
                    if mask.bit_count() != liar_count:
                        continue
                    valid = True
                    for speaker_index, kind, target in statements:
                        is_liar = bool(mask & (1 << speaker_index))
                        truth = statement_true(kind, target, culprit_index, day_index, speaker_index)
                        if truth == is_liar:
                            valid = False
                            break
                    if valid:
                        possible.add(culprit)
        if not possible:
            answers.append('Impossible')
        elif len(possible) > 1:
            answers.append('Cannot Determine')
        else:
            answers.append(next(iter(possible)))
    return '\n'.join(answers) + '\n'


def write(name, cases):
    chunks = []
    for person_count, liar_count, names, speeches in cases:
        chunks.append(f'{person_count} {liar_count} {len(speeches)}\n')
        chunks.append(''.join(name + '\n' for name in names))
        chunks.append(''.join(speaker + ': ' + statement + '\n'
                              for speaker, statement in speeches))
    text = ''.join(chunks)
    (ROOT / 'in' / f'{name}.txt').write_text(text)
    (ROOT / 'out' / f'{name}.out').write_text(oracle(text))


SAMPLE = '''3 1 5
MIKE
CHARLES
KATE
MIKE: I am guilty.
MIKE: Today is Sunday.
CHARLES: MIKE is guilty.
KATE: I am guilty.
KATE: How are you??
'''
assert oracle(SAMPLE) == 'MIKE\n'
assert oracle('1 1 1\nA\nA: I am guilty.\n') == 'Impossible\n'
assert oracle('2 1 1\nA\nB\nA: How are you??\n') == 'Cannot Determine\n'
assert oracle('2 0 2\nA\nB\nA: I am not guilty.\nB: A is guilty.\n') == 'Impossible\n'
assert oracle('2 2 2\nA\nB\nA: I am guilty.\nB: I am not guilty.\n') == 'B\n'


def build():
    write('2_edges', [
        (1, 1, ['A'], [('A', 'I am guilty.')]),
        (2, 1, ['A', 'B'], [('A', 'How are you??')]),
        (2, 0, ['A', 'B'], [('A', 'I am not guilty.'), ('B', 'A is guilty.')]),
        (3, 2, ['AL', 'BOB', 'CY'], [('AL', 'BOB is guilty.'), ('BOB', 'Today is Friday.'),
                                    ('CY', 'AL is not guilty.')]),
    ])
    names = ['MIKE', 'CHARLES', 'KATE', 'JOHN', 'ALICE', 'BOB', 'TOM', 'SARA']
    statements = ['I am guilty.', 'I am not guilty.', 'Today is Sunday.',
                  'Today is Monday.', 'How are you??']
    for name in names:
        statements.append(name + ' is guilty.')
        statements.append(name + ' is not guilty.')
    rng = random.Random(20261126)
    write('3_wide', [(8, 3, names[:8], [(rng.choice(names[:8]), rng.choice(statements))
                                       for _ in range(30)])])
    wide = []
    for _ in range(5):
        count = rng.randint(2, 6)
        chosen = names[:count]
        liars = rng.randint(1, count)
        wide.append((count, liars, chosen,
                     [(rng.choice(chosen), rng.choice(statements)) for _ in range(8)]))
    write('4_random', wide)
    many = []
    for _ in range(300):
        count = rng.randint(2, 4)
        chosen = names[:count]
        liars = rng.randint(1, count)
        many.append((count, liars, chosen,
                     [(rng.choice(chosen), rng.choice(statements)) for _ in range(5)]))
    write('5_io', many)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE)
(ROOT / 'out' / '1_sample.out').write_text('MIKE\n')
build()
