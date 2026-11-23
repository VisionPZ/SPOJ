import os
import random


def brute_supers(permutation):
    count = len(permutation)
    best_length = 0
    winners = set()

    def walk(position, previous_value, chosen):
        nonlocal best_length, winners
        if position == count:
            current = len(chosen)
            if current > best_length:
                best_length = current
                winners = set(chosen)
            elif current == best_length and current > 0:
                winners.update(chosen)
            return
        walk(position + 1, previous_value, chosen)
        value = permutation[position]
        if value > previous_value:
            chosen.append(value)
            walk(position + 1, value, chosen)
            chosen.pop()

    walk(0, -1, [])
    return sorted(winners)


def bit_supers(permutation):
    count = len(permutation)
    tree = [0] * (count + 2)
    ending = [0] * count
    for position, value in enumerate(permutation):
        best = 0
        index = value - 1
        while index > 0:
            if tree[index] > best:
                best = tree[index]
            index -= index & -index
        length = best + 1
        ending[position] = length
        index = value
        while index <= count:
            if tree[index] < length:
                tree[index] = length
            index += index & -index
    longest = max(ending)

    tree = [0] * (count + 2)
    starting = [0] * count
    for position in range(count - 1, -1, -1):
        value = permutation[position]
        best = 0
        index = count - value
        while index > 0:
            if tree[index] > best:
                best = tree[index]
            index -= index & -index
        length = best + 1
        starting[position] = length
        index = count + 1 - value
        while index <= count:
            if tree[index] < length:
                tree[index] = length
            index += index & -index

    result = []
    for position in range(count):
        if ending[position] + starting[position] - 1 == longest:
            result.append(permutation[position])
    return sorted(result)


assert brute_supers([2, 1, 4, 5, 3]) == [1, 2, 4, 5]
assert brute_supers([1, 2, 3]) == [1, 2, 3]
assert brute_supers([3, 2, 1]) == [1, 2, 3]
assert brute_supers([2, 3, 1, 4]) == [2, 3, 4]
check_rng = random.Random(7)
for _ in range(200):
    small = list(range(1, 9))
    check_rng.shuffle(small)
    assert bit_supers(small) == brute_supers(small)
assert bit_supers(list(range(1, 1001))) == list(range(1, 1001))
assert bit_supers(list(range(1000, 0, -1))) == list(range(1, 1001))


oracle_cache = {}


def write(name, cases):
    with open(f"in/{name}.txt", "w") as input_file, open(f"out/{name}.out", "w") as output_file:
        for permutation in cases:
            key = tuple(permutation)
            if key not in oracle_cache:
                oracle_cache[key] = bit_supers(permutation)
            supers = oracle_cache[key]
            input_file.write(f"{len(permutation)}\n")
            input_file.write(" ".join(str(value) for value in permutation) + "\n")
            output_file.write(f"{len(supers)}\n")
            output_file.write(" ".join(str(value) for value in supers) + "\n")


os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

write("1_sample", [[2, 1, 4, 5, 3]])

write("2_edges", [
    [1], [1, 2], [2, 1], [2, 1, 3], [2, 3, 1, 4],
    [5, 4, 3, 2, 1], [1, 2, 3, 4, 5], [3, 2, 1, 6, 5, 4],
    [1, 3, 2], [4, 1, 3, 2],
])

size = 100000
identity = list(range(1, size + 1))
reverse = identity[::-1]
pattern = [2, 1, 4, 5, 3]
sawtooth = []
while len(sawtooth) < size:
    offset = len(sawtooth)
    sawtooth.extend([value + offset for value in pattern])
sawtooth = sawtooth[:size]

generator = random.Random(20261123)
shuffled = []
for _ in range(14):
    permutation = identity[:]
    generator.shuffle(permutation)
    shuffled.append(permutation)

write("3_wide", [identity, reverse, shuffled[0], sawtooth, shuffled[1]])
write("4_random", shuffled[2:12])
write("5_io", [identity for _ in range(10)])

print("generated five pairs with a Fenwick-tree oracle")
