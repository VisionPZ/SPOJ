#!/usr/bin/env python3
import random
import re
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent

WINNING = re.compile(
    r'0*(?:1|011|110|'
    r'11(?:01)*(?:00|00(?:11)+|(?:11)+00|(?:11)*1011|1101(?:11)*)(?:10)*11|'
    r'11(?:01)*(?:11)*01|'
    r'10(?:11)*(?:10)*11)0*\Z')


def oracle(board):
    return WINNING.match(board) is not None


def brute_force(board):
    n = len(board)
    start = 0
    for i, c in enumerate(board):
        if c == '1':
            start |= 1 << i
    seen = set()
    stack = [start]
    while stack:
        state = stack.pop()
        if state in seen:
            continue
        seen.add(state)
        if state.bit_count() == 1:
            return True
        for i in range(n - 2):
            if (state & (3 << i)) == (3 << i) and not (state & (1 << (i + 2))):
                stack.append(state ^ (3 << i) ^ (1 << (i + 2)))
            if (state & (3 << (i + 1))) == (3 << (i + 1)) and not (state & (1 << i)):
                stack.append(state ^ (3 << (i + 1)) ^ (1 << i))
    return False


def winning_moves(board):
    n = len(board)
    start = 0
    for i, c in enumerate(board):
        if c == '1':
            start |= 1 << i
    queue = deque([start])
    parent = {start: None}
    while queue:
        state = queue.popleft()
        if state.bit_count() == 1:
            path = []
            while state is not None:
                path.append(''.join('1' if state & (1 << i) else '0' for i in range(n)))
                state = parent[state]
            return list(reversed(path))
        for i in range(n - 2):
            if (state & (3 << i)) == (3 << i) and not (state & (1 << (i + 2))):
                nxt = state ^ (3 << i) ^ (1 << (i + 2))
                if nxt not in parent:
                    parent[nxt] = state
                    queue.append(nxt)
            if (state & (3 << (i + 1))) == (3 << (i + 1)) and not (state & (1 << i)):
                nxt = state ^ (3 << (i + 1)) ^ (1 << i)
                if nxt not in parent:
                    parent[nxt] = state
                    queue.append(nxt)
    return []


def write(name, boards):
    input_text = str(len(boards)) + '\n' + ''.join(
        f'{len(board)}\n{board}\n' for board in boards)
    (ROOT / 'in' / f'{name}.txt').write_text(input_text)
    output_text = ''.join(('yes' if oracle(board) else 'no') + '\n' for board in boards)
    (ROOT / 'out' / f'{name}.out').write_text(output_text)


for length in range(1, 13):
    for mask in range(1 << length):
        board = ''.join('1' if mask & (1 << i) else '0' for i in range(length))
        assert oracle(board) == brute_force(board), board

assert oracle('1') and not oracle('0')
assert not oracle('11') and oracle('110') and oracle('011')
assert oracle('0110011') and not oracle('111001')
assert not oracle('1' * 32000) and not oracle('0' * 32000)
assert oracle('1' + '0' * 31999)

SAMPLE = ['0110011', '111001']
write('1_sample', SAMPLE)

EDGES = [
    '1', '0', '01', '10', '11', '101', '011', '110', '111', '1111',
    '0' * 32000, '1' * 32000, '1' + '0' * 31999, '0' * 31999 + '1',
    '11' + '0' * 31998, '0' * 31998 + '11',
]
write('2_edges', EDGES)

random.seed(2026)
sparse = ['0'] * 32000
for i in random.sample(range(32000), 50):
    sparse[i] = '1'
WIDE = [
    '0' * 32000,
    '1' * 32000,
    '01' * 16000,
    '10' * 16000,
    '1' + '0' * 31999,
    '0' * 31999 + '1',
    '110' + '0' * 31997,
    '0' * 31997 + '011',
    ''.join(sparse),
    ''.join(random.choice('01') for _ in range(32000)),
]
write('3_wide', WIDE)

RANDOM = []
for _ in range(300):
    n = random.randint(1, 60)
    density = random.choice([0.15, 0.35, 0.55, 0.8])
    RANDOM.append(''.join('1' if random.random() < density else '0' for _ in range(n)))
write('4_random', RANDOM)

IO = [''.join(random.choice('01') for _ in range(random.randint(1, 16)))
      for _ in range(50000)]
write('5_io', IO)

print('worked example for 0110011:')
for state in winning_moves('0110011'):
    print(state)
