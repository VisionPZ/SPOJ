#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def gaussian(text):
    tokens = list(map(int, text.split()))
    cursor = 0
    case_count = tokens[cursor]; cursor += 1
    answers = []
    for _ in range(case_count):
        person_count = tokens[cursor]; cursor += 1
        question_count = tokens[cursor]; cursor += 1
        pivots = {}
        bad = False
        for _ in range(person_count):
            first = tokens[cursor] - 1; cursor += 1
            first_answer = tokens[cursor]; cursor += 1
            second = tokens[cursor] - 1; cursor += 1
            second_answer = tokens[cursor]; cursor += 1
            mask = (1 << first) ^ (1 << second)
            rhs = 1 ^ first_answer ^ second_answer
            while mask:
                lead = mask.bit_length() - 1
                if lead not in pivots:
                    pivots[lead] = (mask, rhs)
                    break
                old_mask, old_rhs = pivots[lead]
                mask ^= old_mask
                rhs ^= old_rhs
            else:
                if rhs:
                    bad = True
        if bad:
            answers.append("No Inference")
            continue
        free = question_count - len(pivots)
        if free == question_count:
            answers.append("No Inference")
        else:
            answers.append(str(1 << free))
    return "\n".join(answers) + "\n"


def brute(text):
    tokens = list(map(int, text.split()))
    cursor = 0
    case_count = tokens[cursor]; cursor += 1
    answers = []
    for _ in range(case_count):
        person_count = tokens[cursor]; cursor += 1
        question_count = tokens[cursor]; cursor += 1
        people = []
        for _ in range(person_count):
            first = tokens[cursor] - 1; cursor += 1
            first_answer = tokens[cursor]; cursor += 1
            second = tokens[cursor] - 1; cursor += 1
            second_answer = tokens[cursor]; cursor += 1
            people.append((first, first_answer, second, second_answer))
        total = 0
        for assignment in range(1 << question_count):
            ok = True
            for first, first_answer, second, second_answer in people:
                hits = ((assignment >> first) & 1) == first_answer
                hits += ((assignment >> second) & 1) == second_answer
                if hits != 1:
                    ok = False
                    break
            if ok:
                total += 1
        if total == 0 or total == (1 << question_count):
            answers.append("No Inference")
        else:
            answers.append(str(total))
    return "\n".join(answers) + "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(gaussian(text))


def packet(people, questions):
    return f"{len(people)} {questions}\n" + "".join(
        " ".join(map(str, line)) + "\n" for line in people)


def packets(cases):
    return str(len(cases)) + "\n" + "".join(cases)


SAMPLE = packets([
    packet([(1, 1, 2, 0), (1, 1, 2, 1)], 2),
    packet([(1, 1, 2, 1), (1, 1, 3, 0), (2, 1, 4, 1), (3, 1, 4, 0)], 4),
])
SAMPLE_OUT = "No Inference\n2\n"
assert gaussian(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert gaussian(packets([packet([(1, 0, 2, 0), (1, 1, 2, 0)], 2)])) == "No Inference\n"
assert brute(packets([packet([(1, 0, 2, 0), (1, 1, 2, 0)], 2)])) == "No Inference\n"
assert brute(packets([packet([(1, 0, 2, 0)], 3)])) == "4\n"
assert gaussian(packets([packet([(1, 0, 2, 0)], 3)])) == "4\n"


def build():
    edges = packets([
        packet([(1, 0, 2, 0), (1, 1, 2, 1)], 2),
        packet([(1, 0, 2, 0), (1, 0, 2, 0)], 3),
        packet([(1, 1, 2, 1), (2, 1, 3, 0), (3, 0, 4, 1)], 5),
        packet([(1, 0, 2, 1), (2, 1, 3, 0), (3, 1, 1, 0)], 3),
    ])
    write("2_edges", edges)
    write("3_wide", packets([
        packet([(1, 0, 2, 1)], 200),
        packet([(index + 1, index % 2, index + 2, (index + 1) % 2)
                for index in range(199)], 200),
    ]))
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(60):
        questions = rng.randint(2, 9)
        person_count = rng.randint(1, 14)
        people = []
        for _ in range(person_count):
            first, second = rng.sample(range(1, questions + 1), 2)
            people.append((first, rng.randrange(2), second, rng.randrange(2)))
        random_cases.append(packet(people, questions))
    text = packets(random_cases)
    assert gaussian(text) == brute(text)
    write("4_random", text)
    io_cases = []
    for index in range(2000):
        first = 1 + index % 199
        second = first + 1
        io_cases.append(packet([(first, index % 2, second, 1 - index % 2)], 200))
    write("5_io", packets(io_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
