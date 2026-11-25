#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = (
    "1\n"
    "A 4 2 3 6 5 7 8 9 10 J K Q 2 3 4 5 6 7 8 J Q 8 9 5 4\n"
    "7 2 4\n"
)
SAMPLE_OUTPUT = "7\n"

SYMBOL_VALUES = {"A": 4, "J": 1, "Q": 2, "K": 3}
for number in range(2, 11):
    SYMBOL_VALUES[str(number)] = number
ALLOWED_CHOSEN = ["J", "5", "6", "7", "8", "9", "10"]
DECK_SYMBOLS = ["A", "J", "Q", "K"] + [str(number) for number in range(2, 11)]


def card_value(token):
    return SYMBOL_VALUES[token]


def simulate_case(plate_tokens, chosen_tokens):
    plate = [card_value(token) for token in plate_tokens]
    chosen = [card_value(token) for token in chosen_tokens]
    remaining_deck = 26
    borrowed = 0
    for value in chosen:
        needed = 11 - value
        from_deck = min(needed, remaining_deck)
        remaining_deck -= from_deck
        still_needed = needed - from_deck
        if still_needed > 0:
            del plate[:still_needed]
            borrowed += still_needed
    index = sum(chosen)
    plate_position = index - remaining_deck
    assert 1 <= plate_position <= len(plate)
    return plate[plate_position - 1], remaining_deck, borrowed, index, plate_position


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        plate_tokens = tokens[cursor:cursor + 26]
        cursor += 26
        chosen_tokens = tokens[cursor:cursor + 3]
        cursor += 3
        answer, remaining_deck, borrowed, index, plate_position = simulate_case(
            plate_tokens, chosen_tokens)
        assert index == remaining_deck + plate_position
        answers.append(str(answer))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert simulate_case(["2"] * 6 + ["A"] + ["3"] * 19, ["7", "2", "4"])[0] == 4
assert simulate_case(["2"] * 6 + ["10"] + ["3"] * 19, ["J", "J", "J"])[0] == 10
assert simulate_case(["2"] * 6 + ["K"] + ["3"] * 19, ["10", "10", "10"])[0] == 3
assert oracle("2\n" + "2 " * 6 + "A " + "3 " * 19 + "7 2 4\n"
              + "2 " * 6 + "J " + "3 " * 19 + "J J J\n") == "4\n1\n"


def write(name, cases):
    lines = [str(len(cases))]
    for plate_tokens, chosen_tokens in cases:
        lines.append(" ".join(plate_tokens))
        lines.append(" ".join(chosen_tokens))
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def random_case(rng, forced_seventh=None):
    plate_tokens = [rng.choice(DECK_SYMBOLS) for _ in range(26)]
    if forced_seventh is not None:
        plate_tokens[6] = forced_seventh
    chosen_tokens = [rng.choice(ALLOWED_CHOSEN) for _ in range(3)]
    return plate_tokens, chosen_tokens


def trace():
    plate_tokens = SAMPLE_INPUT.splitlines()[1].split()[:26]
    chosen_tokens = SAMPLE_INPUT.splitlines()[2].split()
    result = simulate_case(plate_tokens, chosen_tokens)
    print(f"chosen values {[card_value(token) for token in chosen_tokens]}, "
          f"index {result[3]}")
    print(f"deck leftovers {result[1]}, borrowed {result[2]}, "
          f"plate position {result[4]}, value {result[0]}")
    plate_tokens = ["2"] * 6 + ["10"] + ["3"] * 19
    result = simulate_case(plate_tokens, ["J", "J", "J"])
    print(f"chosen values [1, 1, 1], index {result[3]}")
    print(f"deck leftovers {result[1]}, borrowed {result[2]}, "
          f"plate position {result[4]}, value {result[0]}")


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        sample_plate = SAMPLE_INPUT.splitlines()[1].split()[:26]
        sample_chosen = SAMPLE_INPUT.splitlines()[2].split()
        write("1_sample", [(sample_plate, sample_chosen)])
        write("2_edges", [
            (["A"] + ["2"] * 25, ["7", "2", "4"]),
            (["2"] * 6 + ["10"] + ["3"] * 19, ["J", "J", "J"]),
            (["2"] * 6 + ["K"] + ["3"] * 19, ["10", "10", "10"]),
        ])
        rng = random.Random(2026)
        write("3_wide", [random_case(rng, "10") for _ in range(5000)])
        write("4_random", [random_case(rng) for _ in range(5000)])
        write("5_io", [random_case(rng, "10") for _ in range(20000)])
