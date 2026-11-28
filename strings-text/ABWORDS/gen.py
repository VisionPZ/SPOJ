#!/usr/bin/env python3
import itertools
import random
import sys
from pathlib import Path

sys.setrecursionlimit(100000)
ROOT = Path(__file__).resolve().parent


def all_dyck(half):
    result = []
    def grow(prefix, openings, closings):
        if openings == half and closings == half:
            result.append(''.join(prefix))
            return
        if openings < half:
            prefix.append('a')
            grow(prefix, openings + 1, closings)
            prefix.pop()
        if closings < openings:
            prefix.append('b')
            grow(prefix, openings, closings + 1)
            prefix.pop()
    grow([], 0, 0)
    return result


def random_dyck(half):
    letters = []
    openings = 0
    closings = 0
    while openings < half or closings < half:
        if openings < half and (closings == openings or random.randrange(2) == 0):
            letters.append('a')
            openings += 1
        else:
            letters.append('b')
            closings += 1
    return ''.join(letters)


def literal_similarity(left, right):
    if len(left) != len(right):
        return False
    memo = {}
    length = len(left)
    stride = (length + 1) * (length + 1)
    def equal_part(a, b, half):
        key = half * stride + a * (length + 1) + b
        if key in memo:
            return memo[key]
        if half == 0:
            answer = True
        else:
            answer = False
            if (left[a] == 'a' and right[b] == 'a' and
                    left[a + 2 * half - 1] == 'b' and
                    right[b + 2 * half - 1] == 'b' and
                    equal_part(a + 1, b + 1, half - 1)):
                answer = True
            else:
                for split in range(1, half):
                    if (equal_part(a, b, split) and
                            equal_part(a + 2 * split, b + 2 * split, half - split)):
                        answer = True
                        break
                    if (equal_part(a, b + 2 * (half - split), split) and
                            equal_part(a + 2 * split, b, half - split)):
                        answer = True
                        break
        memo[key] = answer
        return answer
    return equal_part(0, 0, length // 2)


def canonical_tree(word):
    children = []
    balance = 0
    start = 0
    for position, letter in enumerate(word):
        balance += 1 if letter == 'a' else -1
        if balance == 0:
            children.append((canonical_tree(word[start + 1:position]),))
            start = position + 1
    return tuple(sorted(children))


def exact_diversity(words):
    chosen = []
    for word in words:
        if all(not literal_similarity(word, other) for other in chosen):
            chosen.append(word)
    best = [len(chosen)]
    def search(position, picked):
        if position == len(words):
            best[0] = max(best[0], len(picked))
            return
        if len(picked) + len(words) - position <= best[0]:
            return
        word = words[position]
        if all(not literal_similarity(word, other) for other in picked):
            search(position + 1, picked + [word])
        search(position + 1, picked)
    search(0, [])
    return best[0]


def canonical_diversity(words):
    return len({canonical_tree(word) for word in words})


def oracle(text, exact=False):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        word_count = int(tokens[cursor])
        cursor += 1
        words = tokens[cursor:cursor + word_count]
        cursor += word_count
        answers.append(str(exact_diversity(words) if exact else canonical_diversity(words)))
    return '\n'.join(answers) + '\n'


def write(name, cases, exact=False):
    input_text = str(len(cases)) + '\n'
    input_text += '\n'.join(str(len(words)) + '\n' + '\n'.join(words)
                            for words in cases) + '\n'
    (ROOT / 'in' / (name + '.txt')).write_text(input_text)
    (ROOT / 'out' / (name + '.out')).write_text(oracle(input_text, exact))


SAMPLE = [['aabaabbbab', 'abababaabb', 'abaaabbabb']]
assert oracle('1\n3\naabaabbbab\nabababaabb\nabaaabbabb\n', exact=True) == '2\n'
for half in range(1, 7):
    words = all_dyck(half)
    for left, right in itertools.product(words, repeat=2):
        assert (literal_similarity(left, right) ==
                (canonical_tree(left) == canonical_tree(right)))

NONTRANSITIVE = [
    'aabbabaaabbbabababaababb',
    'aaabbbaabbabaababbababab',
    'aaabbbaababbaabbabababab',
]
assert oracle('1\n3\n' + '\n'.join(NONTRANSITIVE) + '\n', exact=True) == '2\n'
assert canonical_diversity(NONTRANSITIVE) == 1


def build():
    pieces = [all_dyck(order)[0] for order in range(1, 5)]
    permutations = [''.join(part) for part in itertools.permutations(pieces)]
    edges = [
        ['ab'],
        ['ab', 'ab'],
        ['ab', 'aabb'],
        ['ab', 'aabb', 'abab', 'aaabbb'],
        ['ab' * 100, 'a' * 100 + 'b' * 100],
        NONTRANSITIVE,
        ['ab', 'aabb', 'aabb', 'ab', 'ababab'],
        permutations,
    ]
    write('2_edges', edges, exact=True)

    wide = []
    random.seed(11)
    for _ in range(5):
        wide.append([random_dyck(100) for _ in range(1000)])
    write('3_wide', wide)

    random.seed(2026)
    random_cases = []
    for _ in range(4):
        count = random.randint(6, 16)
        half = random.randint(1, 12)
        words = [''.join(random_dyck(random.randint(1, half))
                         for _ in range(random.randint(1, 3)))
                 for _ in range(count)]
        random_cases.append(words)
    write('4_random', random_cases, exact=True)

    random.seed(99)
    io_cases = []
    for _ in range(4000):
        half = random.randint(1, 100)
        pieces = max(1, half // 10)
        io_cases.append([''.join(random_dyck(max(1, half // pieces))
                                 for _ in range(pieces))])
    write('5_io', io_cases)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
write('1_sample', SAMPLE, exact=True)
build()
