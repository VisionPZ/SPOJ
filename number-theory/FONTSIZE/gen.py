#!/usr/bin/env python3
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def fits(size, width, height, words):
    if size <= 0:
        return True
    tolerance = 1e-10
    character_width = 2 * size / 3
    lines_used = 1
    line_width = 0.0
    for word in words:
        word_width = len(word) * character_width
        if word_width > width + tolerance:
            return False
        separator = character_width if line_width > 0 else 0.0
        if line_width + separator + word_width <= width + tolerance:
            line_width += separator + word_width
        else:
            lines_used += 1
            if lines_used * size > height + tolerance:
                return False
            line_width = word_width
    return lines_used * size <= height + tolerance


def exact_fits(scaled, width, height, words):
    if scaled <= 0:
        return True
    allowed_lines = (height * 1000) // scaled
    if allowed_lines <= 0:
        return False
    used_lines = 1
    used_width = Fraction(0)
    for word in words:
        word_width = Fraction(2 * scaled * len(word), 3000)
        if word_width > width:
            return False
        separator = Fraction(2 * scaled, 3000) if used_width > 0 else Fraction(0)
        if used_width + separator + word_width <= width:
            used_width += separator + word_width
        else:
            used_lines += 1
            if used_lines > allowed_lines:
                return False
            used_width = word_width
    return True


def oracle(text):
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    width, height = (int(value) for value in lines[0].split())
    words = " ".join(lines[1:]).split()
    low = 0.0
    high = float(max(height, width * 3 // 2) + 1)
    for _ in range(90):
        middle = (low + high) / 2
        if fits(middle, width, height, words):
            low = middle
        else:
            high = middle
    guess = int(low * 1000 + 0.5)
    scaled = 0
    for candidate in range(guess + 3, max(-1, guess - 4), -1):
        if candidate >= 0 and exact_fits(candidate, width, height, words):
            scaled = candidate
            break
    whole = scaled // 1000
    fraction = scaled % 1000
    if fraction == 0:
        return str(whole) + "\n"
    return str(whole) + "." + str(fraction).rstrip("0") + "\n"


def format_case(width, height, message):
    return str(width) + " " + str(height) + "\n" + message + "\n"


SAMPLE = """60 25
The lazy brown dog
"""
SAMPLE_OUT = "10\n"
SECOND = """50 50
The lazy brown dog
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SECOND) == "12.5\n"
assert oracle(format_case(0, 10, "abc")) == "0\n"
assert oracle(format_case(10, 0, "abc")) == "0\n"
assert oracle(format_case(10, 10, "a")) == "10\n"
assert oracle(format_case(100, 100, "a b")) == "50\n"
assert fits(10, 60, 25, ["The", "lazy", "brown", "dog"])
assert not fits(11, 60, 25, ["The", "lazy", "brown", "dog"])


def write(name, width, height, message):
    text = format_case(width, height, message)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 0, 10, "abc")
    write("3_wide", 7500, 7500, " ".join(["abcde" * 4] * 500))
    rng = random.Random(20261126)
    words = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta"]
    message = " ".join(rng.choice(words) for _ in range(1600))
    write("4_random", rng.randint(1, 7500), rng.randint(1, 7500), message)
    message_io = " ".join(rng.choice(words) for _ in range(2000))
    write("5_io", 7500, 7500, message_io)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
