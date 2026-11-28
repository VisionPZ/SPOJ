#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        length = int(tokens[cursor]); cursor += 1
        segments = tokens[cursor]; cursor += 1
        best = [0] * (length + 1)
        for right in range(1, length + 1):
            candidate = best[right - 1]
            score = 0
            for left in range(right, 0, -1):
                score += 1 if segments[left - 1] == '1' else -1
                if score > 0:
                    piece = best[left - 1] + (right - left + 1)
                    if piece > candidate:
                        candidate = piece
            best[right] = candidate
        answers.append(str(best[length]))
    return "\n".join(answers) + "\n"


def brute(segments):
    length = len(segments)
    answer = 0
    for mask in range(1 << max(0, length - 1)):
        sold = 0
        start = 0
        for cut in range(length - 1):
            if mask & (1 << cut):
                piece = segments[start:cut + 1]
                if piece.count('1') > piece.count('0'):
                    sold += len(piece)
                start = cut + 1
        piece = segments[start:]
        if piece.count('1') > piece.count('0'):
            sold += len(piece)
        if sold > answer:
            answer = sold
    return answer


def input_text(segments_list):
    return str(len(segments_list)) + "\n" + "".join(
        f"{len(segments)}\n{segments}\n" for segments in segments_list)


def write(name, segments_list):
    text = input_text(segments_list)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE = ["100110001010001", "0010111101100000"]
sample_input = input_text(SAMPLE)
assert oracle(sample_input) == "9\n13\n"

random.seed(11)
for _ in range(300):
    length = random.randint(1, 10)
    segments = "".join(random.choice("01") for _ in range(length))
    assert oracle(input_text([segments])) == f"{brute(segments)}\n"

assert oracle(input_text(["1"])) == "1\n"
assert oracle(input_text(["0"])) == "0\n"
assert oracle(input_text(["1" * 200])) == "200\n"
assert oracle(input_text(["0" * 200])) == "0\n"


def build():
    edges = [
        "0", "1", "10", "01", "11", "00", "101", "010", "111000",
        "000111", "1" + "0" * 198 + "1", "0" * 199 + "1",
        "1" * 199 + "0", "100110001010001", "0010111101100000",
    ]
    write("2_edges", edges)

    wide = [
        "1" * 200, "0" * 200, ("10" * 100), ("01" * 100),
        "1" * 100 + "0" * 100, "0" * 100 + "1" * 100,
        "1" + "0" * 199, "0" * 199 + "1",
    ]
    write("3_wide", wide)

    random.seed(2026)
    randomized = ["".join(random.choice("01") for _ in range(random.randint(1, 200)))
                  for _ in range(200)]
    write("4_random", randomized)

    random.seed(7788)
    io = ["".join(random.choice("01") for _ in range(random.randint(1, 8)))
          for _ in range(250000)]
    write("5_io", io)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
