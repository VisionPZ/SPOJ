#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def suffix_length(first, second):
    length = 0
    while length < min(len(first), len(second)) and first[-1 - length] == second[-1 - length]:
        length += 1
    return length


def oracle(text):
    first_part, second_part = text.split("\n\n", 1)
    words = first_part.splitlines()
    queries = [line for line in second_part.splitlines() if line]
    answers = []
    for query in queries:
        best_word = None
        best_suffix = -1
        for word in words:
            if word == query:
                continue
            length = suffix_length(word, query)
            if length > best_suffix or (length == best_suffix and word < best_word):
                best_suffix = length
                best_word = word
        answers.append(best_word)
    return "\n".join(answers) + "\n"


SAMPLE = """perfect
rhyme
crime
time

crime
rhyme
"""
SAMPLE_OUT = """time
crime
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("cat\ndog\nbat\n\nbat\ncat\n") == "cat\nbat\n"
assert oracle("ab\nbab\ncab\n\nab\n") == "bab\n"
assert suffix_length("perfect", "affect") == 4


def write(name, words, queries):
    text = "\n".join(words) + "\n\n" + "\n".join(queries) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_words(count, rng, suffix, max_length):
    words = set()
    while len(words) < count:
        length = rng.randint(1, max_length)
        prefix = "".join(rng.choice("abcdefghijklmnop") for _ in range(length))
        words.add(prefix + suffix)
    return sorted(words)


def build():
    rng = random.Random(20261202)
    write("2_edges", ["a", "b", "ba", "ab", "ca"], ["a", "ab", "zz", "ba"])
    wide_words = random_words(3000, rng, "e", 11)
    wide_queries = random_words(300, rng, "e", 11) + wide_words[:100]
    write("3_wide", wide_words, wide_queries)
    random_words_list = random_words(250, rng, "ing", 8)
    random_queries = random_words(250, rng, "ing", 8) + random_words_list[:50]
    write("4_random", random_words_list, random_queries)
    io_words = random_words(800, rng, "", 4)
    io_queries = random_words(800, rng, "", 4)
    write("5_io", io_words, io_queries)
    big_words = random_words(120000, rng, "z", 20)
    big_queries = random_words(120000, rng, "z", 20)
    Path("/tmp/PRHYME_big.txt").write_text(
        "\n".join(big_words) + "\n\n" + "\n".join(big_queries) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
