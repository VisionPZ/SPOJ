#!/usr/bin/env python3
from pathlib import Path
from itertools import combinations
import random

ROOT = Path(__file__).resolve().parent
SAMPLE_TRANSCRIPT = "B" * 48


def apply_ball(state, player):
    points, games, set_points = state
    if points[player] == 3 and all(other <= 2 for index, other in enumerate(points) if index != player):
        pass
    elif points[player] == 4:
        pass
    else:
        advantage = next((index for index, value in enumerate(points) if index != player and value == 4), None)
        if advantage is not None:
            points[advantage] -= 1
            points[player] += 1
            return False
        points[player] += 1
        return False
    for index in range(len(points)):
        points[index] = 0
    games[player] += 1
    if games[player] >= 6 and all(games[player] - games[index] >= 2 for index in range(len(games)) if index != player):
        worth = 2 if all(games[index] == 0 for index in range(len(games)) if index != player) else 1
        set_points[player] += worth
        for index in range(len(games)):
            games[index] = 0
        if set_points[player] >= 3:
            return True
    return False


def copy_state(state):
    return ([value for value in state[0]], [value for value in state[1]], [value for value in state[2]])


def oracle(player_count, transcript):
    state = ([0] * player_count, [0] * player_count, [0] * player_count)
    for letter in transcript:
        if apply_ball(state, ord(letter) - 65):
            return letter
    return None


def oracle_text(cases):
    return "".join(oracle(player_count, transcript) + "\n" for player_count, transcript in cases)


def can_end(state):
    return any(apply_ball(copy_state(state), player) for player in range(len(state[0])))


def generate_random(rng, player_count, target_length):
    champion = rng.randrange(player_count)
    state = ([0] * player_count, [0] * player_count, [0] * player_count)
    letters = []
    while True:
        ending = [player for player in range(player_count) if apply_ball(copy_state(state), player)]
        if len(letters) >= target_length and ending:
            letters.append(chr(65 + (champion if champion in ending else ending[0])))
            return "".join(letters)
        safe = [player for player in range(player_count) if not apply_ball(copy_state(state), player)]
        if not safe:
            letters.append(chr(65 + (champion if champion in ending else rng.randrange(player_count))))
            return "".join(letters)
        if len(letters) < target_length:
            player = champion if champion in safe and rng.random() < 0.85 else rng.choice(safe)
        else:
            advancing = []
            for candidate in safe:
                advanced = copy_state(state)
                apply_ball(advanced, candidate)
                if can_end(advanced):
                    advancing.append(candidate)
            if advancing:
                player = champion if champion in advancing else rng.choice(advancing)
            else:
                player = rng.choice(safe)
        apply_ball(state, player)
        letters.append(chr(65 + player))
        if len(letters) > target_length + 3000:
            raise RuntimeError("generator could not finish a complete match")


def long_transcript(winner_index, player_count, length):
    winner = chr(65 + winner_index)
    other = chr(65 + ((winner_index + 1) % player_count))
    extra = length - 51
    assert extra >= 0 and extra % 2 == 0
    return (winner + other) * 3 + (other + winner) * (extra // 2) + winner + winner * 44


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        f"{player_count} {transcript}\n" for player_count, transcript in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(cases))


assert oracle(3, SAMPLE_TRANSCRIPT) == "B"
assert oracle(2, "A" * 48) == "A"
assert oracle(10, "J" * 48) == "J"
assert oracle(2, "A" * 47) is None
assert len(long_transcript(0, 2, 49999)) == 49999
assert oracle(2, long_transcript(0, 2, 49999)) == "A"


def brute_crosscheck():
    checked = 0
    for player_count in (2, 3):
        for winner_index in range(player_count):
            for noise_index in range(player_count):
                if noise_index == winner_index:
                    continue
                for noise_count in (0, 1, 2):
                    length = 48 + noise_count
                    for positions in combinations(range(length), noise_count):
                        letters = [chr(65 + winner_index)] * length
                        for position in positions:
                            letters[position] = chr(65 + noise_index)
                        transcript = "".join(letters)
                        if oracle(player_count, transcript[:-1]) is not None:
                            continue
                        result = oracle(player_count, transcript)
                        if result is not None:
                            assert result == transcript[-1]
                            checked += 1
    assert checked > 100


brute_crosscheck()

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

write("1_sample", [(3, SAMPLE_TRANSCRIPT)])

write("2_edges", [
    (2, "A" * 48),
    (2, "B" * 48),
    (3, "C" * 48),
    (10, "F" * 48),
    (10, "J" * 48),
    (2, long_transcript(0, 2, 103)),
])

write("3_wide", [
    (2, long_transcript(0, 2, 49999)),
    (10, long_transcript(9, 10, 49999)),
])

rng = random.Random(20261125)
random_cases = []
for _ in range(150):
    player_count = rng.randint(2, 10)
    transcript = generate_random(rng, player_count, rng.randint(48, 2500))
    assert oracle(player_count, transcript) == transcript[-1]
    random_cases.append((player_count, transcript))
write("4_random", random_cases)

io_cases = []
for index in range(38):
    player_count = 2 if index % 2 == 0 else 10
    winner_index = 0 if index % 4 == 0 else player_count - 1
    io_cases.append((player_count, long_transcript(winner_index, player_count, 49999)))
write("5_io", io_cases)

for player_count, transcript in io_cases:
    assert oracle(player_count, transcript) == transcript[-1]
