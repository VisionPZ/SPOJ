#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"


def read_number(text, cursor):
    while cursor < len(text) and text[cursor].isspace():
        cursor += 1
    start = cursor
    while cursor < len(text) and text[cursor].isdigit():
        cursor += 1
    return int(text[start:cursor]), cursor


def read_characters(text, cursor, count):
    collected = ""
    while len(collected) < count:
        while cursor < len(text) and text[cursor].isspace():
            cursor += 1
        collected += text[cursor]
        cursor += 1
    return collected, cursor


def decode_pair(group, second_string):
    answer = ""
    for role in (0, 1):
        number = 0
        for position, character in enumerate(group):
            source_bit = position if role == 0 else (position + 3) % 6
            binary_form = format(ord(character), "08b")
            if binary_form[7 - source_bit] == "1":
                number |= 1 << position
        answer += second_string[number]
    return answer


def oracle(text):
    cursor = 0
    case_count, cursor = read_number(text, cursor)
    answers = []
    for _ in range(case_count):
        tuple_count, cursor = read_number(text, cursor)
        first_string, cursor = read_characters(text, cursor, tuple_count * 6)
        second_string, cursor = read_characters(text, cursor, 64)
        pieces = []
        for start in range(0, len(first_string), 6):
            pieces.append(decode_pair(first_string[start:start + 6], second_string))
        answers.append("".join(pieces))
    return "\n".join(answers) + "\n"


SAMPLE_INPUT = """2
2
qwe345 rf3Arg
XSBSRasdew9873465hkldsfsalndfvnfq489uqovkLKJHaeDaae555Sk5asdpASD

3
2S4J5K 111111 lrtb2A
isimgsow45ipfgisd56wfgngdfcdkgc7kKKKkuuJJgfstdygQdWORQADFSLKF2K8

"""
SAMPLE_OUTPUT = "keep\ncoding\n"
assert decode_pair("qwe345", "XSBSRasdew9873465hkldsfsalndfvnfq489uqovkLKJHaeDaae555Sk5asdpASD") == "ke"
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert decode_pair("AAAAAA", "0123456789" * 7) == "18"


def write(name, cases):
    lines = [str(len(cases))]
    for tuple_count, first_string, second_string in cases:
        lines.append(str(tuple_count))
        groups = [first_string[index:index + 6] for index in range(0, len(first_string), 6)]
        lines.append(" ".join(groups))
        lines.append(second_string)
        lines.append("")
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace():
    group = "qwe345"
    second = "XSBSRasdew9873465hkldsfsalndfvnfq489uqovkLKJHaeDaae555Sk5asdpASD"
    first_number = 0
    second_number = 0
    for position, character in enumerate(group):
        binary_form = format(ord(character), "08b")
        first_bit = binary_form[7 - position]
        paired_bit = binary_form[7 - (position + 3) % 6]
        if first_bit == "1":
            first_number |= 1 << position
        if paired_bit == "1":
            second_number |= 1 << position
        print(f"char {position} {character} bits {binary_form} a-bit {first_bit} b-bit {paired_bit}")
    print(f"a {first_number}, b {second_number}")
    print(f"characters {second[first_number]}{second[second_number]}")


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace()
    else:
        (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
        (ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
        random.seed(2026)
        def random_case(tuple_count):
            first = "".join(random.choice(ALPHABET) for _ in range(tuple_count * 6))
            second = "".join(random.choice(ALPHABET) for _ in range(64))
            return (tuple_count, first, second)
        write("2_edges", [random_case(count) for count in (1, 1, 2, 5, 99)])
        write("3_wide", [random_case(99) for _ in range(10)])
        write("4_random", [random_case(random.randint(1, 30)) for _ in range(50)])
        write("5_io", [random_case(99) for _ in range(99)])
