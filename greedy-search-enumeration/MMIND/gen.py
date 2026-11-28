import random
from itertools import product

SAMPLE_INPUT = """3
4 3 2
1 2 3 2
1 1
2 1 3 2
1 1
4 6 2
3 3 3 3
3 0
4 4 4 4
2 0
8 9 3
1 2 3 4 5 6 7 8
0 0
2 3 4 5 6 7 8 9
1 0
3 4 5 6 7 8 9 9
2 0
"""

SAMPLE_OUTPUT = """1 1 1 3
You are cheating!
9 9 9 9 9 9 9 9
"""


def score_by_matching(secret, guess):
    pin_count = len(secret)
    states = {0: (0, 0)}
    for secret_pos in range(pin_count):
        next_states = dict(states)
        for used_mask, (black, pairs) in states.items():
            for guess_pos in range(pin_count):
                if used_mask & (1 << guess_pos):
                    continue
                if secret[secret_pos] != guess[guess_pos]:
                    continue
                new_mask = used_mask | (1 << guess_pos)
                candidate = (black + (1 if secret_pos == guess_pos else 0), pairs + 1)
                if candidate > next_states.get(new_mask, (-1, -1)):
                    next_states[new_mask] = candidate
        states = next_states
    black, pairs = max(states.values())
    return black, pairs - black


def score_by_counts(secret, guess):
    black = sum(left == right for left, right in zip(secret, guess))
    secret_counts = {}
    guess_counts = {}
    for colour in secret:
        secret_counts[colour] = secret_counts.get(colour, 0) + 1
    for colour in guess:
        guess_counts[colour] = guess_counts.get(colour, 0) + 1
    pairs = 0
    for colour in set(secret_counts) | set(guess_counts):
        pairs += min(secret_counts.get(colour, 0), guess_counts.get(colour, 0))
    return black, pairs - black


def brute_lex_small(pin_count, colour_count, played):
    for secret in product(range(1, colour_count + 1), repeat=pin_count):
        if all(score_by_matching(secret, guess) == hint for guess, hint in played):
            return list(secret)
    return None


def format_case(pin_count, colour_count, played):
    lines = ["%d %d %d" % (pin_count, colour_count, len(played))]
    for guess, hint in played:
        lines.append(" ".join(str(colour) for colour in guess))
        lines.append("%d %d" % hint)
    return lines


def format_answer(answer, pin_count):
    if answer is None:
        return "You are cheating!"
    assert len(answer) == pin_count
    return " ".join(str(colour) for colour in answer)


def verify_small(pin_count, colour_count, played, expected):
    oracle = brute_lex_small(pin_count, colour_count, played)
    assert oracle == expected, (pin_count, colour_count, played, oracle, expected)


assert score_by_matching([1, 2, 3, 4, 1], [1, 3, 1, 1, 4]) == (1, 3)
assert score_by_matching([1, 1, 1, 3], [1, 2, 3, 2]) == (1, 1)
assert score_by_matching([1, 1, 1, 3], [2, 1, 3, 2]) == (1, 1)
assert brute_lex_small(4, 3, [([1, 2, 3, 2], (1, 1)), ([2, 1, 3, 2], (1, 1))]) == [1, 1, 1, 3]
assert brute_lex_small(4, 6, [([3, 3, 3, 3], (3, 0)), ([4, 4, 4, 4], (2, 0))]) is None
assert score_by_matching([9] * 8, [1, 2, 3, 4, 5, 6, 7, 8]) == (0, 0)
assert score_by_matching([9] * 8, [2, 3, 4, 5, 6, 7, 8, 9]) == (1, 0)
assert score_by_matching([9] * 8, [3, 4, 5, 6, 7, 8, 9, 9]) == (2, 0)

rng = random.Random(1)
for trial_index in range(500):
    pin_count = rng.randint(1, 7)
    colour_count = rng.randint(1, 6)
    secret = [rng.randint(1, colour_count) for _ in range(pin_count)]
    guess = [rng.randint(1, colour_count) for _ in range(pin_count)]
    assert score_by_matching(secret, guess) == score_by_counts(secret, guess)

with open("in/1_sample.txt", "w") as handle:
    handle.write(SAMPLE_INPUT)
with open("out/1_sample.out", "w") as handle:
    handle.write(SAMPLE_OUTPUT)

edges = []
edges.append((1, 1, [([1], (1, 0))], [1]))
edges.append((1, 1, [([1], (0, 0))], None))
edges.append((10, 1, [([1] * 10, (10, 0))], [1] * 10))
edges.append((3, 1, [([1, 1, 1], (2, 0))], None))
edges.append((3, 3, [([1, 2, 3], (0, 0))], None))
edges.append((2, 2, [([1, 2], (0, 2))], [2, 1]))
edges.append((3, 2, [([1, 1, 2], (2, 0))], [1, 1, 1]))
edges.append((4, 3, [([1, 2, 3, 2], (1, 1)), ([2, 1, 3, 2], (2, 0))], [2, 3, 3, 3]))
for pin_count, colour_count, played, expected in edges:
    if colour_count ** pin_count <= 20000:
        verify_small(pin_count, colour_count, played, expected)

wide = []
wide.append((10, 100, [([100] * 10, (10, 0))], [100] * 10))
wide.append((10, 100, [([1] * 10, (0, 0))], [2] * 10))
wide.append((10, 100, [([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], (0, 0))], [11] * 10))
wide.append((10, 100, [([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], (1, 0))], [1] * 10))
wide.append((10, 100, [([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], (0, 0)),
                       ([11, 12, 13, 14, 15, 16, 17, 18, 19, 20], (0, 0))], [21] * 10))
heavy_guesses = []
for guess_index in range(100):
    colours = [(colour_index % 99) + 1 for colour_index in range(guess_index, guess_index + 10)]
    heavy_guesses.append((colours, (0, 0)))
wide.append((10, 100, heavy_guesses, [100] * 10))
for pin_count, colour_count, played, expected in wide:
    for guess, hint in played:
        assert score_by_matching(expected, guess) == hint

random_cases = []
for case_index in range(20):
    pin_count = rng.randint(1, 4) if case_index < 18 else 5
    colour_count = rng.randint(1, 4) if case_index < 18 else 5
    guess_count = rng.randint(1, 4)
    played = []
    for _ in range(guess_count):
        guess = [rng.randint(1, colour_count) for _ in range(pin_count)]
        hint = score_by_matching([rng.randint(1, colour_count) for _ in range(pin_count)], guess)
        played.append((guess, hint))
    if case_index % 5 == 4 and played:
        guess, (black, white) = played[0]
        played[0] = (guess, (black, white + 1))
    answer = brute_lex_small(pin_count, colour_count, played)
    random_cases.append((pin_count, colour_count, played, answer))

io_cases = []
for case_index in range(150000):
    io_cases.append((10, 100, [([100] * 10, (10, 0))], [100] * 10))

for name, cases in (("2_edges", edges), ("3_wide", wide), ("4_random", random_cases), ("5_io", io_cases)):
    with open("in/%s.txt" % name, "w") as input_handle, open("out/%s.out" % name, "w") as output_handle:
        input_handle.write("%d\n" % len(cases))
        for pin_count, colour_count, played, expected in cases:
            for line in format_case(pin_count, colour_count, played):
                input_handle.write(line + "\n")
            output_handle.write(format_answer(expected, pin_count) + "\n")
