#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_solution(stones, towers):
    best = [-1]

    def search(tower_index, remaining, value):
        if tower_index == len(towers):
            best[0] = max(best[0], value)
            return
        target = towers[tower_index]
        size = len(remaining)
        for mask in range(1 << size):
            total = 0
            gained = 0
            chosen = []
            for bit in range(size):
                if mask >> bit & 1:
                    exponent, strength = stones[remaining[bit]]
                    total += 1 << exponent
                    gained += strength
                    chosen.append(remaining[bit])
            if total == target:
                next_remaining = [item for item in remaining if item not in chosen]
                search(tower_index + 1, next_remaining, value + gained)

    search(0, list(range(len(stones))), 0)
    return "Plan Failed!" if best[0] < 0 else str(best[0])


def bit_solution(stones, towers):
    if not towers:
        return "0"
    max_level = max([exponent for exponent, _ in stones] + [max(height.bit_length() - 1 for height in towers)])
    requirements = [0] * (max_level + 2)
    for height in towers:
        for index in range(height.bit_length()):
            if (height >> index) & 1:
                requirements[index] += 1
    levels = {}
    for exponent, strength in stones:
        levels.setdefault(exponent, []).append(strength)
    prefixes = {}
    for exponent, strengths in levels.items():
        strengths.sort(reverse=True)
        running = [0]
        for strength in strengths:
            running.append(running[-1] + strength)
        prefixes[exponent] = running
    max_carry = len(stones) + 2
    current = {0: 0}
    for level in range(max_level + 1):
        available = len(levels.get(level, []))
        running = prefixes.get(level, [0])
        needed = requirements[level]
        following = {}
        for carry, value in current.items():
            for used in range(available + 1):
                total = carry + used
                if total < needed or (total - needed) % 2:
                    continue
                next_carry = (total - needed) // 2
                candidate = value + running[used]
                following[next_carry] = max(following.get(next_carry, -1), candidate)
        current = following
        if not current:
            return "Plan Failed!"
    answer = current.get(0, -1)
    return "Plan Failed!" if answer < 0 else str(answer)


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        stone_count = int(tokens[cursor])
        cursor += 1
        stones = []
        for _ in range(stone_count):
            stones.append((int(tokens[cursor]), int(tokens[cursor + 1])))
            cursor += 2
        tower_count = int(tokens[cursor])
        cursor += 1
        towers = []
        for _ in range(tower_count):
            towers.append(int(tokens[cursor]))
            cursor += 1
        answers.append(brute_solution(stones, towers) if len(stones) <= 9 and max(towers or [0]) < 512
                       else bit_solution(stones, towers))
    return "\n".join(answers) + "\n"


SAMPLE = """1
2
2 3
0 4
1
5
"""
SAMPLE_OUT = """7
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0\n1\n2\n") == "Plan Failed!\n"
assert oracle("1\n1\n0 5\n1\n1\n") == "5\n"
assert oracle("1\n2\n0 3\n0 4\n2\n1 1\n") == "7\n"
assert brute_solution([(2, 3), (0, 4)], [5]) == "7"
rng_check = random.Random(41)
for _ in range(150):
    stones = [(rng_check.randint(0, 3), rng_check.randint(1, 6))
              for _ in range(rng_check.randint(0, 8))]
    towers = [rng_check.choice([2, 3, 5, 7]) for _ in range(rng_check.randint(1, 2))]
    assert brute_solution(stones, towers) == bit_solution(stones, towers)


def write_case(name, cases):
    chunks = [str(len(cases))]
    for stones, towers in cases:
        chunks.append(str(len(stones)))
        chunks.extend(f"{exponent} {strength}" for exponent, strength in stones)
        chunks.append(str(len(towers)))
        chunks.extend(str(height) for height in towers)
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [
        ([(2, 3), (0, 4)], [5]),
        ([], [2]),
        ([(0, 5)], [1]),
        ([(0, 1), (0, 2), (0, 3)], [3]),
        ([(1, 4), (0, 2)], [3, 2]),
    ])
    rng = random.Random(20261126)
    wide_stones = [(rng.randint(0, 12), rng.randint(1, 977)) for _ in range(977)]
    wide_towers = [rng.choice([2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31]) for _ in range(97)]
    write_case("3_wide", [(wide_stones, wide_towers)])
    random_cases = []
    for _ in range(10):
        stones = [(rng.randint(0, 6), rng.randint(1, 977)) for _ in range(rng.randint(5, 40))]
        towers = [rng.choice([2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31])
                  for _ in range(rng.randint(1, 8))]
        random_cases.append((stones, towers))
    write_case("4_random", random_cases)
    io_stones = [(rng.randint(0, 10), rng.randint(1, 977)) for _ in range(977)]
    io_towers = [rng.choice([2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31])
                 for _ in range(97)]
    write_case("5_io", [(io_stones, io_towers)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
