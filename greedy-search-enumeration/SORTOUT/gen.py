#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    input_count = int(tokens[0])
    query_count = int(tokens[1])
    words = tokens[2:2 + input_count]
    queries = tokens[2 + input_count:2 + input_count + query_count]
    answers = []
    for query in queries:
        answers.append(str(sum(1 for word in words if word <= query)))
    return "\n".join(answers) + "\n"


SAMPLE = """4 3
fury
fuzzy
dizzy
future
fuzz
evil
freeze
"""
SAMPLE_OUT = """3
1
1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 3\na\nb\nc\na\nb\nc\n") == "1\n2\n3\n"
assert oracle("3 2\nz\nz\ny\nz\nx\n") == "3\n0\n"
assert oracle("1 1\napple\napple\n") == "1\n"


def write(name, words, queries):
    text = f"{len(words)} {len(queries)}\n"
    text += "\n".join(words) + "\n"
    text += "\n".join(queries) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["a", "aa", "ab", "b", "ba", "a"], ["a", "aa", "z", "b"])
    rng = random.Random(20261126)
    alphabet = "abcdefghij"
    words = ["".join(rng.choice(alphabet) for _ in range(rng.randint(1, 6))) for _ in range(200)]
    queries = ["".join(rng.choice(alphabet) for _ in range(rng.randint(1, 6))) for _ in range(80)]
    write("3_wide", words, queries)
    words = ["".join(rng.choice("abc") for _ in range(rng.randint(1, 5))) for _ in range(300)]
    queries = ["".join(rng.choice("abc") for _ in range(rng.randint(1, 5))) for _ in range(120)]
    write("4_random", words, queries)
    long_word = "q" * 40
    write("5_io", [long_word] * 400, [long_word] * 200)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", ["fury", "fuzzy", "dizzy", "future"], ["fuzz", "evil", "freeze"])
build()
