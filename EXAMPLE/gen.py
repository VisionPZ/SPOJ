#!/usr/bin/env python3
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent

WORDS = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight',
         'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
         'sixteen', 'seventeen', 'eighteen', 'nineteen']
TENS = {20: 'twenty', 30: 'thirty', 40: 'forty', 50: 'fifty', 60: 'sixty',
        70: 'seventy', 80: 'eighty', 90: 'ninety'}
VALUE = {word: index for index, word in enumerate(WORDS)}
VALUE.update({word: number for number, word in TENS.items()})
TOKEN_PATTERN = re.compile(r'"[^"]*"|\'[^\']*\'|[A-Za-z]+|\.')


def number_word(value):
    if value < 20:
        return WORDS[value]
    tens = value // 10 * 10
    units = value % 10
    return TENS[tens] + (' ' + WORDS[units] if units else '')


def fragment(factor, kind, obj):
    if kind == 'n':
        text = ' '.join(str(obj) for _ in range(factor))
        designator = (number_word(factor) + ' numbers') if factor > 1 else 'number'
        description = designator + ' ' + number_word(obj)
    elif kind == 's':
        text = obj * factor
        quote = '"' if "'" in obj else "'"
        designator = (number_word(factor) + ' strings') if factor > 1 else 'string'
        description = designator + ' ' + quote + obj + quote
    else:
        text = ' ' * factor
        description = (number_word(factor) + ' spaces') if factor > 1 else 'space'
    return description, text, kind


def needs_space(previous_kind, current_kind):
    return ((previous_kind == 'n' and current_kind in ('n', 's')) or
            (previous_kind == 's' and current_kind == 'n'))


def sentence_for(count, fragments, first, empty):
    if empty:
        verb = 'is' if count == 1 else 'are'
        head = 'The first line' if first else (
            'The next line' if count == 1 else 'The next ' + number_word(count) + ' lines')
        return head + ' ' + verb + ' empty.'
    pieces = [fragment(*item) for item in fragments]
    body = ''
    for index, piece in enumerate(pieces):
        if index > 0 and needs_space(pieces[index - 1][2], piece[2]):
            body += ' '
        body += piece[1]
    designators = ' followed by '.join(piece[0] for piece in pieces)
    head = 'The first line' if first else (
        'The next line' if count == 1 else 'The next ' + number_word(count) + ' lines')
    verb = 'contains' if count == 1 else 'contain'
    return head + ' ' + verb + ' ' + designators + '.', body


def build_case(groups):
    sentences = []
    expected_lines = []
    first = True
    for count, fragments in groups:
        if fragments is None:
            sentences.append(sentence_for(count, None, first, True))
            expected_lines.extend([''] * count)
        else:
            sentence, body = sentence_for(count, fragments, first, False)
            sentences.append(sentence)
            expected_lines.extend([body] * count)
        first = False
    return sentences, '\n'.join(expected_lines) + '\n'


def tokens_of(sentences):
    tokens = []
    for sentence in sentences:
        tokens.extend(TOKEN_PATTERN.findall(sentence))
    return tokens


def random_text(sentences, rng):
    tokens = tokens_of(sentences)
    text = ''
    for index, token in enumerate(tokens):
        if index > 0:
            text += rng.choice([' ', ' ', '\n', '  ', '\n  '])
        text += token
    return text + '\n'


def decode(text):
    tokens = TOKEN_PATTERN.findall(text)
    sentences = []
    current = []
    for token in tokens:
        if token == '.':
            sentences.append(current)
            current = []
        elif token.startswith(('"', "'")):
            current.append(('s', token[1:-1]))
        else:
            current.append(('w', token.lower()))
    if current:
        sentences.append(current)

    def read_number(cursor):
        value = VALUE.get(sentences_cursor[cursor][1], -1)
        cursor += 1
        if value >= 20 and cursor < len(sentences_cursor):
            second = VALUE.get(sentences_cursor[cursor][1], -1)
            if 0 < second < 10:
                cursor += 1
                value += second
        return value, cursor

    lines = []
    for sentences_cursor in sentences:
        if not sentences_cursor:
            continue
        cursor = 0
        if sentences_cursor[cursor][1] == 'the':
            cursor += 1
        count = 1
        if sentences_cursor[cursor][1] == 'next':
            cursor += 1
            if sentences_cursor[cursor][1] == 'line':
                cursor += 1
            else:
                count, cursor = read_number(cursor)
                cursor += 1
        elif sentences_cursor[cursor][1] == 'first':
            cursor += 1
            cursor += 1
        if sentences_cursor[cursor][1] in ('is', 'are'):
            lines.extend([''] * count)
            continue
        cursor += 1
        pieces = []
        while cursor < len(sentences_cursor):
            probe, after_probe = read_number(cursor)
            if probe > 1 and after_probe < len(sentences_cursor) and \
                    sentences_cursor[after_probe][1] in ('numbers', 'strings', 'spaces'):
                factor = probe
                designator = sentences_cursor[after_probe][1]
                cursor = after_probe + 1
            else:
                factor = 1
                designator = sentences_cursor[cursor][1]
                cursor += 1
            if designator in ('number', 'numbers'):
                value, cursor = read_number(cursor)
                content = ' '.join([str(value)] * factor)
                kind = 'n'
            elif designator in ('string', 'strings'):
                content = sentences_cursor[cursor][1] * factor
                cursor += 1
                kind = 's'
            else:
                content = ' ' * factor
                kind = 'p'
            pieces.append((kind, content))
            if cursor < len(sentences_cursor) and sentences_cursor[cursor][1] == 'followed':
                cursor += 2
            else:
                break
        line = ''
        for index, piece in enumerate(pieces):
            if index > 0 and needs_space(pieces[index - 1][0], piece[0]):
                line += ' '
            line += piece[1]
        lines.extend([line] * count)
    return '\n'.join(lines) + '\n'


