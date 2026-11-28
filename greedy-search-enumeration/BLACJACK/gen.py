#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SYMBOLS = 'A23456789TJQK'
VALUES = {symbol: (1 if symbol == 'A' else (10 if symbol in 'TJQK' else int(symbol))) for symbol in SYMBOLS}


def play_round(deck, position):
    player = deck[position] + deck[position + 2]
    dealer = deck[position + 1] + deck[position + 3]
    used = 4
    hits = 0
    while hits < 3 and player <= 15:
        player += deck[position + used]
        used += 1
        hits += 1
        if player > 21:
            return 0, used
        if hits == 3:
            break
    if hits == 3:
        return 1, used
    hits = 0
    while hits < 3 and dealer <= 15:
        dealer += deck[position + used]
        used += 1
        hits += 1
        if dealer > 21:
            return 1, used
        if hits == 3:
            break
    if hits == 3:
        return 0, used
    return (1 if player > dealer else 0), used


def simulate(deck, keep):
    position = 0
    wins = 0
    while len(deck) - position >= keep:
        result, used = play_round(deck, position)
        wins += result
        position += used
    return wins


def oracle_case(deck, keep):
    best = 0
    size = len(deck)
    for first_cut in range(1, size - 1):
        for second_cut in range(first_cut, size - 1):
            cut_deck = deck[first_cut:second_cut + 1] + deck[:first_cut] + deck[second_cut + 1:]
            wins = simulate(cut_deck, keep)
            if wins > best:
                best = wins
    return best


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while cursor < len(tokens):
        size = int(tokens[cursor]); cursor += 1
        keep = int(tokens[cursor]); cursor += 1
        deck = [VALUES[token] for token in tokens[cursor:cursor + size]]
        cursor += size
        answers.append(oracle_case(deck, keep))
    return ''.join(f"Case {index}: {answer}\n" for index, answer in enumerate(answers, 1))


SAMPLE_IN = (
    "20 10\n8 4 7 8 8 K 5 A Q Q A Q 6 4 J 6 9 5\n3 9\n"
    "40 10\n3 J 7 7 2 T J 6 A 4 4 8 J T 6 A 6 2 K 9\n"
    "6 5 7 J T 3 5 5 3 7 7 J 5 3 A 5 9 Q 6 7\n"
)
SAMPLE_OUT = "Case 1: 3\nCase 2: 6\n"
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert simulate([1] * 10, 10) == 1
assert oracle_case([1, 10] * 10, 10) >= 0
for small_size in range(20, 26):
    deck = [2 + (index % 8) for index in range(small_size)]
    assert oracle_case(deck, 10) >= 0


def render(decks):
    pieces = []
    for deck, keep in decks:
        symbols = [next(symbol for symbol, value in VALUES.items() if value == card) for card in deck]
        pieces.append(f"{len(deck)} {keep}\n" + " " + " ".join(symbols) + "\n")
    return "".join(pieces)


def write(name, decks):
    text = render(decks)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write('2_edges', [([1] * 20, 10), ([10] * 20, 10)])
    write('3_wide', [([rng.randint(1, 10) for _ in range(60)], 10) for rng in [random.Random(11)] for _ in range(3)])
    rng = random.Random(20261126)
    write('4_random', [([rng.randint(1, 10) for _ in range(rng.randint(20, 60))], rng.randint(10, 20))
                       for _ in range(5)])
    write('5_io', [([rng.randint(1, 10) for _ in range(70)], 10) for _ in range(8)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
