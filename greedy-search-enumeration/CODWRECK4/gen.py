#!/usr/bin/env python3
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    word_count = int(tokens[cursor]); cursor += 1
    trie = {}
    for _ in range(word_count):
        word = tokens[cursor]; cursor += 1
        node = trie
        for letter in word:
            node = node.setdefault(letter, {})
        node['#'] = True
    message_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(message_count):
        message = tokens[cursor]; cursor += 1
        node = trie
        for split in range(1, len(message)):
            letter = message[split - 1]
            if letter not in node:
                break
            node = node[letter]
            if '#' not in node:
                continue
            suffix = trie
            for tail_letter in message[split:]:
                if tail_letter not in suffix:
                    suffix = None
                    break
                suffix = suffix[tail_letter]
            if suffix is not None and '#' in suffix:
                answers.append(message[:split] + " " + message[split:])
                break
    return "\n".join(answers) + "\n"


SAMPLE = """6
coding
code
wreck
dechef
co
chef
2
codingwreck
codechef
"""
SAMPLE_OUT = """coding wreck
co dechef
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\na\naa\n1\naa\n") == "a a\n"
assert oracle("3\nab\ncd\nabcd\n1\nabcd\n") == "ab cd\n"
assert oracle("4\na\nab\nbc\nc\n1\nabc\n") == "a bc\n"


def write(name, words, messages):
    lines = [str(len(words))] + list(words) + [str(len(messages))] + list(messages)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_word(rng, low, high):
    length = rng.randint(low, high)
    return "".join(rng.choice(string.ascii_lowercase) for _ in range(length))


def build():
    write("2_edges", ["a", "aa", "b", "ab"], ["aab", "aba", "abab"])
    rng = random.Random(20261126)
    wide = [random_word(rng, 5, 20) for _ in range(30000)]
    wide_messages = []
    for _ in range(200):
        first = rng.choice(wide)
        second = rng.choice(wide)
        if len(first) + len(second) <= 40:
            wide_messages.append(first + second)
    while len(wide_messages) < 200:
        wide_messages.append(rng.choice(wide) + rng.choice(wide))
    write("3_wide", wide, wide_messages)
    small = [random_word(rng, 1, 18) for _ in range(1000)]
    small_messages = []
    for _ in range(500):
        first = rng.choice(small)
        second = rng.choice(small)
        if len(first) + len(second) <= 40:
            small_messages.append(first + second)
    while len(small_messages) < 500:
        small_messages.append(rng.choice(small) + rng.choice(small))
    write("4_random", small, small_messages)
    io_words = [random_word(rng, 1, 20) for _ in range(1000)]
    io_messages = []
    for _ in range(1000):
        first = rng.choice(io_words)
        second = rng.choice(io_words)
        while len(first) + len(second) > 40:
            first = rng.choice(io_words)
            second = rng.choice(io_words)
        io_messages.append(first + second)
    write("5_io", io_words, io_messages)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", ["coding", "code", "wreck", "dechef", "co", "chef"],
      ["codingwreck", "codechef"])
build()