def oracle(text):
    return decode(text)


SAMPLE = """The first line contains four
numbers twenty eight. The next
line is empty. The next two
lines contain six strings '-'.
The next line contains number
four followed by number seventy
seven followed by string 'meat'
followed by three strings "!".
"""
SAMPLE_OUT = """28 28 28 28

------
------
4 77 meat!!!
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("The first line is empty.\n") == "\n"
assert oracle("The first line contains number zero.\n") == "0\n"
assert oracle("The first line contains two spaces followed by number nine.\n") == "  9\n"
assert oracle("The first line contains twenty one strings 'A'.\n") == "A" * 21 + "\n"
assert oracle("The first line contains number five followed by string 'x' followed by number six.\n") == "5 x 6\n"


def write(name, sentences, rng):
    text = random_text(sentences, rng)
    expected = oracle(text)
    (ROOT / 'in' / (name + '.txt')).write_text(text)
    (ROOT / 'out' / (name + '.out')).write_text(expected)
    return expected


def build(rng):
    write('2_edges', [
        'The first line is empty.',
        'The next line contains number zero.',
        'The next three lines are empty.',
        'The next two lines contain space.',
        'The next line contains number ninety nine followed by string "a.b".',
    ], rng)
    wide_groups = [
        (1, [(21, 's', 'A'), (2, 'n', 28), (65, 'p', None)]),
        (2, [(11, 'n', 77), (3, 's', '-'), (4, 's', '5" tall')]),
        (1, [(1, 'n', 0), (20, 'n', 17), (1, 's', "John's")]),
    ]
    sentences, expected = build_case(wide_groups)
    assert oracle(random_text(sentences, rng)) == expected
    write('3_wide', sentences, rng)
    random_sentences = []
    for _ in range(12):
        groups = []
        for group_index in range(rng.randint(1, 4)):
            count = 1 if group_index == 0 else rng.randint(1, 4)
            if rng.random() < 0.2:
                groups.append((count, None))
                continue
            fragments = []
            for _ in range(rng.randint(1, 4)):
                kind = rng.choice('nsp')
                factor = rng.choice([1, 2, 3, 4, 6, 11, 20, 21, 65])
                if kind == 'n':
                    obj = rng.choice([0, 1, 5, 17, 28, 77, 99])
                elif kind == 's':
                    obj = rng.choice(['-', 'A', '!', 'meat', "John's", '5" tall', 'a.b'])
                else:
                    obj = None
                fragments.append((factor, kind, obj))
            groups.append((count, fragments))
        part, exp = build_case(groups)
        random_sentences.extend(part)
        assert oracle(random_text(part, rng)) == exp
    write('4_random', random_sentences, rng)
    io_sentences = []
    for _ in range(600):
        groups = []
        for count in (1, 3):
            fragments = []
            for _ in range(3):
                kind = rng.choice('nsp')
                obj = rng.choice([7, 42, 88]) if kind == 'n' else ('A' if kind == 's' else None)
                fragments.append((rng.choice([1, 2, 6, 21]), kind, obj))
            groups.append((count, fragments))
        part, exp = build_case(groups)
        io_sentences.extend(part)
        assert oracle(random_text(part, rng)) == exp
    write('5_io', io_sentences, rng)
    stress_groups = []
    for _ in range(2800):
        for count in (1, 3):
            fragments = []
            for _ in range(5):
                kind = rng.choice('nsp')
                obj = rng.choice([7, 42, 88]) if kind == 'n' else ('A' if kind == 's' else None)
                fragments.append((rng.randint(1, 9), kind, obj))
            stress_groups.append((count, fragments))
    stress_sentences, _ = build_case(stress_groups)
    Path('/tmp/EXAMPLE_big.txt').write_text(random_text(stress_sentences, rng))


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
rng = random.Random(20261126)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE)
(ROOT / 'out' / '1_sample.out').write_text(oracle(SAMPLE))
build(rng)
