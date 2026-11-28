#!/usr/bin/env python3
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ALPHABET = string.ascii_uppercase
VOWEL_SET = set("AEIOU")
LETTER_VALUE = {letter: (ord(letter) - ord('A')) % 9 + 1 for letter in ALPHABET}
VOWELS = [letter for letter in ALPHABET if letter in VOWEL_SET]
CONSONANTS = [letter for letter in ALPHABET if letter not in VOWEL_SET]
VOWEL_ORDER = sorted(VOWELS, key=lambda letter: LETTER_VALUE[letter])
CONSONANT_ORDER = sorted(CONSONANTS, key=lambda letter: (LETTER_VALUE[letter], letter))


def minimum_total(slots, used, by_value, cap):
    total = 0
    left = slots
    for letter in by_value:
        take = min(left, cap - used[letter])
        total += take * LETTER_VALUE[letter]
        left -= take
        if left == 0:
            break
    return total


def build_class(slots, by_value, cap):
    used = {letter: 0 for letter in by_value}
    target = minimum_total(slots, used, by_value, cap)
    result = []
    for placed_count in range(slots):
        chosen = None
        for letter in sorted(by_value):
            if used[letter] >= cap:
                continue
            used[letter] += 1
            left = slots - placed_count - 1
            feasible = minimum_total(left, used, by_value, cap) == target - LETTER_VALUE[letter]
            used[letter] -= 1
            if feasible:
                chosen = letter
                break
        used[chosen] += 1
        target -= LETTER_VALUE[chosen]
        result.append(chosen)
    return result


def solve_length(length):
    vowel_slots = (length + 1) // 2
    consonant_slots = length // 2
    vowels = build_class(vowel_slots, VOWEL_ORDER, 21)
    consonants = build_class(consonant_slots, CONSONANT_ORDER, 5)
    name = []
    for position in range(length):
        name.append(vowels[position // 2] if position % 2 == 0 else consonants[position // 2])
    return "".join(name)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    lengths = tokens[1:1 + case_count]
    lines = []
    for index, length in enumerate(lengths):
        lines.append(f"Case {index + 1}: {solve_length(length)}")
    return "\n".join(lines) + "\n"


def compositions(total, letter_count, cap):
    if letter_count == 1:
        if total <= cap:
            yield (total,)
        return
    for count in range(min(total, cap) + 1):
        for rest in compositions(total - count, letter_count - 1, cap):
            yield (count,) + rest


def brute_name(length):
    vowel_slots = (length + 1) // 2
    consonant_slots = length // 2
    best = None
    for vowel_counts in compositions(vowel_slots, len(VOWELS), 21):
        vowel_value = sum(vowel_counts[i] * LETTER_VALUE[VOWELS[i]] for i in range(len(VOWELS)))
        vowel_units = sorted([VOWELS[i] for i in range(len(VOWELS)) for _ in range(vowel_counts[i])])
        for consonant_counts in compositions(consonant_slots, len(CONSONANTS), 5):
            consonant_value = sum(consonant_counts[i] * LETTER_VALUE[CONSONANTS[i]] for i in range(len(CONSONANTS)))
            consonant_units = sorted([CONSONANTS[i] for i in range(len(CONSONANTS)) for _ in range(consonant_counts[i])])
            units = []
            for position in range(length):
                units.append(vowel_units[position // 2] if position % 2 == 0 else consonant_units[position // 2])
            candidate = (vowel_value + consonant_value, "".join(units))
            if best is None or candidate < best:
                best = candidate
    return best[1]


SAMPLE = "3\n1\n5\n5\n"
SAMPLE_OUT = "Case 1: A\nCase 2: AJAJA\nCase 3: AJAJA\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert solve_length(2) == "AJ"
assert solve_length(12) == "AJAJAJAJAJAS"
assert solve_length(13) == "AJAJAJAJAJASA"
assert LETTER_VALUE['J'] == 1 and LETTER_VALUE['T'] == 2 and LETTER_VALUE['R'] == 9
for check_length in range(1, 7):
    assert solve_length(check_length) == brute_name(check_length)


def write(name, lengths):
    text = str(len(lengths)) + "\n" + "".join(f"{length}\n" for length in lengths)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 21, 22, 41, 42, 43, 44, 209, 210])
    write("3_wide", [210] * 30)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 210) for _ in range(60)])
    write("5_io", [210] * 650)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 5, 5])
build()
