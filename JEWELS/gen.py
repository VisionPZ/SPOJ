#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def bit_lcs(first, second):
    masks = {}
    for pos, ch in enumerate(second):
        masks[ch] = masks.get(ch, 0) | (1 << pos)
    full = (1 << len(second)) - 1
    state = full
    for ch in first:
        match = masks.get(ch, 0)
        state = ((state + (state & match)) | (state & ~match)) & full
    return len(second) - bin(state).count('1')


def naive_lcs(first, second):
    prev = [0] * (len(second) + 1)
    for ch in first:
        cur = [0] * (len(second) + 1)
        for j, other in enumerate(second):
            if ch == other:
                cur[j + 1] = prev[j] + 1
            else:
                cur[j + 1] = max(prev[j + 1], cur[j])
        prev = cur
    return prev[-1]


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        word = tokens[cursor]
        cursor += 1
        length = len(word)
        best = 0
        cut = 1
        for c in range(1, length):
            straight = bit_lcs(word[:c], word[c:])
            turned = bit_lcs(word[:c], word[c:][::-1])
            value = 2 * max(straight, turned)
            if value > best:
                best = value
                cut = c
        answers.append(f"{best} {cut}")
    return "\n".join(answers) + "\n"


def write(name, words, expected=None):
    input_text = str(len(words)) + "\n" + "".join(word + "\n" for word in words)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    output_text = oracle(input_text) if expected is None else "".join(
        line + "\n" for line in expected)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


SAMPLE = ["abcacdd", "acbddabedff", "abcbca"]
SAMPLE_OUT = ["4 3", "6 4", "4 2"]
assert oracle("3\nabcacdd\nacbddabedff\nabcbca\n") == "4 3\n6 4\n4 2\n"
assert oracle("1\naccddaacda\n").strip() == "8 6"
assert oracle("1\naabb\n").strip() == "2 1"
assert oracle("1\nabcabc\n").strip() == "6 3"

random.seed(7)
for _ in range(300):
    length = random.randint(1, 10)
    word = ''.join(random.choice('abcd') for _ in range(length))
    for c in range(1, length):
        assert bit_lcs(word[:c], word[c:]) == naive_lcs(word[:c], word[c:])
        assert bit_lcs(word[:c], word[c:][::-1]) == naive_lcs(word[:c], word[c:][::-1])


def build():
    write("1_sample", SAMPLE, SAMPLE_OUT)

    edges = ["a", "ab", "aa", "abc", "abca", "abcd", "zzzz", "abcbca",
             "cbaabc", "ababab", "aabb", "abacaba", "abcddcba", "qwerty"]
    write("2_edges", edges)

    wide = ['a' * 8000, 'a' * 4000 + 'b' * 4000]
    write("3_wide", wide, ["8000 4000", "4000 2000"])

    random.seed(20261124)
    mid = []
    for _ in range(200):
        length = random.randint(2, 160)
        mid.append(''.join(random.choice('abcdefgh') for _ in range(length)))
    write("4_random", mid)

    random.seed(99)
    many = []
    for _ in range(500):
        length = random.randint(2, 150)
        many.append(''.join(random.choice('abcdefghijklmnopqrstuvwxyz') for _ in range(length)))
    write("5_io", many)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE, SAMPLE_OUT)
build()
