#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

TABLE = {
    'cs': {'Kamen': 'Rock', 'Nuzky': 'Scissors', 'Papir': 'Paper'},
    'en': {'Rock': 'Rock', 'Scissors': 'Scissors', 'Paper': 'Paper'},
    'fr': {'Pierre': 'Rock', 'Ciseaux': 'Scissors', 'Feuille': 'Paper'},
    'de': {'Stein': 'Rock', 'Schere': 'Scissors', 'Papier': 'Paper'},
    'hu': {'Ko': 'Rock', 'Koe': 'Rock', 'Ollo': 'Scissors', 'Olloo': 'Scissors', 'Papir': 'Paper'},
    'it': {'Sasso': 'Rock', 'Roccia': 'Rock', 'Forbice': 'Scissors', 'Carta': 'Paper', 'Rete': 'Paper'},
    'jp': {'Guu': 'Rock', 'Choki': 'Scissors', 'Paa': 'Paper'},
    'pl': {'Kamien': 'Rock', 'Nozyce': 'Scissors', 'Papier': 'Paper'},
    'es': {'Piedra': 'Rock', 'Tijera': 'Scissors', 'Papel': 'Paper'},
}
WINNING_PAIRS = {('Rock', 'Scissors'), ('Scissors', 'Paper'), ('Paper', 'Rock')}

SAMPLE = """cs Pepik
en Johnny
Nuzky Scissors
Papir Rock
Papir Scissors
-
de Gertruda
cs Lenka
Stein Papir
Schere Kamen
.
"""
SAMPLE_OUT = """Game #1:
Pepik: 1 point
Johnny: 1 point
TIED GAME

Game #2:
Gertruda: 0 points
Lenka: 2 points
WINNER: Lenka

"""


def oracle(text):
    tokens = text.split()
    cursor = 0
    output_parts = []
    game_number = 0
    while cursor < len(tokens):
        first_language = tokens[cursor]
        first_name = tokens[cursor + 1]
        second_language = tokens[cursor + 2]
        second_name = tokens[cursor + 3]
        cursor += 4
        game_number += 1
        first_points = 0
        second_points = 0
        while True:
            marker = tokens[cursor]
            cursor += 1
            if marker in ('-', '.'):
                last_game = marker == '.'
                break
            first_shape = TABLE[first_language][marker]
            second_shape = TABLE[second_language][tokens[cursor]]
            cursor += 1
            if first_shape != second_shape:
                if (first_shape, second_shape) in WINNING_PAIRS:
                    first_points += 1
                else:
                    second_points += 1
        first_label = 'point' if first_points == 1 else 'points'
        second_label = 'point' if second_points == 1 else 'points'
        lines = [
            f"Game #{game_number}:",
            f"{first_name}: {first_points} {first_label}",
            f"{second_name}: {second_points} {second_label}",
        ]
        if first_points == second_points:
            lines.append('TIED GAME')
        elif first_points > second_points:
            lines.append(f'WINNER: {first_name}')
        else:
            lines.append(f'WINNER: {second_name}')
        output_parts.append("\n".join(lines) + "\n\n")
        if last_game:
            break
    return "".join(output_parts)


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("en Ann\nfr Bob\nRock Ciseaux\n.\n") == "Game #1:\nAnn: 1 point\nBob: 0 points\nWINNER: Ann\n\n"
assert oracle("en Ann\nen Bob\nPaper Paper\n-\nen Cy\nfr Dee\nRock Pierre\n.\n") == (
    "Game #1:\nAnn: 0 points\nBob: 0 points\nTIED GAME\n\n"
    "Game #2:\nCy: 0 points\nDee: 0 points\nTIED GAME\n\n")
assert oracle("it Lu\njp Mika\nRoccia Choki\n-\nhu Ada\npl Ewa\nOlloo Nozyce\n.\n") == (
    "Game #1:\nLu: 1 point\nMika: 0 points\nWINNER: Lu\n\n"
    "Game #2:\nAda: 0 points\nEwa: 0 points\nTIED GAME\n\n")
assert len(TABLE) == 9


def words(language):
    return sorted(TABLE[language].keys())


def game_text(first_language, first_name, second_language, second_name, rounds, terminator):
    lines = [f"{first_language} {first_name}", f"{second_language} {second_name}"]
    for first_word, second_word in rounds:
        lines.append(f"{first_word} {second_word}")
    lines.append(terminator)
    return "\n".join(lines) + "\n"


def write(name, games):
    input_text = "".join(games)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    edges = [
        game_text('en', 'Ann', 'fr', 'Bob', [], '-'),
        game_text('cs', 'Lenka', 'en', 'John', [('Nuzky', 'Scissors')], '-'),
        game_text('hu', 'Ada', 'it', 'Luca', [('Ko', 'Sasso'), ('Olloo', 'Rete')], '-'),
        game_text('jp', 'Ken', 'es', 'Luis', [('Paa', 'Tijera'), ('Choki', 'Papel')], '.'),
    ]
    write("2_edges", edges)
    rng = random.Random(20261126)
    wide_rounds = []
    for _ in range(100):
        wide_rounds.append((rng.choice(words('en')), rng.choice(words('de'))))
    write("3_wide", [game_text('en', 'Wide', 'de', 'Schmal', wide_rounds, '.')])

    random_games = []
    languages = list(TABLE)
    for game_index in range(80):
        first_language = rng.choice(languages)
        second_language = rng.choice(languages)
        round_count = rng.randint(0, 30)
        rounds = []
        for _ in range(round_count):
            rounds.append((rng.choice(words(first_language)), rng.choice(words(second_language))))
        terminator = '-' if game_index < 79 else '.'
        random_games.append(game_text(
            first_language, f"Player{game_index}A", second_language, f"Player{game_index}B",
            rounds, terminator))
    write("4_random", random_games)

    io_games = []
    for game_index in range(2000):
        first_language = rng.choice(languages)
        second_language = rng.choice(languages)
        rounds = []
        for _ in range(rng.randint(0, 2)):
            rounds.append((rng.choice(words(first_language)), rng.choice(words(second_language))))
        terminator = '.' if game_index == 1999 else '-'
        io_games.append(game_text(
            first_language, f"A{game_index}", second_language, f"B{game_index}", rounds, terminator))
    write("5_io", io_games)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
