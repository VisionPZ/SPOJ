#!/usr/bin/env python3
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def is_prime(value):
    if value < 2:
        return False
    if value % 2 == 0:
        return value == 2
    divisor = 3
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 2
    return True


def oracle(text):
    tokens = text.split()
    pos = 0
    count = int(tokens[pos]); pos += 1
    answers = []
    for _ in range(count):
        name = tokens[pos]; pos += 1
        added = int(tokens[pos]); pos += 1
        prime_name = any(is_prime(ord(ch) + added) for ch in name)
        answers.append("YES" if prime_name else "NO")
    return "\n".join(answers) + ("\n" if answers else "")


SAMPLE = "2\nMina 20\nShimul 60\n"
SAMPLE_OUT = "YES\nNO\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert is_prime(2) and is_prime(97)
assert not is_prime(1) and not is_prime(143) and not is_prime(169)
assert oracle("1\nMina 20\n") == "YES\n"
assert oracle("1\nShimul 60\n") == "NO\n"


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(
        f"{person} {added}\n" for person, added in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ("A", 0), ("A", 1), ("z", 0), ("z", 9999), ("Mina", 20),
        ("Mina", 0), ("Shimul", 60), ("B", 9999), ("b", 9999),
    ])
    write("3_wide", [
        ("abcdefghijklmnopqrs", 9999), ("ABCDEFGHIJKLMNOPQRS", 9999),
        ("ZZZZZZZZZZZZZZZZZZZ", 0), ("aaaaaaaaaaaaaaaaaaa", 1),
        ("Minaaaaaaaaaaaaaaaaa", 9999), ("Shimulllllllllllllll", 9999),
    ])
    random.seed(2026)
    letters = string.ascii_letters
    rnd = []
    for _ in range(99):
        person = "".join(random.choice(letters) for _ in range(random.randint(1, 19)))
        rnd.append((person, random.randint(0, 9999)))
    write("4_random", rnd)
    rnd_io = []
    for _ in range(99):
        person = "".join(random.choice(letters) for _ in range(19))
        rnd_io.append((person, random.randint(0, 9999)))
    write("5_io", rnd_io)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [("Mina", 20), ("Shimul", 60)])
build()
print("trace: Mina+20 -> 97 prime -> YES; Shimul+60 -> no prime -> NO")
