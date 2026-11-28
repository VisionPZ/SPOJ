#!/usr/bin/env python3
import itertools
import random
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent

RANK_ORDER = "AKQJT98765432"
VALUE = {"A": 14, "K": 13, "Q": 12, "J": 11, "T": 10,
         "9": 9, "8": 8, "7": 7, "6": 6, "5": 5, "4": 4, "3": 3, "2": 2}
STRAIGHT_SETS = [frozenset(RANK_ORDER[start:start + 5]) for start in range(len(RANK_ORDER) - 4)]
STRAIGHT_SETS.append(frozenset("A5432"))
ROYAL_SET = frozenset("AKQJT")
SHAPE_LABELS = {
    (4, 1): "four of a kind",
    (3, 2): "full house",
    (3, 1, 1): "three of a kind",
    (2, 2, 1): "two pairs",
    (2, 1, 1, 1): "pair",
}


def oracle_hand(cards):
    ranks = [card[0] for card in cards]
    suits = [card[1] for card in cards]
    rank_set = frozenset(ranks)
    is_flush = len(set(suits)) == 1
    is_straight = rank_set in STRAIGHT_SETS
    shape = tuple(sorted(Counter(ranks).values(), reverse=True))
    if shape == (1, 1, 1, 1, 1):
        if is_flush and rank_set == ROYAL_SET:
            return "royal flush"
        if is_flush and is_straight:
            return "straight flush"
        if is_flush:
            return "flush"
        if is_straight:
            return "straight"
        return "high card"
    return SHAPE_LABELS[shape]


def brute_hand(cards):
    values = sorted(VALUE[card[0]] for card in cards)
    suits = [card[1] for card in cards]
    flush = all(suit == suits[0] for suit in suits)
    distinct = sorted(set(values))
    straight = False
    if len(distinct) == 5:
        straight = distinct[-1] - distinct[0] == 4 or distinct == [2, 3, 4, 5, 14]
    counts = sorted((values.count(value) for value in distinct), reverse=True)
    if flush and straight and distinct == [10, 11, 12, 13, 14]:
        return "royal flush"
    if flush and straight:
        return "straight flush"
    if counts == [4, 1]:
        return "four of a kind"
    if counts == [3, 2]:
        return "full house"
    if flush:
        return "flush"
    if straight:
        return "straight"
    if counts == [3, 1, 1]:
        return "three of a kind"
    if counts == [2, 2, 1]:
        return "two pairs"
    if counts == [2, 1, 1, 1]:
        return "pair"
    return "high card"


SAMPLE = [
    "AH KH QH TH JH",
    "KH 5S 3C 5C 7D",
    "QH QD 2S QC 2C",
]
KNOWN = SAMPLE + [
    "AD 2D 3D 4D 5D",
    "2S 2H 2D 2C 4D",
    "4C 3C 2C AC KC",
    "4C 9C TC AC KC",
    "5H AS 2C 3D 4C",
    "5H 5D 5C 7H KS",
    "2H 2S 4C 4S 5D",
    "AH 4S 9C TD 3H",
]
SMALL_DECK = [rank + suit for suit in "SH" for rank in RANK_ORDER]

assert len(STRAIGHT_SETS) == 10 and ROYAL_SET in STRAIGHT_SETS
assert [oracle_hand(hand.split()) for hand in SAMPLE] == ["royal flush", "pair", "full house"]
assert [oracle_hand(hand.split()) for hand in KNOWN] == [
    "royal flush", "pair", "full house", "straight flush", "four of a kind",
    "flush", "flush", "straight", "three of a kind", "two pairs", "high card",
]
assert all(oracle_hand(hand) == brute_hand(hand) for hand in itertools.combinations(SMALL_DECK, 5))


def write(name, hands):
    input_text = str(len(hands)) + "\n" + "".join(hand + "\n" for hand in hands)
    output_text = "".join(oracle_hand(hand.split()) + "\n" for hand in hands)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


EDGE_HANDS = KNOWN + ["AS KS QS JS TS", "2C 3C 4C 5C AC", "7H 8D 9C TH JS"]

WIDE_HANDS = [
    "AH KH QH TH JH", "AS KS QS JS TS",
    "AD 2D 3D 4D 5D", "9C TC JC QC KC",
    "2S 2H 2D 2C 4D", "AH AD AC AS KH",
    "QH QD 2S QC 2C", "3H 3D 3C 7S 7D",
    "4C 9C TC AC KC", "2H 5H 8H JH KH",
    "5H AS 2C 3D 4C", "7H 8D 9C TH JS",
    "5H 5D 5C 7H KS", "QC QD QS 4H 9C",
    "2H 2S 4C 4S 5D", "AH AD KC KD 9S",
    "KH 5S 3C 5C 7D", "AS QH QD 3C 8S",
    "AH 4S 9C TD 3H", "2D 6C 8H JS 4S",
]

rng = random.Random(20261125)
DECK = [rank + suit for suit in "SHDC" for rank in RANK_ORDER]
RANDOM_HANDS = [" ".join(rng.sample(DECK, 5)) for _ in range(20)]

IO_HANDS = []
for index in range(20):
    quad_rank = RANK_ORDER[index % 12]
    kicker_rank = RANK_ORDER[(index + 5) % 12]
    if kicker_rank == quad_rank:
        kicker_rank = RANK_ORDER[(index + 6) % 12]
    IO_HANDS.append(" ".join(quad_rank + suit for suit in "SHDC") + " " + kicker_rank + "S")

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
write("2_edges", EDGE_HANDS)
write("3_wide", WIDE_HANDS)
write("4_random", RANDOM_HANDS)
write("5_io", IO_HANDS)
