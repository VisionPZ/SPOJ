import itertools
import os
import random


MOVES = ("U", "L", "R", "LL", "RR")


def parse(text):
    tokens = text.split()
    cursor = 0
    initial_track = int(tokens[cursor]) - 1
    cursor += 1
    initial_energy = int(tokens[cursor])
    cursor += 1
    level_count = int(tokens[cursor])
    cursor += 1
    hurdles = []
    for _ in range(3):
        hurdles.append([int(tokens[cursor + index]) for index in range(level_count)])
        cursor += level_count
    left_drink = [int(tokens[cursor + index]) for index in range(level_count - 1)]
    cursor += level_count - 1
    right_drink = [int(tokens[cursor + index]) for index in range(level_count - 1)]
    return initial_track, initial_energy, hurdles, left_drink, right_drink


def render(case):
    initial_track, initial_energy, hurdles, left_drink, right_drink = case
    lines = [f"{initial_track + 1} {initial_energy} {len(hurdles[0])}"]
    for track_values in hurdles:
        lines.append(" ".join(str(value) for value in track_values))
    lines.append(" ".join(str(value) for value in left_drink))
    lines.append(" ".join(str(value) for value in right_drink))
    return "\n".join(lines) + "\n"


def simulate(case, path):
    initial_track, initial_energy, hurdles, left_drink, right_drink = case
    track = initial_track
    energy = initial_energy
    for gap, group in enumerate(path):
        steps = 2 if len(group) == 2 else (0 if group == "U" else 1)
        direction = 1 if "R" in group else -1
        for step in range(steps):
            if gap > 0:
                boundary = track if direction == 1 else track - 1
                energy += left_drink[gap - 1] if boundary == 0 else right_drink[gap - 1]
            if energy <= 0:
                return None
            track += direction
            if not 0 <= track < 3:
                return None
        energy -= hurdles[track][gap]
        if energy <= 0:
            return None
    return energy


def brute_answer(case):
    level_count = len(case[2][0])
    best_energy = -1
    best_path = None
    ties = 0
    for path in itertools.product(MOVES, repeat=level_count):
        energy = simulate(case, path)
        if energy is None:
            continue
        if energy > best_energy:
            best_energy = energy
            best_path = path
            ties = 0
        elif energy == best_energy:
            ties += 1
    if best_path is None:
        return "GAME OVER!\n", ties
    return "DONE IT!\n" + "-".join(best_path) + "\n", ties


def dp_answer(case):
    initial_track, initial_energy, hurdles, left_drink, right_drink = case
    level_count = len(hurdles[0])
    current = [-10**12, -10**12, -10**12]
    current[initial_track] = initial_energy
    parents = []
    for gap in range(level_count):
        following = [-10**12, -10**12, -10**12]
        layer = [(-1, False)] * 9
        chosen = [-1, -1, -1]
        for source in range(3):
            if current[source] <= 0:
                continue
            for target in range(3):
                energy = current[source]
                right = target > source
                distance = abs(target - source)
                for step in range(distance):
                    if gap > 0:
                        boundary = source + step if right else source - 1 - step
                        energy += left_drink[gap - 1] if boundary == 0 else right_drink[gap - 1]
                    if energy <= 0:
                        break
                else:
                    energy -= hurdles[target][gap]
                    if energy > 0 and energy > following[target]:
                        following[target] = energy
                        if chosen[target] >= 0:
                            layer[target * 3 + chosen[target]] = (-1, False)
                        chosen[target] = source
                        layer[target * 3 + source] = (source, right)
        parents.append(layer)
        current = following
    target = max(range(3), key=lambda track_index: current[track_index])
    if current[target] <= 0:
        return "GAME OVER!\n"
    groups = [""] * level_count
    for gap in range(level_count - 1, -1, -1):
        source = next(candidate for candidate in range(3) if parents[gap][target * 3 + candidate][0] >= 0)
        right = parents[gap][target * 3 + source][1]
        groups[gap] = "U" if source == target else ("R" if right else "L") * abs(target - source)
        target = source
    return "DONE IT!\n" + "-".join(groups) + "\n"


SAMPLE = """1 6 5
3 2 9 16 3
4 0 7 26 1
1 7 3 30 9
8 19 8 3
10 3 6 4
"""
SAMPLE_OUT = """DONE IT!
RR-LL-RR-LL-R
"""
SAMPLE_CASE = parse(SAMPLE)
assert brute_answer(SAMPLE_CASE)[0] == SAMPLE_OUT
assert brute_answer(SAMPLE_CASE)[1] == 0
assert dp_answer(SAMPLE_CASE) == SAMPLE_OUT


def emit(name, cases, use_brute=False):
    os.makedirs("in", exist_ok=True)
    os.makedirs("out", exist_ok=True)
    for case_index, case in enumerate(cases, 1):
        stem = name if name == "1_sample" else f"{name}_{case_index}"
        with open(os.path.join("in", stem + ".txt"), "w", encoding="utf-8") as stream:
            stream.write(render(case))
        if use_brute:
            answer, ties = brute_answer(case)
            assert ties == 0, (name, "ambiguous optimum")
            assert dp_answer(case) == answer, (name, "oracle disagreement")
        else:
            answer = dp_answer(case)
        with open(os.path.join("out", stem + ".out"), "w", encoding="utf-8") as stream:
            stream.write(answer)


def make_case(rng, level_count):
    hurdles = [[rng.randint(1, 60) for _ in range(level_count)] for _ in range(3)]
    left_drink = [rng.randint(1, 40) for _ in range(level_count - 1)]
    right_drink = [rng.randint(1, 40) for _ in range(level_count - 1)]
    return rng.randint(0, 2), rng.randint(30, 80), hurdles, left_drink, right_drink


def main():
    os.makedirs("in", exist_ok=True)
    os.makedirs("out", exist_ok=True)

    emit("1_sample", [SAMPLE_CASE], use_brute=True)

    edges = [
        (0, 10, [[5], [1], [3]], [], []),
        (2, 1, [[5], [1], [3]], [], []),
        (1, 4, [[2, 3], [9, 8], [7, 6]], [20], [1]),
        (0, 20, [[3, 5, 4], [4, 3, 5], [5, 4, 3]], [3, 2], [4, 1]),
    ]
    emit("2_edges", edges, use_brute=True)

    rng = random.Random(20261127)
    wide = []
    for level_count in (7, 40, 400):
        case = make_case(rng, level_count)
        if level_count <= 7:
            emit_case = [case]
            answer, ties = brute_answer(case)
            assert ties == 0
            assert dp_answer(case) == answer
        wide.append(case)
    emit("3_wide", wide)

    random_cases = []
    while len(random_cases) < 40:
        case = make_case(rng, rng.randint(1, 6))
        _, ties = brute_answer(case)
        if ties == 0:
            random_cases.append(case)
    emit("4_random", random_cases, use_brute=True)

    emit("5_io", [make_case(rng, 200000)])


if __name__ == "__main__":
    main()
