import os
import random


def brute_force(colors):
    count = len(colors)

    def search(left, right):
        if left == right:
            return 0
        best = None
        for split in range(left, right):
            total = search(left, split) + search(split + 1, right)
            left_color = sum(colors[left:split + 1]) % 100
            right_color = sum(colors[split + 1:right + 1]) % 100
            total += left_color * right_color
            if best is None or total < best:
                best = total
        return best

    return search(0, count - 1)


def oracle(colors):
    count = len(colors)
    prefix = [0] * (count + 1)
    for index, color in enumerate(colors):
        prefix[index + 1] = prefix[index] + color
    memo = {}

    def search(left, right):
        key = (left, right)
        if key in memo:
            return memo[key]
        if left == right:
            return 0
        whole_color = (prefix[right + 1] - prefix[left]) % 100
        best = None
        for split in range(left, right):
            left_color = (prefix[split + 1] - prefix[left]) % 100
            right_color = (whole_color - left_color) % 100
            candidate = search(left, split) + search(split + 1, right) + left_color * right_color
            if best is None or candidate < best:
                best = candidate
        memo[key] = best
        return best

    return search(0, count - 1)


assert oracle([18, 19]) == 342 and oracle([40, 60, 20]) == 2400
assert oracle([99, 99]) == 9801
assert oracle([0] * 100) == 0
probe = random.Random(11)
for _ in range(120):
    size = probe.randint(1, 9)
    sample = [probe.randint(0, 99) for _ in range(size)]
    assert oracle(sample) == brute_force(sample)


def write(name, cases):
    input_text = "".join(
        f"{len(colors)}\n" + " ".join(str(color) for color in colors) + "\n"
        for colors in cases
    )
    answer_text = "".join(str(oracle(colors)) + "\n" for colors in cases)
    with open(f"in/{name}.txt", "w") as f:
        f.write(input_text)
    with open(f"out/{name}.out", "w") as f:
        f.write(answer_text)


os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)
SAMPLE = [[18, 19], [40, 60, 20]]
write("1_sample", SAMPLE)
write("2_edges", [
    [0], [99], [1], [0, 0], [99, 99], [50, 50],
    [40, 60, 20], [0, 99, 0], [99, 0, 99], [1, 2, 3, 4, 5],
    [0] * 100, [99] * 100, [50] * 100,
])
write("3_wide", [
    [99] * 100, [0] * 100, [50] * 100,
    list(range(100)), list(range(99, -1, -1)), [99, 0] * 50,
])
rng = random.Random(20261125)
random_cases = []
for _ in range(200):
    size = rng.randint(1, 100)
    random_cases.append([rng.randint(0, 99) for _ in range(size)])
write("4_random", random_cases)
io_cases = []
for _ in range(200000):
    io_cases.append([rng.randint(0, 99), rng.randint(0, 99)])
write("5_io", io_cases)
