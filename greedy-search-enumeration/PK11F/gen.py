#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse(text):
    lines = text.splitlines()
    cursor = 0
    near = set()
    while cursor < len(lines) and lines[cursor].strip():
        rule = lines[cursor].strip()
        rule_character = rule[0]
        for paired in rule[1:].strip():
            near.add((rule_character, paired))
            near.add((paired, rule_character))
        cursor += 1
    while cursor < len(lines) and not lines[cursor].strip():
        cursor += 1
    dictionary = []
    while cursor < len(lines) and lines[cursor].strip():
        dictionary.append(lines[cursor].strip())
        cursor += 1
    while cursor < len(lines) and not lines[cursor].strip():
        cursor += 1
    queries = [line.strip() for line in lines[cursor:] if line.strip()]
    return near, dictionary, queries


def edit_distance(source, target, near):
    rows = len(source) + 1
    columns = len(target) + 1
    matrix = [[0] * columns for _ in range(rows)]
    for row in range(rows):
        matrix[row][0] = 2 * row
    for column in range(columns):
        matrix[0][column] = 2 * column
    for row in range(1, rows):
        for column in range(1, columns):
            first_character = source[row - 1]
            second_character = target[column - 1]
            if first_character == second_character:
                cost = 0
            elif (first_character, second_character) in near:
                cost = 1
            else:
                cost = 2
            best = min(matrix[row - 1][column] + 2,
                       matrix[row][column - 1] + 2,
                       matrix[row - 1][column - 1] + cost)
            if row >= 2 and column >= 2 and \
               first_character == target[column - 2] and \
               source[row - 2] == second_character:
                best = min(best, matrix[row - 2][column - 2] + 2)
            matrix[row][column] = best
    return matrix[rows - 1][columns - 1]


def oracle(text):
    near, dictionary, queries = parse(text)
    answers = []
    for query in queries:
        distance = min(edit_distance(query, word, near) for word in dictionary)
        matches = sorted(word for word in dictionary
                         if edit_distance(query, word, near) == distance)
        answers.append(f"{query}:{distance}:" + " ".join(matches))
    return "\n".join(answers) + "\n"


SAMPLE = """a AqQsSzZ
b BgGvVnN
p P0);:oO[{
r R4$fFeEtT
z ZaAxX

a
A
b
B
Z
angel
angle
anger
angry
ABC

x
s
z
xx
xxx
angre
angri
angrt
angel
ACB
BAC
CAB
"""
SAMPLE_OUT = """x:2:A B Z a b
s:1:a
z:1:A Z a
xx:4:A B Z a b
xxx:6:A ABC B Z a b
angre:2:anger angle angry
angri:2:angry
angrt:2:anger angry
angel:0:angel
ACB:2:ABC
BAC:2:ABC
CAB:4:A ABC B
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert len(SAMPLE_OUT.splitlines()) == 12
assert edit_distance("abc", "abc", set()) == 0
assert edit_distance("abc", "", set()) == 6
assert edit_distance("ab", "ba", set()) == 2
assert edit_distance("ab", "ba", {("a", "b")}) == 2


def random_word(rng, alphabet, shortest=1, longest=7):
    return "".join(rng.choice(alphabet) for _ in range(rng.randint(shortest, longest)))


def write(name, rules, dictionary, queries):
    text = "\n".join(rules) + "\n\n" + "\n".join(dictionary) + "\n\n" + "\n".join(queries) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    symbols = "0123456789`~!@#$%^&*()-_=+\\|[{]};:'<>,.?/"
    rules = ["a AqQsSzZ", "b BgGvVnN", "p P0);:oO[{", "r R4$fFeEtT", "z ZaAxX"]
    dictionary = ["a", "A", "b", "B", "Z", "angel", "angle", "anger", "angry", "ABC"]
    write("2_edges", rules, dictionary, ["x", "s", "z", "xx", "angel", "ABC"])
    generated_rules = []
    for character in "abcxyz":
        partners = "".join(rng.choice(letters + symbols) for _ in range(4))
        generated_rules.append(character + " " + partners)
    generated_dictionary = [random_word(rng, letters, 1, 8) for _ in range(24)]
    generated_dictionary += [word.upper() for word in generated_dictionary[:6]]
    generated_queries = [random_word(rng, letters + symbols, 1, 8) for _ in range(20)]
    write("3_wide", generated_rules, generated_dictionary, generated_queries)
    write("4_random", generated_rules,
          [random_word(rng, letters) for _ in range(35)],
          [random_word(rng, letters + symbols, 1, 6) for _ in range(24)])
    write("5_io", generated_rules,
          [random_word(rng, letters, 1, 5) for _ in range(18)],
          [random_word(rng, letters, 1, 5) for _ in range(240)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
