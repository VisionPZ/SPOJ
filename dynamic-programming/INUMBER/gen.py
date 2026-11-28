#!/usr/bin/env python3
from collections import deque
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def oracle(target):
    predecessors = [[] for _ in range(target)]
    for previous in range(target):
        predecessors[(previous * 10) % target].append(previous)

    need = [[INF] * target for _ in range(target + 1)]
    for remainder in range(target):
        steps = 0
        current = remainder
        while current != 0 and steps <= target:
            current = (current * 10) % target
            steps += 1
        need[target][remainder] = steps if current == 0 else INF

    for digit_sum in range(target - 1, -1, -1):
        row = need[digit_sum]
        for remainder in range(target):
            best = INF
            for digit in range(1, 10):
                if digit_sum + digit > target:
                    break
                candidate = need[digit_sum + digit][(remainder * 10 + digit) % target]
                if candidate + 1 < best:
                    best = candidate + 1
            row[remainder] = best
        queue = deque(remainder for remainder in range(target) if row[remainder] < INF)
        while queue:
            remainder = queue.popleft()
            cost = row[remainder] + 1
            for previous in predecessors[remainder]:
                if cost < row[previous]:
                    row[previous] = cost
                    queue.append(previous)

    length = need[0][0]
    assert length < INF
    digit_sum = 0
    remainder = 0
    digits = []
    for position in range(length):
        lower = 1 if position == 0 else 0
        remaining = length - position
        for digit in range(lower, 10):
            if digit_sum + digit > target:
                break
            next_sum = digit_sum + digit
            next_remainder = (remainder * 10 + digit) % target
            if need[next_sum][next_remainder] + 1 == remaining:
                digits.append(str(digit))
                digit_sum = next_sum
                remainder = next_remainder
                break
        else:
            raise AssertionError(('greedy stuck', target, position))
    answer = ''.join(digits)
    assert int(answer) % target == 0
    assert sum(int(digit) for digit in answer) == target
    return answer


def brute(target):
    seen = [[False] * (target + 1) for _ in range(target)]
    queue = deque()
    for digit in range(1, 10):
        if digit > target:
            break
        remainder = digit % target
        if seen[remainder][digit]:
            continue
        seen[remainder][digit] = True
        if remainder == 0 and digit == target:
            return str(digit)
        queue.append((remainder, digit, str(digit)))
    while queue:
        remainder, digit_sum, number = queue.popleft()
        for digit in range(10):
            next_sum = digit_sum + digit
            if next_sum > target:
                continue
            next_remainder = (remainder * 10 + digit) % target
            if seen[next_remainder][next_sum]:
                continue
            seen[next_remainder][next_sum] = True
            next_number = number + str(digit)
            if next_remainder == 0 and next_sum == target:
                return next_number
            queue.append((next_remainder, next_sum, next_number))
    raise AssertionError(('no answer', target))


@lru_cache(maxsize=None)
def cached(target):
    return oracle(target)


def write(name, values):
    input_text = str(len(values)) + '\n' + ''.join(f'{value}\n' for value in values)
    (ROOT / 'in' / f'{name}.txt').write_text(input_text)
    (ROOT / 'out' / f'{name}.out').write_text(
        '\n'.join(cached(value) for value in values) + '\n')


assert oracle(1) == '1'
assert oracle(10) == '190'
assert oracle(11) == '209'
assert oracle(100) == '19999999999900'
for small in range(1, 40):
    assert oracle(small) == brute(small)


def build():
    write('2_edges', [1, 2, 9, 10, 11, 12, 99, 100, 999, 1000])
    write('3_wide', [1000, 999, 1000, 998, 997, 1000, 1, 2, 3, 1000])
    import random
    random.seed(20261124)
    write('4_random', [random.randint(1, 1000) for _ in range(50)])
    write('5_io', [1000] * 50)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
write('1_sample', [1, 10])
build()
