#!/usr/bin/env python3
"""Test-data generator and statement-derived oracle for EMO.

The rendered statement sample is the five lines below joined with no separator.
The statement note says the third line has a space before its emo: that line
begins with a non-breaking space, and the space is part of the expected output.
"""
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = (
    "Always remember: \u201cFor every problem there is a fast, easy and wrong solution\u201d :P :[ .\n"
    " Sometimes a line :O :T may contain only emoticons like the next  one.\n"
    "\u00a0-_- -__ .\n"
    " And can be of different lengths too -_- -_ .Even if both emoticons in a pair are correct, only one remains, Consider this case: :/ :) .\n"
    "#\n"
)
SAMPLE_OUTPUT = (
    'Always remember: "For every problem there is a fast, easy and wrong solution" :P .\n'
    "Sometimes a line :O may contain only emoticons like the next one.\n"
    "\u00a0-_- .\n"
    "And can be of different lengths too -_- .Even if both emoticons in a pair are correct, only one remains, Consider this case: :/ .\n"
)

FLAT_SAMPLE_INPUT = (
    "Always remember: \u201cFor every problem there is a fast, easy and wrong solution\u201d :P :[ ."
    " Sometimes a line :O :T may contain only emoticons like the next  one.\u00a0-_- -__ ."
    " And can be of different lengths too -_- -_ .Even if both emoticons in a pair are correct, only one remains, Consider this case: :/ :) .#"
)
FLAT_SAMPLE_OUTPUT = (
    'Always remember: "For every problem there is a fast, easy and wrong solution" :P .'
    "Sometimes a line :O may contain only emoticons like the next one.\u00a0-_- ."
    "And can be of different lengths too -_- .Even if both emoticons in a pair are correct, only one remains, Consider this case: :/ ."
)

def is_emoji(word):
    return 2 <= len(word) <= 5 and word[0] in ":->"


def single_space(separator):
    return " "


def leading_space(separator):
    return "\u00a0" if "\u00a0" in separator else " "


def correct_line(raw):
    parts = re.split(r"([ \u00a0]+)", raw)
    words = [(parts[index], parts[index - 1] if index else "")
             for index in range(0, len(parts), 2) if parts[index]]
    kept = []
    pending = False
    for word, separator in words:
        emoji = is_emoji(word)
        if emoji and pending:
            pending = False
            continue
        pending = emoji
        kept.append((word.replace("\u201c", '"').replace("\u201d", '"'), separator))
    if not kept:
        return ""
    pieces = []
    if kept[0][1] and is_emoji(words[0][0]):
        pieces.append(leading_space(kept[0][1]))
    pieces.append(kept[0][0])
    for word, separator in kept[1:]:
        pieces.append(single_space(separator))
        pieces.append(word)
    return "".join(pieces)


def oracle(text):
    corrected_lines = []
    for line in text.split("\n"):
        line = line.rstrip("\r")
        stripped = line.lstrip(" \u00a0")
        if not stripped:
            continue
        if stripped.startswith("#"):
            break
        marker = stripped.find("#")
        if marker != -1:
            stripped = stripped[:marker]
            stop = True
        else:
            stop = False
        leading = line[:len(line) - len(line.lstrip(" \u00a0"))]
        corrected_lines.append(correct_line(leading + stripped))
        if stop:
            break
    return "\n".join(corrected_lines) + ("\n" if corrected_lines else "")


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert "".join(SAMPLE_INPUT.splitlines()) == FLAT_SAMPLE_INPUT
assert "".join(SAMPLE_OUTPUT.splitlines()) == FLAT_SAMPLE_OUTPUT
assert oracle("\u00a0-_- -__ .\n#\n") == "\u00a0-_- .\n"
assert oracle(" Hello :P :[ .\n#\n") == "Hello :P .\n"
assert oracle("Only :P :[ :D :-D .\n#\n") == "Only :P :D .\n"
assert oracle("#\n") == ""
assert oracle("") == ""


def write(name, lines):
    input_text = "\n".join(lines) + "\n#\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


EMOJIS = [":P", ":)", ":D", ":[", ":/", ":O", ":T", ":-P",
          ":>", "-_-", "-__", "-_", ":->", ">:D"]
WORDS = ["Hello", "world", "the", "quick", "brown", "fox", "jumps",
         "over", "lazy", "dog", "Always", "remember", "line", "Consider",
         "this", "case:", "next", "one.", "sentence", "with", "emoticons"]


def make_line(rng):
    entries = [(rng.choice(WORDS), " " * rng.randint(1, 3))
               for _ in range(rng.randint(1, 3))]
    for _ in range(rng.randint(1, 3)):
        first_emo = rng.choice(EMOJIS)
        second_emo = rng.choice(EMOJIS)
        first_separator = ("\u00a0" if rng.random() < 0.1
                           else " " * rng.randint(1, 3))
        entries.append((first_emo, first_separator))
        entries.append((second_emo, " " * rng.randint(1, 3)))
        entries.append((rng.choice(WORDS), " " * rng.randint(1, 3)))
    text = "".join(separator + word for word, separator in entries)
    return " " * rng.randint(0, 2) + text.lstrip(" ") + " ."


def make_leading_emoji_line(rng):
    first = rng.choice(EMOJIS)
    second = rng.choice(EMOJIS)
    return (rng.choice([" ", "  ", "\u00a0"]) + first +
            rng.choice([" ", "   ", "\u00a0"]) + second + " .")


write("1_sample", [
    "Always remember: \u201cFor every problem there is a fast, easy and wrong solution\u201d :P :[ .",
    " Sometimes a line :O :T may contain only emoticons like the next  one.",
    "\u00a0-_- -__ .",
    " And can be of different lengths too -_- -_ .Even if both emoticons in a pair are correct, only one remains, Consider this case: :/ :) .",
])

write("2_edges", [
    ":P :[ .",
    " :-P :-> .",
    "\u00a0-_- -__ .",
    "C :O :T :D :> .",
    "D one.\u00a0-_- -__ .",
    "E :/ :) .",
])

rng = random.Random(2026)
write("3_wide", [make_line(rng) for _ in range(60)] +
      [make_leading_emoji_line(rng) for _ in range(20)])
write("4_random", [make_line(rng) for _ in range(200)] +
      [make_leading_emoji_line(rng) for _ in range(60)])
write("5_io", [make_line(rng) for _ in range(4000)] +
      [make_leading_emoji_line(rng) for _ in range(1000)])
