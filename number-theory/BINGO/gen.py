#!/usr/bin/env python3
import math
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def is_ascii_letter(character):
    return ('a' <= character <= 'z') or ('A' <= character <= 'Z')


def tokenize(text):
    return re.sub(r'[^A-Za-z]', ' ', text).split()


def oracle(text):
    distinct_words = set()
    completed_games = 0
    total_distinct = 0
    for token in tokenize(text):
        word = token.lower()
        if word == 'bullshit':
            total_distinct += len(distinct_words)
            completed_games += 1
            distinct_words = set()
        else:
            distinct_words.add(word)
    divisor = math.gcd(total_distinct, completed_games)
    return f"{total_distinct // divisor} / {completed_games // divisor}\n"


def hand_gcd(first_value, second_value):
    while second_value > 0:
        first_value, second_value = second_value, first_value % second_value
    return first_value


def brute_oracle(text):
    distinct_words = []
    completed_games = 0
    total_distinct = 0
    position = 0
    text_length = len(text)
    while position < text_length:
        while position < text_length and not is_ascii_letter(text[position]):
            position += 1
        word_start = position
        while position < text_length and is_ascii_letter(text[position]):
            position += 1
        if word_start == position:
            break
        word = text[word_start:position].lower()
        if word == 'bullshit':
            total_distinct += len(distinct_words)
            completed_games += 1
            distinct_words = []
        elif word not in distinct_words:
            distinct_words.append(word)
    divisor = hand_gcd(total_distinct, completed_games)
    return f"{total_distinct // divisor} / {completed_games // divisor}\n"


def render_words(words, max_line=90):
    lines = []
    current = ''
    for word in words:
        candidate = word if not current else current + ' ' + word
        if len(candidate) <= max_line:
            current = candidate
        else:
            lines.append(current)
            current = word
    if current:
        lines.append(current)
    return '\n'.join(lines) + '\n'


def write(name, text, cross_check=True):
    expected = oracle(text)
    if cross_check:
        assert brute_oracle(text) == expected, name
    (ROOT / 'in' / f'{name}.txt').write_text(text)
    (ROOT / 'out' / f'{name}.out').write_text(expected)


SAMPLE_TEXT = (
    'Programming languages can be classified BULLSHIT into following types:\n'
    '- imperative and BULLSHIT procedural languages\n'
    '- functional languages\n'
    '- logical BULLSHIT programming languages\n'
    '- object-oriented BULLSHIT languages\n'
)

assert oracle(SAMPLE_TEXT) == '9 / 2\n'
assert oracle('alpha BETA Alpha beta BULLSHIT') == '2 / 1\n'
assert oracle('x BULLSHIT y z BULLSHIT tail') == '3 / 2\n'
assert oracle('a b c BULLSHIT d e BULLSHIT') == '5 / 2\n'
assert brute_oracle(SAMPLE_TEXT) == oracle(SAMPLE_TEXT)

EDGE_TEXT = render_words([
    'A', 'a', 'a', 'BULLSHIT',
    'a1', 'a-a', 'a', 'BULLSHIT',
    'BINGO', 'bingo', 'BULLSHIT',
    'one', 'TWO', 'two', 'Three', 'BULLSHIT',
    'last', 'words', 'never', 'end',
])

wide_parts = []
for game_index in range(12):
    game_words = [f'g{game_index:02d}w{slot:03d}' for slot in range(500)]
    wide_parts.extend(game_words)
    wide_parts.extend(game_words[:100])
    wide_parts.append('BULLSHIT')
wide_parts.extend(f'tail{slot:03d}' for slot in range(100))
WIDE_TEXT = render_words(wide_parts)

random_generator = random.Random(20261125)
random_vocabulary = [f'word{idx:04d}' for idx in range(700)]
random_parts = []
for game_index in range(20):
    chosen_words = [random_generator.choice(random_vocabulary) for _ in range(40)]
    for word in chosen_words:
        random_parts.append(word.upper() if random_generator.random() < 0.3 else word)
    random_parts.append('BULLSHIT')
random_parts.extend(random_generator.choice(random_vocabulary) for _ in range(25))
RANDOM_TEXT = render_words(random_parts)

io_vocabulary = [f't{idx:04d}' for idx in range(600)]
io_parts = []
for game_index in range(1500):
    io_parts.extend(random_generator.choice(io_vocabulary) for _ in range(120))
    io_parts.append('BULLSHIT')
io_parts.extend(random_generator.choice(io_vocabulary) for _ in range(60))
IO_TEXT = render_words(io_parts)

(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
write('1_sample', SAMPLE_TEXT)
write('2_edges', EDGE_TEXT)
write('3_wide', WIDE_TEXT)
write('4_random', RANDOM_TEXT)
write('5_io', IO_TEXT, cross_check=False)
assert oracle(IO_TEXT).endswith('\n')
