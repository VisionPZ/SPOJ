#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def disjoint_count(text, pattern, step):
    first = text.find(pattern)
    if first == -1:
        return 0
    count = 1
    end = first + step
    while True:
        nxt = text.find(pattern, end)
        if nxt == -1:
            return count
        count += 1
        end = nxt + step
        if count >= 2:
            return count


def valid_length(messages, length):
    base = messages[0]
    earliest = {}
    for pos in range(len(base) - length + 1):
        pat = base[pos:pos + length]
        if pat not in earliest:
            earliest[pat] = pos
    candidates = []
    for pat, firstpos in earliest.items():
        if base.find(pat, firstpos + length) != -1:
            candidates.append(pat)
    if not candidates:
        return False
    for msg in messages[1:]:
        survivors = [pat for pat in candidates if disjoint_count(msg, pat, length) >= 2]
        if not survivors:
            return False
        candidates = survivors
    return True


def oracle(cases):
    answers = []
    for messages in cases:
        shortest = min(len(m) for m in messages)
        low, high = 0, shortest // 2
        while low < high:
            middle = (low + high + 1) // 2
            if valid_length(messages, middle):
                low = middle
            else:
                high = middle - 1
        answers.append(str(low))
    return "\n".join(answers) + "\n"


def render(cases):
    parts = [str(len(cases))]
    for messages in cases:
        parts.append(str(len(messages)))
        parts.extend(messages)
    return "\n".join(parts) + "\n"


def write(name, cases):
    input_text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


SAMPLE = [["abbabba", "dabddkababa", "bacaba", "baba"]]
assert oracle(SAMPLE) == "2\n"
assert oracle([["abab", "abab"]]) == "2\n"
assert oracle([["aaaa", "aaaa"]]) == "2\n"
assert oracle([["abc", "abc"]]) == "0\n"
assert oracle([["aa"]]) == "1\n"
assert oracle([["ab"]]) == "0\n"


def repeated(seed, word, blocks, prefix, suffix):
    rng = random.Random(seed)
    noise = "".join(rng.choice("abcdefghijklmnopqrstuvwxyz") for _ in range(3))
    return prefix + noise + (word + noise) * blocks + suffix


def build():
    edges = [
        ["abcabc", "abcabc"],
        ["aaaa", "aaaa", "aaaa"],
        ["ab", "cd"],
        ["z" * 40, "q" + "z" * 40 + "q"],
        ["abcdefghij" * 20],
        ["mnopqrst" * 8, "stuvwxyz" * 8, "abcdefgh" * 8],
    ]
    write("2_edges", edges)

    wide_word = "qwerty" + "z" * 4
    wide = []
    for seed in range(2):
        msgs = []
        for idx in range(10):
            msgs.append(repeated(seed * 100 + idx, wide_word, 40,
                                 "ab", "cd"))
        wide.append(msgs)
    write("3_wide", wide)

    rng = random.Random(2026)
    random_cases = []
    for _ in range(10):
        count = rng.randint(1, 6)
        msgs = []
        for _ in range(count):
            length = rng.randint(2, 180)
            msgs.append("".join(rng.choice("abcde") for _ in range(length)))
        random_cases.append(msgs)
    write("4_random", random_cases)

    io_word = "phraserepeat"
    io_cases = []
    for seed in range(10):
        msgs = []
        for idx in range(10):
            msgs.append(repeated(5000 + seed * 100 + idx, io_word, 30,
                                 "xy", "wv"))
        io_cases.append(msgs)
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
