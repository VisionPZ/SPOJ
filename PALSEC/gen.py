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
        n = int(tokens[cursor]); cursor += 1
        variants = []
        for _ in range(n):
            variants.append(tokens[cursor]); cursor += 1
        for _ in range(n):
            variants.append(tokens[cursor]); cursor += 1
        answers.append(str(solve(n, variants)))
    return "\n".join(answers) + "\n"


def solve(n, raw):
    variants = []
    for i in range(n):
        variants.append(raw[i])
        variants.append(raw[n + i])
    if n == 1:
        return sum(1 for word in variants if word == word[::-1])
    stream = ""
    begins = []
    ends = []
    for word in variants:
        begins.append(len(stream))
        stream += word
        ends.append(len(stream) - 1)
    belongs = [0] * len(stream)
    ahead = [[-1, -1] for _ in stream]
    behind = [[-1, -1] for _ in stream]
    for word_index, word in enumerate(variants):
        for offset in range(len(word)):
            spot = begins[word_index] + offset
            belongs[spot] = word_index
            if offset < len(word) - 1:
                ahead[spot][0] = spot + 1
            elif word_index < 2 * n - 2:
                ahead[spot][0] = begins[(word_index & ~1) + 2]
                ahead[spot][1] = begins[(word_index & ~1) + 3]
            if offset > 0:
                behind[spot][0] = spot - 1
            elif word_index >= 2:
                behind[spot][0] = ends[(word_index & ~1) - 2]
                behind[spot][1] = ends[(word_index & ~1) - 1]
    layer = {}
    for left_choice in range(2):
        for right_choice in range(2):
            if variants[left_choice][0] == variants[2 * n - 2 + right_choice][-1]:
                spot = (begins[left_choice], ends[2 * n - 2 + right_choice])
                layer[spot] = layer.get(spot, 0) + 1
    total = 0
    while layer:
        next_layer = {}
        for (left_spot, right_spot), ways in layer.items():
            if (left_spot == right_spot
                    or (left_spot + 1 == right_spot and belongs[left_spot] == belongs[right_spot])
                    or (left_spot == ends[belongs[left_spot]]
                        and right_spot == begins[belongs[right_spot]]
                        and (belongs[left_spot] & ~1) + 2 == (belongs[right_spot] & ~1))):
                total += ways
                continue
            for left_choice in range(2):
                for right_choice in range(2):
                    moved_left = ahead[left_spot][left_choice]
                    moved_right = behind[right_spot][right_choice]
                    if (moved_left >= 0 and moved_right >= 0 and moved_left <= moved_right
                            and stream[moved_left] == stream[moved_right]):
                        spot = (moved_left, moved_right)
                        next_layer[spot] = next_layer.get(spot, 0) + ways
        layer = next_layer
    return total


def brute(n, xwords, ywords):
    total = 0
    for bits in range(1 << n):
        assembled = "".join(
            xwords[i] if (bits >> i) & 1 else ywords[i] for i in range(n))
        if assembled == assembled[::-1]:
            total += 1
    return total


def worked_example():
    xwords = ["a", "bbb"]
    ywords = ["b", "aaa"]
    lines = []
    for choice in range(4):
        assembled = "".join(
            xwords[i] if (choice >> i) & 1 else ywords[i] for i in range(2))
        verdict = "palindrome" if assembled == assembled[::-1] else "not"
        lines.append(f"{choice:02b}  {assembled:6s}  {verdict}")
    lines.append(f"count = {solve(2, xwords + ywords)}")
    return "\n".join(lines)


def encode(cases):
    parts = [str(len(cases))]
    for xwords, ywords in cases:
        parts.append(str(len(xwords)))
        parts.extend(xwords)
        parts.extend(ywords)
    return "\n".join(parts) + "\n"


def write(name, cases):
    input_text = encode(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [(["ab", "a", "a", "ab", "a"],
           ["a", "baaaa", "a", "a", "ba"])]
SAMPLE_TEXT = ("1\n5\nab\na\na\nab\na\n"
               "a\nbaaaa\na\na\nba\n")
assert oracle(SAMPLE_TEXT) == "12\n"
assert oracle(encode(SAMPLE)) == "12\n"

check_seed = random.Random(2026)
for _ in range(300):
    length = check_seed.randint(1, 6)
    xs = ["".join(check_seed.choice("ab") for _ in range(check_seed.randint(1, 4)))
          for _ in range(length)]
    ys = ["".join(check_seed.choice("ab") for _ in range(check_seed.randint(1, 4)))
          for _ in range(length)]
    assert solve(length, xs + ys) == brute(length, xs, ys)

assert solve(4, ["a"] * 4 + ["a"] * 4) == 16
assert solve(1, ["a", "a"]) == 2
assert solve(2, ["ab", "ba", "zz", "zz"]) == 2


def build():
    long_pal = "a" * 400
    edges = [
        (["a"], ["a"]),
        (["ab"], ["ba"]),
        (["aba"], ["xyz"]),
        (["a", "b"], ["b", "a"]),
        (["ab", "ba"], ["zz", "zz"]),
        (["a", "bbbb"], ["b", "aaaa"]),
        ([long_pal], ["b" * 400]),
        (["a"] * 30, ["a"] * 30),
    ]
    write("2_edges", edges)

    wide = [
        (["".join(random.choice("abc") for _ in range(400)) for _ in range(30)],
         ["".join(random.choice("abc") for _ in range(400)) for _ in range(30)]),
        ([long_pal] * 30, [long_pal] * 30),
        (["a" * 400, "b" * 400] * 15, ["b" * 400, "a" * 400] * 15),
    ]
    write("3_wide", wide)

    seeded = random.Random(424242)
    random_cases = []
    for _ in range(16):
        length = seeded.randint(18, 30)
        xs = ["".join(seeded.choice("abc") for _ in range(seeded.randint(1, 400)))
              for _ in range(length)]
        ys = ["".join(seeded.choice("abc") for _ in range(seeded.randint(1, 400)))
              for _ in range(length)]
        random_cases.append((xs, ys))
    write("4_random", random_cases)

    io_seed = random.Random(777)
    io_cases = []
    for _ in range(100000):
        left = io_seed.choice("aab")
        right = io_seed.choice("aab")
        io_cases.append(([left], [right]))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
print(worked_example())
