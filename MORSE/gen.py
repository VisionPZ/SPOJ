import os
import random

MORSE = [
    ".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---",
    "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-",
    "..-", "...-", ".--", "-..-", "-.--", "--..",
]
ALPHABET = [chr(ord("A") + index) for index in range(26)]
REVERSE = {code: ALPHABET[index] for index, code in enumerate(MORSE)}
DOT_DOT_LETTERS = "ISHFUV"
DOT_LETTERS = "EISHFUV"
DASH_LETTERS = "BCDGK MNOQ TXYZ".replace(" ", "")


def to_morse(word):
    return "".join(MORSE[ord(letter) - 65] for letter in word)


def from_morse(code):
    letters = []
    position = 0
    while position < len(code):
        for width in (4, 3, 2, 1):
            piece = code[position:position + width]
            if piece in REVERSE:
                letters.append(REVERSE[piece])
                position += width
                break
    return "".join(letters)


def oracle_dp(sequence, words):
    counts = {}
    for word in words:
        code = to_morse(word)
        counts[code] = counts.get(code, 0) + 1
    lengths = sorted({len(code) for code in counts})
    ways = [0] * (len(sequence) + 1)
    ways[0] = 1
    for position in range(len(sequence)):
        base = ways[position]
        if base == 0:
            continue
        for width in lengths:
            if position + width > len(sequence):
                continue
            found = counts.get(sequence[position:position + width], 0)
            if found:
                ways[position + width] += base * found
    return ways[len(sequence)]


def oracle_brute(sequence, words):
    codes = [to_morse(word) for word in words]
    cache = {}

    def recurse(position):
        if position == len(sequence):
            return 1
        if position in cache:
            return cache[position]
        total = 0
        for code in codes:
            if sequence.startswith(code, position):
                total += recurse(position + len(code))
        cache[position] = total
        return total

    return recurse(0)


def unique_words(alphabet, count, length):
    base = len(alphabet)
    words = []
    for index in range(count):
        digits = []
        value = index
        for _ in range(length):
            digits.append(alphabet[value % base])
            value //= base
        words.append("".join(reversed(digits)))
    assert len(set(words)) == count
    return words


assert to_morse("A") == ".-"
assert to_morse("Z") == "--.."
assert to_morse("ATTACK") == ".---.--.-.-.-"
assert to_morse(from_morse(".---.--.-.-.-")) == ".---.--.-.-.-"

SAMPLE_SEQUENCE = ".---.--.-.-.-.---...-.---."
SAMPLE_WORDS = ["AT", "TACK", "TICK", "ATTACK", "DAWN", "DUSK"]
assert oracle_dp(SAMPLE_SEQUENCE, SAMPLE_WORDS) == 2
assert oracle_brute(SAMPLE_SEQUENCE, SAMPLE_WORDS) == 2
assert oracle_dp("." * 45, ["E", "I"]) == 1836311903
assert oracle_brute("." * 10, ["E", "EE", "EEE"]) == oracle_dp("." * 10, ["E", "EE", "EEE"])


def write_case(name, datasets):
    with open("in/" + name + ".txt", "w") as input_file:
        input_file.write(str(len(datasets)) + "\n")
        for sequence, words in datasets:
            input_file.write(sequence + "\n")
            input_file.write(str(len(words)) + "\n")
            for word in words:
                input_file.write(word + "\n")
    with open("out/" + name + ".out", "w") as output_file:
        for sequence, words in datasets:
            answer = oracle_dp(sequence, words)
            assert 0 <= answer <= 2000000000
            output_file.write(str(answer) + "\n")


write_case("1_sample", [(SAMPLE_SEQUENCE, SAMPLE_WORDS)])

edge_datasets = [
    (".", ["E"]),
    (".", ["E", "E"]),
    ("-", ["T"]),
    ("...", ["T"]),
    (".", ["ATTACK"]),
    ("....", ["E", "EE", "EEE", "EEEE"]),
    (".....", ["E", "EE"]),
    ("..", ["E", "I"]),
    ("-.-.", ["N", "TET", "E", "ET"]),
    (".-.-", ["A", "EE"]),
]
for sequence, words in edge_datasets:
    assert oracle_brute(sequence, words) == oracle_dp(sequence, words)
write_case("2_edges", edge_datasets)

wide_fillers_a = unique_words(DOT_DOT_LETTERS, 9999, 20)
wide_fillers_b = unique_words(DOT_LETTERS, 9999, 20)
wide_datasets = [
    (".-" * 5000, ["A"] + wide_fillers_a),
    ("-" * 10000, ["T"] + wide_fillers_b),
]
assert [oracle_dp(sequence, words) for sequence, words in wide_datasets] == [1, 1]
write_case("3_wide", wide_datasets)

rng = random.Random(20261124)
random_datasets = []
for case_index in range(8):
    while True:
        length = rng.randint(30, 100)
        sequence = "".join(rng.choice(".-") for _ in range(length))
        words = []
        for _ in range(rng.randint(3, 6)):
            start = rng.randint(0, length - 2)
            width = rng.randint(2, min(8, length - start))
            words.append(from_morse(sequence[start:start + width]))
        for _ in range(rng.randint(100, 300)):
            words.append("".join(rng.choice(ALPHABET) for _ in range(rng.randint(1, 6))))
        words = list(dict.fromkeys(words))
        if oracle_dp(sequence, words) <= 2000000000:
            break
    assert oracle_brute(sequence, words) == oracle_dp(sequence, words)
    random_datasets.append((sequence, words))
write_case("4_random", random_datasets)

io_fillers = unique_words(DASH_LETTERS, 9998, 20)
io_datasets = [("." * 45, ["E", "I"] + io_fillers) for _ in range(20)]
assert all(oracle_dp(sequence, words) == 1836311903 for sequence, words in io_datasets)
write_case("5_io", io_datasets)

print("generated 5 test pairs")
