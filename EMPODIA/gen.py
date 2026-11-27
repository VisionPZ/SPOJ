import heapq
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute(seq):
    size = len(seq)
    framed = []
    for left in range(size):
        for right in range(left + 1, size):
            segment = seq[left:right + 1]
            if (min(segment) == seq[left] and max(segment) == seq[right]
                    and seq[right] - seq[left] == right - left):
                framed.append((left, right))
    return [(left, right) for left, right in framed
            if not any(left <= inner_left <= inner_right <= right
                       and (inner_left, inner_right) != (left, right)
                       for inner_left, inner_right in framed)]


def oracle(seq):
    size = len(seq)
    next_smaller = [size] * size
    stack = []
    for index, value in enumerate(seq):
        while stack and seq[stack[-1]] > value:
            next_smaller[stack.pop()] = index
        stack.append(index)
    previous_greater = [-1] * size
    stack = []
    for index, value in enumerate(seq):
        while stack and seq[stack[-1]] < value:
            stack.pop()
        previous_greater[index] = stack[-1] if stack else -1
        stack.append(index)

    key_heaps = {}
    expiry_heap = []
    active = [True] * size
    found = []
    rightmost_start = -1
    for right in range(size):
        while expiry_heap and expiry_heap[0][0] <= right:
            _, expired = heapq.heappop(expiry_heap)
            active[expired] = False
        key = seq[right] - right
        bucket = key_heaps.get(key)
        candidate = -1
        if bucket:
            while bucket and not active[-bucket[0]]:
                heapq.heappop(bucket)
            if bucket:
                candidate = -bucket[0]
        if candidate >= 0 and candidate > previous_greater[right]:
            if candidate > rightmost_start:
                found.append((candidate, right))
                rightmost_start = candidate
        heapq.heappush(expiry_heap, (next_smaller[right], right))
        heapq.heappush(key_heaps.setdefault(key, []), -right)
    return found


def layered(size):
    assert (size - 1) % 3 == 0
    result = []
    value = 0
    while value + 2 < size - 1:
        result.extend((value, value + 2, value + 1))
        value += 3
    result.append(size - 1)
    return result


def valid_permutation(size, rng):
    while True:
        middle = list(range(1, size - 1))
        rng.shuffle(middle)
        result = [0] + middle + [size - 1]
        if all(result[index + 1] != result[index] + 1
               for index in range(size - 1)):
            return result


SAMPLE = [0, 3, 5, 4, 6, 2, 1, 7]

assert oracle(SAMPLE) == [(1, 4)]
assert oracle([0]) == []
assert oracle(layered(10)) == [(0, 3), (3, 6), (6, 9)]
assert len(oracle(layered(301))) == 100
for length in range(1, 8):
    for candidate in itertools.permutations(range(length)):
        assert oracle(candidate) == brute(candidate)


def write(name, cases):
    input_lines = [str(len(cases))]
    output_lines = []
    for sequence in cases:
        input_lines.append(str(len(sequence)))
        input_lines.extend(str(value) for value in sequence)
        pairs = oracle(sequence)
        output_lines.append(str(len(pairs)))
        for left, right in pairs:
            output_lines.append(f"{left + 1} {right + 1}")
    (ROOT / "in" / f"{name}.txt").write_text("\n".join(input_lines) + "\n")
    (ROOT / "out" / f"{name}.out").write_text("\n".join(output_lines) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
generator = random.Random(20261125)
write("1_sample", [SAMPLE])
write("2_edges", [
    [0],
    [0, 2, 1, 3],
    [0, 3, 2, 1, 4],
    [0, 2, 1, 3, 5, 4, 6],
    [0, 2, 1, 3, 5, 4, 6, 8, 7, 9],
    SAMPLE,
])
write("3_wide", [
    valid_permutation(1100000, generator),
    layered(59998),
    valid_permutation(60000, generator),
    valid_permutation(60000, generator),
])
write("4_random", [
    valid_permutation(generator.randint(4, 60000), generator)
    for _ in range(20)
])
write("5_io", [layered(59998) for _ in range(5)])

print("generated five test pairs")
