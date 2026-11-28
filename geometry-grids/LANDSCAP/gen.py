import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INFINITY = 10**18

SAMPLE_ELEVATIONS = [1, 2, 3, 3, 3, 2, 1, 3, 2, 2, 1, 2]


def peak_count(values):
    total = 0
    index = 0
    while index < len(values):
        end = index
        while end + 1 < len(values) and values[end + 1] == values[index]:
            end += 1
        left_ok = index == 0 or values[index - 1] < values[index]
        right_ok = end == len(values) - 1 or values[end + 1] < values[index]
        if left_ok and right_ok:
            total += 1
        index = end + 1
    return total


def brute_force(elevations, budget):
    candidates = []
    for height in elevations:
        candidates.append([value for value in sorted(set(elevations)) if value <= height])
    best = INFINITY
    for choice in itertools.product(*candidates):
        cost = sum(height - chosen for height, chosen in zip(elevations, choice))
        if cost < best and peak_count(choice) <= budget:
            best = cost
    return best


def reverse_oracle(elevations, budget):
    values = sorted(set(elevations))
    level_count = len(values)
    index_of = {value: position + 1 for position, value in enumerate(values)}
    peak_run = [[INFINITY] * (budget + 1) for _ in range(level_count + 2)]
    valley_run = [[INFINITY] * (budget + 1) for _ in range(level_count + 2)]
    last_height = elevations[len(elevations) - 1]
    for level in range(1, index_of[last_height] + 1):
        peak_run[level][0] = last_height - values[level - 1]
    for position in range(len(elevations) - 2, -1, -1):
        height = elevations[position]
        top = index_of[height]
        new_peak = [[INFINITY] * (budget + 1) for _ in range(level_count + 2)]
        new_valley = [[INFINITY] * (budget + 1) for _ in range(level_count + 2)]
        for chosen in range(1, top + 1):
            add = height - values[chosen - 1]
            for count in range(budget + 1):
                for previous in range(1, level_count + 1):
                    if previous == chosen:
                        new_peak[chosen][count] = min(new_peak[chosen][count], peak_run[previous][count] + add)
                        new_valley[chosen][count] = min(new_valley[chosen][count], valley_run[previous][count] + add)
                    elif previous < chosen:
                        new_peak[chosen][count] = min(new_peak[chosen][count], peak_run[previous][count] + add)
                        new_peak[chosen][count] = min(new_peak[chosen][count], valley_run[previous][count] + add)
                    else:
                        new_valley[chosen][count] = min(new_valley[chosen][count], valley_run[previous][count] + add)
                        if count > 0:
                            new_valley[chosen][count] = min(new_valley[chosen][count], peak_run[previous][count - 1] + add)
        peak_run, valley_run = new_peak, new_valley
    best = INFINITY
    for level in range(1, level_count + 1):
        for count in range(budget):
            best = min(best, peak_run[level][count])
        for count in range(budget + 1):
            best = min(best, valley_run[level][count])
    return best


def input_text(cases):
    parts = [str(len(cases))]
    for elevations, budget in cases:
        parts.append(str(len(elevations)) + " " + str(budget))
        for height in elevations:
            parts.append(str(height))
    return "\n".join(parts) + "\n"


def write(name, cases):
    text = input_text(cases)
    answers = [reverse_oracle(elevations, budget) for elevations, budget in cases]
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text("".join(str(answer) + "\n" for answer in answers))


assert peak_count(SAMPLE_ELEVATIONS) == 3
assert brute_force(SAMPLE_ELEVATIONS, 1) == 5
assert reverse_oracle(SAMPLE_ELEVATIONS, 1) == 5
assert reverse_oracle(SAMPLE_ELEVATIONS, 2) == 1
assert reverse_oracle([1000000, 1, 1000000], 1) == 999999
assert brute_force([2, 1, 2], 1) == 1

checker = random.Random(4242)
for trial in range(300):
    size = checker.randint(1, 6)
    sample = [checker.randint(1, 4) for _ in range(size)]
    limit = checker.randint(1, 3)
    assert brute_force(sample, limit) == reverse_oracle(sample, limit)


def sawtooth(size, high, step):
    return [1 + ((index // step) % 2) * (high - 1) for index in range(size)]


def alternating(size, low, high):
    return [high if index % 2 == 0 else low for index in range(size)]


def plateaus(size, width, high):
    return [1 + ((index // width) % high) for index in range(size)]


def staircase(size, high):
    middle = size // 2
    return [1 + min(index, size - 1 - index) * (high - 1) // max(1, middle) for index in range(size)]


def spikes(size, high):
    return [high if index % 17 == 0 else 1 for index in range(size)]


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

write("1_sample", [(SAMPLE_ELEVATIONS, 1)])

write("2_edges", [
    ([1], 1),
    ([1000000], 1),
    ([1, 1], 1),
    ([2, 1], 1),
    ([1, 2], 1),
    ([2, 1, 2], 1),
    ([2, 1, 2], 2),
    ([5, 5, 5, 5], 1),
    ([1, 2, 3, 4, 5], 1),
    ([5, 4, 3, 2, 1], 1),
    ([1000000, 1, 1000000], 1),
    (SAMPLE_ELEVATIONS, 25),
])

write("3_wide", [
    (alternating(1000, 1, 2), 1),
    (sawtooth(1000, 4, 3), 3),
    (plateaus(1000, 7, 6), 25),
    (staircase(1000, 12), 1),
    (spikes(1000, 1000000), 2),
    ([x * 100000 for x in alternating(1000, 1, 10)], 5),
])

rng = random.Random(20261125)
random_cases = []
for trial in range(12):
    size = rng.randint(1, 1000)
    budget = rng.randint(1, 25)
    heights = [rng.randint(1, 12) for _ in range(size)]
    random_cases.append((heights, budget))
write("4_random", random_cases)

io_cases = []
for index in range(60000):
    if index % 2 == 0:
        io_cases.append(([1000000, 1, 1000000], 1))
    else:
        io_cases.append(([1, 1000000, 1, 1000000], 1))
write("5_io", io_cases)

print("generated", len(random_cases), "random cases and", len(io_cases), "io cases")
