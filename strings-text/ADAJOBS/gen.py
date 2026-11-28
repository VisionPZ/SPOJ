#!/usr/bin/env python3
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    query_count = int(tokens[0])
    cursor = 1
    inserted = []
    answers = []
    for _ in range(query_count):
        kind = int(tokens[cursor])
        word = tokens[cursor + 1]
        cursor += 2
        if kind == 0:
            inserted.append(word)
        else:
            answers.append("YES" if any(pattern in word for pattern in inserted) else "NO")
    return "\n".join(answers) + "\n" if answers else ""


SAMPLE = """12
0 cat
1 dogville
0 dog
1 dogville
1 gooutwithcat
1 gooutwithcrocodile
1 fancyconcatenation
0 crocodile
1 lacoste
1 gooutwithcrocodile
1 catalanreferendum
1 rocodile
"""
SAMPLE_OUT = """NO
YES
YES
NO
YES
NO
YES
YES
NO
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 abc\n") == "NO\n"
assert oracle("3\n0 a\n1 bab\n1 xyz\n") == "YES\nNO\n"
assert oracle("3\n0 abc\n1 xxabcxx\n1 xxabxx\n") == "YES\nNO\n"
assert oracle("2\n0 a\n1 a\n") == "YES\n"


def write(name, queries):
    text = f"{len(queries)}\n" + "".join(f"{kind} {word}\n" for kind, word in queries)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, "a"), (1, "bbb"), (0, "bbb"), (1, "bb"), (1, "b")])
    write("3_wide", [(0, "abcdefghij"), (1, "zzabcdefghzz"), (1, "abcdexxfghij"),
                     (0, "xyzxyz"), (1, "qqxyzxyzqq"), (1, "xyzyx")])
    rng = random.Random(20261126)
    alphabet = string.ascii_lowercase[:8]
    random_queries = []
    for query_index in range(60):
        kind = 0 if query_index % 3 == 0 else 1
        word = "".join(rng.choice(alphabet) for _ in range(rng.randint(1, 14)))
        random_queries.append((kind, word))
    write("4_random", random_queries)
    io_queries = [(0, "abcdefgh"), (0, "mnopqrst")]
    for query_index in range(200):
        word = "".join(rng.choice(alphabet) for _ in range(rng.randint(1, 16)))
        io_queries.append((1, word))
    write("5_io", io_queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(0, "cat"), (1, "dogville"), (0, "dog"), (1, "dogville"),
                   (1, "gooutwithcat"), (1, "gooutwithcrocodile"),
                   (1, "fancyconcatenation"), (0, "crocodile"),
                   (1, "lacoste"), (1, "gooutwithcrocodile"),
                   (1, "catalanreferendum"), (1, "rocodile")])
build()
