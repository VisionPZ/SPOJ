import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = (
    "2\n"
    "urjc\n"
    "urjccontesttwo\n"
    "abcdefghijklmnopqrstuvwxyz\n"
    "thequickbrownfoxjumpsoverthelazydog\n"
)
SAMPLE_OUTPUT = "1300\n1750\n"


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        known = set(tokens[cursor])
        cursor += 1
        target = tokens[cursor]
        cursor += 1
        learned = set()
        elapsed = 0
        for letter in target:
            if letter in known or letter in learned:
                elapsed += 50
            else:
                elapsed += 150
                learned.add(letter)
        answers.append(str(elapsed))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\na\na\n") == "50\n"
assert oracle("1\na\nb\n") == "150\n"
assert oracle("1\na\nbb\n") == "200\n"
assert oracle("1\nabcxyz\nzzzz\n") == "200\n"


def write(name, cases):
    lines = [str(len(cases))]
    for known, target in cases:
        lines.append(known)
        lines.append(target)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(input_text))


def random_string(rng, size):
    return "".join(chr(97 + rng.randrange(26)) for _ in range(size))


def build():
    letters = "abcdefghijklmnopqrstuvwxyz"
    write("2_edges", [
        ("a", "a"),
        ("a", "b"),
        ("a", "bb"),
        (letters, letters),
        ("a", "zyxwvutsrqponmlkjihgfedcba"),
    ])
    write("3_wide", [(letters, random_string(random.Random(1), 100000))])
    rng = random.Random(2026)
    write("4_random", [
        (random_string(rng, rng.randint(1, 26)),
         random_string(rng, rng.randint(1, 300)))
        for _ in range(500)
    ])
    rng2 = random.Random(7)
    write("5_io", [
        (random_string(rng2, rng2.randint(1, 26)),
         random_string(rng2, 100000))
        for _ in range(12)
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    ("urjc", "urjccontesttwo"),
    ("abcdefghijklmnopqrstuvwxyz",
     "thequickbrownfoxjumpsoverthelazydog"),
])
build()
