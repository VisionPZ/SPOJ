#!/usr/bin/env python3
import itertools
import random
from collections import deque
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(maxsize=None)
def minimum_turns(player_count, target_wins):
    start = (player_count,) + (0,) * (target_wins - 1)
    visited = {start}
    queue = deque([(start, 0)])
    while queue:
        state, elapsed = queue.popleft()
        choices = [range(count // 2 + 1) for count in state]
        for games in itertools.product(*choices):
            following = [0] * target_wins
            following[0] = state[0] % 2 + sum(games)
            for level in range(1, target_wins):
                following[level] = state[level] % 2 + games[level - 1]
            if games[target_wins - 1] > 0:
                return elapsed + 1
            following = tuple(following)
            if following not in visited:
                visited.add(following)
                queue.append((following, elapsed + 1))
    return 0


def oracle(text):
    pairs = []
    for line in text.split():
        pairs.append(int(line))
    answers = []
    for index in range(0, len(pairs) - 1, 2):
        player_count = pairs[index]
        target_wins = pairs[index + 1]
        if player_count == 0 and target_wins == 0:
            break
        answers.append('Case {}: {}'.format(
            len(answers) + 1, minimum_turns(player_count, target_wins)))
    return ''.join(answer + '\n' for answer in answers)


SAMPLE_IN = '''2 1
10 5
15 10
0 0
'''
SAMPLE_OUT = '''Case 1: 1
Case 2: 11
Case 3: 210
'''
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert minimum_turns(2, 1) == 1
assert minimum_turns(3, 2) == 3
assert minimum_turns(8, 7) == 58
assert minimum_turns(20, 12) == 588


def write(name, pairs):
    text = ''.join('{} {}\n'.format(player_count, target_wins)
                   for player_count, target_wins in pairs) + '0 0\n'
    (ROOT / 'in' / '{}.txt'.format(name)).write_text(text)
    (ROOT / 'out' / '{}.out'.format(name)).write_text(oracle(text))


def build():
    write('2_edges', [(2, 1), (3, 1), (3, 2), (4, 1), (4, 3), (5, 4),
                      (6, 5), (7, 6), (8, 7)])
    write('3_wide', [(20, target) for target in range(1, 13)])
    rng = random.Random(20261126)
    pairs = []
    for _ in range(60):
        player_count = rng.randint(2, 20)
        pairs.append((player_count, rng.randint(1, player_count - 1)))
    write('4_random', pairs)
    write('5_io', [(20, 12) for _ in range(300)])


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE_IN)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUT)
build()
