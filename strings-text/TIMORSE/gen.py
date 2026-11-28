#!/usr/bin/env python3
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CODES = {
    "a": ".-", "b": "-...", "c": "-.-.", "d": "-..", "e": ".", "f": "..-.",
    "g": "--.", "h": "....", "i": "..", "j": ".---", "k": "-.-", "l": ".-..",
    "m": "--", "n": "-.", "o": "---", "p": ".--.", "q": "--.-", "r": ".-.",
    "s": "...", "t": "-", "u": "..-", "v": "...-", "w": ".--", "x": "-..-",
    "y": "-.--", "z": "--..",
}


def oracle(text):
    lines = text.split("\n")
    count = int(lines[0])
    answers = []
    for message in lines[1:1 + count]:
        timeline = []
        previous_letter = False
        for char in message:
            if char in CODES:
                if previous_letter:
                    timeline.append(3)
                elif timeline:
                    timeline.append(7)
                for index, symbol in enumerate(CODES[char]):
                    if index:
                        timeline.append(1)
                    timeline.append(3 if symbol == "-" else 1)
                previous_letter = True
            elif char == " ":
                previous_letter = False
        answers.append(f"{message}: length = {sum(timeline)}")
    return "\n".join(answers) + "\n"


def alternate(message):
    words = [word for word in message.split(" ") if word]
    lengths = []
    for word in words:
        letters = [char for char in word if char in CODES]
        for char in letters:
            code = CODES[char]
            lengths.append(2 * code.count("-") + 2 * len(code) - 1)
        lengths.append(3 * (len(letters) - 1))
    return sum(lengths) + 7 * (len(words) - 1) if words else 0


SAMPLE = """2
hi joe
sos
"""
SAMPLE_OUT = """hi joe: length = 51
sos: length = 27
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\nhi\njoe\nhi joe\n") == "hi: length = 13\njoe: length = 31\nhi joe: length = 51\n"
assert oracle("1\nsos\n") == "sos: length = 27\n"
assert oracle("1\n  hi   joe  \n") == "  hi   joe  : length = 51\n"
for message in ["hi", "joe", "hi joe", "sos", "a b c", "z z", "abc!def"]:
    assert alternate(message) == int(
        oracle(f"1\n{message}\n").split(" = ")[1].strip())


def write(name, messages):
    text = str(len(messages)) + "\n" + "\n".join(messages) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["", "e", "t", "a a", "   ", "s o s", "hello!world"])
    write("3_wide", [("abcdefghijklmnopqrstuvwxyz " * 3).strip() for _ in range(5)])
    rng = random.Random(20261126)
    pool = string.ascii_lowercase + "   !?.,"
    messages = []
    for _ in range(150):
        length = rng.randint(1, 80)
        messages.append("".join(rng.choice(pool) for _ in range(length)))
    write("4_random", messages)
    io_messages = [("message number " + str(index)) * 3 for index in range(2500)]
    write("5_io", io_messages)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE.splitlines()[1:])
build()
