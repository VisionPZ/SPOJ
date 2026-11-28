import os
import random

IN_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "in")
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")


def min_rotation_naive(text):
    length = len(text)
    best = 0
    for start in range(1, length):
        offset = 0
        while offset < length and text[(start + offset) % length] == text[(best + offset) % length]:
            offset += 1
        if offset < length and text[(start + offset) % length] < text[(best + offset) % length]:
            best = start
    return best


def min_rotation_scan(text):
    length = len(text)
    if length < 2:
        return 0
    smallest = min(text)
    doubled = text + text
    candidates = [pos for pos in range(length) if text[pos] == smallest]
    return min(candidates, key=lambda pos: doubled[pos:pos + length])


def oracle(text):
    if len(text) <= 300:
        naive = min_rotation_naive(text)
        assert naive == min_rotation_scan(text), text
        return naive
    return min_rotation_scan(text)


def write_case(name, cases):
    with open(os.path.join(IN_DIR, name + ".txt"), "w") as handle:
        handle.write(str(len(cases)) + "\n")
        for text in cases:
            handle.write(text + "\n")
    with open(os.path.join(OUT_DIR, name + ".out"), "w") as handle:
        handle.write("\n".join(str(oracle(text) + 1) for text in cases) + "\n")


def random_necklace(rng, length, alphabet):
    return "".join(rng.choice(alphabet) for _ in range(length))


SAMPLE = ["helloworld", "amandamanda", "dontcallmebfu", "aaabaaa"]
assert oracle("helloworld") == 9
assert oracle("amandamanda") == 10
assert oracle("dontcallmebfu") == 5
assert oracle("aaabaaa") == 4
assert oracle("bbaa") == 2
assert oracle("aaaa") == 0
assert oracle("ba") == 1

os.makedirs(IN_DIR, exist_ok=True)
os.makedirs(OUT_DIR, exist_ok=True)

write_case("1_sample", SAMPLE)

edges = ["a", "ab", "ba", "aa", "bbaa", "abab", "c", "z",
         "a" * 10000, "b" + "a" * 9999, "a" * 9999 + "b",
         "ab" * 5000, "zyxwvutsrqponmlkjihgfedcba", "abcdefghijklmnopqrstuvwxyz"]
write_case("2_edges", edges)

rng = random.Random(20240606)
wide = []
for _ in range(100):
    style = rng.randint(0, 3)
    if style == 0:
        wide.append(random_necklace(rng, 10000, "abcdefghijklmnopqrstuvwxyz"))
    elif style == 1:
        wide.append(random_necklace(rng, 10000, "ab"))
    elif style == 2:
        wide.append("a" * 9999 + "b")
    else:
        wide.append("c" * 5000 + random_necklace(rng, 5000, "abc"))
write_case("3_wide", wide)

random_cases = []
for _ in range(500):
    length = rng.randint(1, 300)
    alphabet = "abcdefghijklmnopqrstuvwxyz"[: rng.randint(2, 26)]
    random_cases.append(random_necklace(rng, length, alphabet))
for _ in range(50):
    period = rng.randint(1, 12)
    unit = random_necklace(rng, period, "abcde")
    random_cases.append(unit * (10000 // period))
write_case("4_random", random_cases)

io_cases = []
for _ in range(100000):
    io_cases.append(random_necklace(rng, 100, "abcdefghijklmnopqrstuvwxyz"))
write_case("5_io", io_cases)

print("gen.py wrote 5 cases")
