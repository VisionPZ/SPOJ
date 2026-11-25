#!/usr/bin/env python3
import random
from functools import lru_cache
from itertools import product
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def is_set(word):
    length = len(word)

    @lru_cache(None)
    def set_ok(left, right):
        if left >= right or word[left] != '{' or word[right] != '}':
            return False
        if right == left + 1:
            return True
        return list_ok(left + 1, right - 1)

    @lru_cache(None)
    def element_ok(left, right):
        return left == right or set_ok(left, right)

    @lru_cache(None)
    def list_ok(left, right):
        if left > right:
            return False
        if element_ok(left, right):
            return True
        for cut in range(left + 1, right + 1):
            if word[cut] == ',' and element_ok(left, cut - 1) and list_ok(cut + 1, right):
                return True
        return False

    return set_ok(0, length - 1)


def brute_is_set(word):
    def element_ends(start):
        yield start
        yield from set_ends(start)

    def set_ends(start):
        if start >= len(word) or word[start] != '{':
            return
        if start + 1 < len(word) and word[start + 1] == '}':
            yield start + 1
        for inner_end in list_ends(start + 1):
            if inner_end + 1 < len(word) and word[inner_end + 1] == '}':
                yield inner_end + 1

    def list_ends(start):
        if start >= len(word):
            return
        for first_end in element_ends(start):
            yield first_end
            cut = first_end + 1
            if cut < len(word) and word[cut] == ',':
                yield from list_ends(cut + 1)

    return len(word) - 1 in set_ends(0)


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for case_index in range(1, count + 1):
        word = tokens[cursor]
        cursor += 1
        verdict = 'Set' if is_set(word) else 'No Set'
        answers.append(f'Word #{case_index}: {verdict}')
    return '\n'.join(answers) + '\n'


def write(name, words):
    input_text = str(len(words)) + '\n' + ''.join(word + '\n' for word in words)
    (ROOT / 'in' / f'{name}.txt').write_text(input_text)
    (ROOT / 'out' / f'{name}.out').write_text(oracle(input_text))


assert is_set('{}') and is_set('{{}}') and is_set('{{}},{,}}') and not is_set('{,,}')
assert not is_set('{') and not is_set('}') and not is_set(',')
assert is_set('{{}') and is_set('{}}') and is_set('{,}')
assert is_set('{' * 100 + '}' * 100) and is_set('{' + ',' * 197 + '}')
for size in range(1, 8):
    for letters in product('{},', repeat=size):
        word = ''.join(letters)
        assert is_set(word) == brute_is_set(word), word

SAMPLE = ['{}', '{{}}', '{{}},{,}}', '{,,}']

EDGES = [
    '{', '}', ',', '{}', '{{}', '{}}', '{,}', '{{}}', '{,,}', '{{,}}',
    '{{},}}', '{},{}', '{{,},{}}', '{},,}', '{{,{}}', '{},},{}',
    '{' + ',' * 197 + '}', '{' + ',' * 198 + '}',
    '{' * 100 + '}' * 100, '{' * 99 + '}' * 100,
    '{' * 100 + '}' * 99 + ',',
]

WIDE = [
    '{' * 100 + '}' * 100,
    '{' + ',' * 197 + '}',
    '{' + ',' * 198 + '}',
    '{' * 100 + '}' * 99 + ',',
    '{' * 50 + ',' * 99 + '}' * 50,
]

rng = random.Random(20261125)
RANDOM = [''.join(rng.choice('{},') for _ in range(rng.randint(1, 200)))
          for _ in range(500)]

IO = ['{' for _ in range(100000)]

(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
write('1_sample', SAMPLE)
write('2_edges', EDGES)
write('3_wide', WIDE)
write('4_random', RANDOM)
write('5_io', IO)
print('generated', len(RANDOM), 'random words and', len(IO), 'io words')
