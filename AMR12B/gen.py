#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        attacks = tokens[cursor]
        anomaly_count = tokens[cursor + 1]
        cursor += 2
        anomalies = []
        for _ in range(anomaly_count):
            anomalies.append((tokens[cursor], tokens[cursor + 1]))
            cursor += 2
        beats = [[False] * attacks for _ in range(attacks)]
        for low in range(attacks):
            for high in range(low + 1, attacks):
                beats[high][low] = True
        for weaker, stronger in anomalies:
            beats[weaker - 1][stronger - 1] = True
            beats[stronger - 1][weaker - 1] = False
        best_score = 0
        best_attack = 0
        for first in range(attacks):
            counters = [other for other in range(attacks)
                        if other != first and beats[other][first]]
            if not counters:
                score = 2
            else:
                score = 1
                for counter in counters:
                    reply = any(beats[third][counter] for third in range(attacks)
                                if third != first and third != counter)
                    if not reply:
                        score = 0
                        break
            if score > best_score:
                best_score = score
                best_attack = first + 1
        if best_score == 2:
            answers.append(f"2 {best_attack}")
        else:
            answers.append(str(best_score))
    return "\n".join(answers) + "\n"


SAMPLE = "2\n3 0\n3 1\n1 3\xa0\n"
SAMPLE_OUT = "2 3\n1\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3 0\n") == "2 3\n"
assert oracle("1\n4 2\n2 3\n2 4\n") == "2 2\n"
assert oracle("1\n4 2\n1 4\n2 3\n") == "1\n"


def write_cases(name, cases):
    pieces = [str(len(cases))]
    for attacks, anomalies in cases:
        pieces.append(f"{attacks} {len(anomalies)}")
        for weaker, stronger in anomalies:
            pieces.append(f"{weaker} {stronger}")
    text = "\n".join(pieces) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def write_known(name, text, expected):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(expected)


def build():
    write_cases("2_edges", [
        (3, []), (3, [(1, 3)]), (4, [(2, 3), (2, 4)]),
        (4, [(1, 4), (2, 3)]), (5, [(1, 5), (2, 5), (3, 5), (4, 5)]),
    ])
    wide_input = "2\n1000000 1\n1 1000000\n1000000 0\n"
    write_known("3_wide", wide_input, "1\n2 1000000\n")
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(20):
        attacks = rng.randint(3, 12)
        pairs = [(low, high) for low in range(1, attacks + 1)
                 for high in range(low + 1, attacks + 1)]
        rng.shuffle(pairs)
        count = rng.randint(0, len(pairs))
        random_cases.append((attacks, sorted(pairs[:count])))
    write_cases("4_random", random_cases)
    io_cases = []
    for _ in range(15):
        pairs = [(low, high) for low in range(1, 13) for high in range(low + 1, 13)]
        rng.shuffle(pairs)
        io_cases.append((12, sorted(pairs[:40])))
    write_cases("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
