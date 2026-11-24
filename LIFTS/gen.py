#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def lcm_values(first, second):
    return first // math.gcd(first, second) * second


def build_arrays(platform):
    low, high, initial, direction = platform
    period = 2 * (high - low) if high > low else 1
    heights = []
    height = initial
    step_direction = direction
    for _ in range(period):
        heights.append(height)
        if step_direction == 1:
            if height < high:
                height += 1
            else:
                height -= 1
                step_direction = -1
        else:
            if height > low:
                height -= 1
            else:
                height += 1
                step_direction = 1
    return heights


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        lift_count = int(tokens[cursor])
        cursor += 1
        platforms = [(0, 0, 0, 1)]
        for _ in range(lift_count):
            low = 2 * int(tokens[cursor])
            high = 2 * int(tokens[cursor + 1])
            initial = 2 * int(tokens[cursor + 2])
            direction = int(tokens[cursor + 3])
            cursor += 4
            platforms.append((low, high, initial, direction))
        platforms.append((0, 0, 0, 1))
        arrays = [build_arrays(platform) for platform in platforms]
        moment = 2
        possible = True
        for index in range(lift_count + 1):
            first = arrays[index]
            second = arrays[index + 1]
            meeting = None
            for offset in range(lcm_values(len(first), len(second))):
                candidate = moment + offset
                if first[candidate % len(first)] == second[candidate % len(second)]:
                    meeting = candidate
                    break
            if meeting is None:
                possible = False
                break
            moment = meeting + (4 if index < lift_count else 2)
        answers.append(str(moment // 2) if possible else "-1")
    return "\n".join(answers) + "\n"


def direct_simulation(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        lift_count = int(tokens[cursor])
        cursor += 1
        platforms = [(0, 0, 0, 1)]
        for _ in range(lift_count):
            low = 2 * int(tokens[cursor])
            high = 2 * int(tokens[cursor + 1])
            initial = 2 * int(tokens[cursor + 2])
            direction = int(tokens[cursor + 3])
            cursor += 4
            platforms.append((low, high, initial, direction))
        platforms.append((0, 0, 0, 1))
        moment = 2
        possible = True
        for index in range(lift_count + 1):
            low_one, high_one, height_one, dir_one = platforms[index]
            low_two, high_two, height_two, dir_two = platforms[index + 1]
            period_one = 2 * (high_one - low_one) if high_one > low_one else 1
            period_two = 2 * (high_two - low_two) if high_two > low_two else 1
            for _ in range(moment % period_one):
                if dir_one == 1:
                    if height_one < high_one:
                        height_one += 1
                    else:
                        height_one -= 1
                        dir_one = -1
                else:
                    if height_one > low_one:
                        height_one -= 1
                    else:
                        height_one += 1
                        dir_one = 1
            for _ in range(moment % period_two):
                if dir_two == 1:
                    if height_two < high_two:
                        height_two += 1
                    else:
                        height_two -= 1
                        dir_two = -1
                else:
                    if height_two > low_two:
                        height_two -= 1
                    else:
                        height_two += 1
                        dir_two = 1
            limit = lcm_values(period_one, period_two)
            if height_one == height_two:
                pass
            else:
                found = False
                for _ in range(1, limit):
                    moment += 1
                    if period_one > 0 and high_one > low_one:
                        if dir_one == 1:
                            if height_one < high_one:
                                height_one += 1
                            else:
                                height_one -= 1
                                dir_one = -1
                        else:
                            if height_one > low_one:
                                height_one -= 1
                            else:
                                height_one += 1
                                dir_one = 1
                    if high_two > low_two:
                        if dir_two == 1:
                            if height_two < high_two:
                                height_two += 1
                            else:
                                height_two -= 1
                                dir_two = -1
                        else:
                            if height_two > low_two:
                                height_two -= 1
                            else:
                                height_two += 1
                                dir_two = 1
                    if height_one == height_two:
                        found = True
                        break
                if not found:
                    possible = False
                    break
            moment += 4 if index < lift_count else 2
        answers.append(str(moment // 2) if possible else "-1")
    return "\n".join(answers) + "\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def cases_to_text(cases):
    lines = [str(len(cases))]
    for case in cases:
        lines.append(str(len(case)))
        for lift in case:
            lines.append(" ".join(str(value) for value in lift))
    return "\n".join(lines) + "\n"


SAMPLE_TEXT = "1\n\n4\n-1 2 1 -1\n0 3 0 1\n-4 0 0 -1\n-2 1 0 -1\n\n"

assert oracle(SAMPLE_TEXT) == "29\n"
assert oracle("1\n1\n0 1 0 1\n") == "5\n"
assert oracle("1\n1\n-2 0 -2 1\n") == "7\n"
assert oracle("1\n2\n-2 -1 -2 1\n1 2 1 1\n") == "-1\n"

for seed in range(40):
    random.seed(seed)
    case = []
    for _ in range(random.randint(1, 4)):
        low = random.randint(-5, 5)
        high = random.randint(low + 1, 8)
        initial = random.randint(low, high)
        case.append((low, high, initial, random.choice([1, -1])))
    text = cases_to_text([case])
    assert oracle(text) == direct_simulation(text)


def build():
    write("1_sample", SAMPLE_TEXT)
    edges = [
        [(0, 1, 0, 1)],
        [(-2, 0, -2, 1)],
        [(-100, 100, 0, -1)],
        [(-2, -1, -2, 1), (1, 2, 1, 1)],
        [(-1, 1, -1, 1), (-1, 1, 1, -1), (-1, 1, 0, 1)],
        [(0, 3, 0, 1), (0, 3, 3, -1)],
    ]
    write("2_edges", cases_to_text(edges))

    random.seed(1207)
    wide = []
    for _ in range(2):
        case = []
        for _ in range(100):
            low = random.randint(-10, 9)
            high = random.randint(low + 1, 10)
            initial = random.randint(low, high)
            case.append((low, high, initial, random.choice([1, -1])))
        wide.append(case)
    for _ in range(2):
        case = []
        for _ in range(10):
            low = random.randint(-100, 99)
            high = random.randint(low + 1, 100)
            initial = random.randint(low, high)
            case.append((low, high, initial, random.choice([1, -1])))
        wide.append(case)
    write("3_wide", cases_to_text(wide))

    random.seed(3301)
    random_cases = []
    for _ in range(40):
        case = []
        for _ in range(random.randint(1, 10)):
            low = random.randint(-12, 11)
            high = random.randint(low + 1, 12)
            initial = random.randint(low, high)
            case.append((low, high, initial, random.choice([1, -1])))
        random_cases.append(case)
    write("4_random", cases_to_text(random_cases))

    random.seed(4409)
    io_cases = []
    for _ in range(50000):
        low = random.randint(-3, 2)
        high = random.randint(low + 1, 3)
        initial = random.randint(low, high)
        io_cases.append([(low, high, initial, random.choice([1, -1]))])
    write("5_io", cases_to_text(io_cases))


def worked_example():
    lift_low, lift_high, lift_initial, lift_direction = -1, 2, 1, -1
    edge = build_arrays((0, 0, 0, 1))
    lift = build_arrays((2 * lift_low, 2 * lift_high, 2 * lift_initial, lift_direction))
    reachable = {}
    for residue, height in enumerate(lift):
        reachable.setdefault(height, []).append(residue)
    lines = ["edge: period 1, height 0 at every residue"]
    lines.append("lift 1: period %d, heights %s" % (len(lift), " ".join(map(str, lift))))
    for height in sorted(reachable):
        if height in edge:
            lines.append("shared height %d: residues %s of lift 1" %
                         (height, ", ".join(map(str, reachable[height]))))
    lines.append("first common time at or after 2: 2 half-seconds")
    lines.append("after 4 half-seconds of walking the hero reaches time 6")
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    import sys
    if "--example" in sys.argv:
        print(worked_example(), end="")
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        build()
