#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while True:
        count = int(tokens[cursor]); cursor += 1
        line_count = int(tokens[cursor]); cursor += 1
        if count == 0 and line_count == 0:
            break
        elements = tokens[cursor:cursor + count]; cursor += count
        text_data = "".join(tokens[cursor:cursor + line_count]); cursor += line_count
        lengths = [len(element) for element in elements]
        total_length = sum(lengths)
        full_mask = (1 << count) - 1

        @lru_cache(maxsize=None)
        def completes(mask, position):
            if mask == full_mask:
                return True
            for index in range(count):
                bit = 1 << index
                if mask & bit:
                    continue
                if text_data.startswith(elements[index], position) \
                        and completes(mask | bit, position + lengths[index]):
                    return True
            return False

        matches = 0
        for start in range(len(text_data) - total_length + 1):
            if completes(0, start):
                matches += 1
        answers.append(str(matches))
    return "\n".join(answers) + "\n"


SAMPLE = (
    "3 1\naa\nb\nccc\naabccczbaacccbaazaabbcccaa\n"
    "3 1\na\nb\nc\n"
    "cbbcbcbabaacabccaccbaacbccbcaaaccccbcbcbbcacbaacccaccbbcaacbbabbabaccc\n"
    "3 4\n" + "a" * 20 + "\n" + "a" * 20 + "\n" + "a" * 20 + "\n"
    + "a" * 58 + "\n" + "a" * 79 + "\n" + "a" * 68 + "\n" + "a" * 51 + "\n"
    "0 0\n"
)
SAMPLE_OUT = "5\n12\n197\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\na\naaa\n0 0\n") == "3\n"
assert oracle("2 1\nx\nxx\nxxxx\n0 0\n") == "2\n"
assert oracle("2 1\nab\nba\nabba\n0 0\n") == "1\n"
assert oracle("1 1\nabc\nabcabc\n0 0\n") == "2\n"


def dataset(elements, text_data, line_length=100):
    lines = [text_data[index:index + line_length]
             for index in range(0, len(text_data), line_length)]
    return (f"{len(elements)} {len(lines)}\n" + "".join(element + "\n" for element in elements)
            + "".join(line + "\n" for line in lines))


def write(name, datasets):
    text = "".join(datasets) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    wide = [dataset(["a" * length for length in range(1, 9)], "a" * 200)]
    rng = random.Random(20261126)
    letters = "abcdefghijklmnopqrstuvwxyz"
    elements = ["".join(rng.choice(letters) for _ in range(4)) for _ in range(12)]
    permutation = elements[:]
    rng.shuffle(permutation)
    body = "".join(rng.choice(letters) for _ in range(5000))
    insert_at = 500
    body = body[:insert_at] + "".join(permutation) + body[insert_at:]
    wide.append(dataset(elements, body))
    write("3_wide", wide)

    random_datasets = []
    for _ in range(8):
        count = rng.randint(1, 5)
        elements = ["".join(rng.choice(letters) for _ in range(rng.randint(1, 4)))
                    for _ in range(count)]
        text_length = rng.randint(60, 150)
        body = "".join(rng.choice(letters) for _ in range(text_length))
        if rng.random() < 0.5:
            order = elements[:]
            rng.shuffle(order)
            spot = rng.randint(0, len(body))
            body = body[:spot] + "".join(order) + body[spot:]
        random_datasets.append(dataset(elements, body))
    write("4_random", random_datasets)

    io_datasets = []
    for _ in range(5000):
        element = rng.choice(letters)
        body = "".join(rng.choice(letters) for _ in range(6))
        io_datasets.append(dataset([element], body))
    write("5_io", io_datasets)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
write("2_edges", [
    dataset(["a"], "aaa"),
    dataset(["x", "xx"], "xxxx"),
    dataset(["ab", "ba"], "abba"),
    dataset(["abc"], "abcabc"),
    dataset(["a", "b", "c"], "abc"),
])
build()
