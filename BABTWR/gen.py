import os
import random

def orientations(blocks):
    result = []
    for height, width, depth in blocks:
        result.append((max(width, depth), min(width, depth), height))
        result.append((max(height, depth), min(height, depth), width))
        result.append((max(height, width), min(height, width), depth))
    return result

def tower_height(blocks):
    block_orientations = orientations(blocks)
    large_values = sorted(set(item[0] for item in block_orientations))
    small_values = sorted(set(item[1] for item in block_orientations))
    large_count = len(large_values)
    small_count = len(small_values)
    large_index = {value: index for index, value in enumerate(large_values)}
    small_index = {value: index for index, value in enumerate(small_values)}
    height_at = [[0] * small_count for _ in range(large_count)]
    for large, small, height in block_orientations:
        cell = height_at[large_index[large]][small_index[small]]
        if height > cell:
            height_at[large_index[large]][small_index[small]] = height
    best_at = [[0] * small_count for _ in range(large_count)]
    prefix = [[0] * small_count for _ in range(large_count)]
    for large_pos in range(large_count):
        for small_pos in range(small_count):
            below = prefix[large_pos - 1][small_pos - 1] if large_pos > 0 and small_pos > 0 else 0
            best_at[large_pos][small_pos] = height_at[large_pos][small_pos] + below
            above = prefix[large_pos - 1][small_pos] if large_pos > 0 else 0
            left = prefix[large_pos][small_pos - 1] if small_pos > 0 else 0
            diagonal = prefix[large_pos - 1][small_pos - 1] if large_pos > 0 and small_pos > 0 else 0
            prefix[large_pos][small_pos] = max(best_at[large_pos][small_pos], above, left, diagonal)
    return max(max(row) for row in best_at)

def subset_brute(blocks):
    block_orientations = orientations(blocks)
    total = len(block_orientations)
    best = 0
    for mask in range(1, 1 << total):
        chosen = [block_orientations[pos] for pos in range(total) if mask >> pos & 1]
        chosen.sort(key=lambda item: (-item[0], -item[1]))
        if all(chosen[pos][0] > chosen[pos + 1][0] and chosen[pos][1] > chosen[pos + 1][1]
               for pos in range(len(chosen) - 1)):
            height = sum(item[2] for item in chosen)
            if height > best:
                best = height
    return best

assert tower_height([(31, 41, 59), (26, 53, 58), (97, 93, 23), (84, 62, 64), (33, 83, 27)]) == 342
assert tower_height([(1, 1, 1)]) == 1
assert tower_height([(2, 3, 4)]) == 6
assert tower_height([(2500, 2500, 2500)] * 30) == 2500
for tiny in [[(1, 2, 3)], [(2, 3, 4), (5, 1, 6)], [(3, 3, 5), (4, 2, 2)]]:
    assert tower_height(tiny) == subset_brute(tiny)

def render_case(blocks):
    lines = [str(len(blocks))]
    lines.extend("%d %d %d" % block for block in blocks)
    return "\n".join(lines) + "\n"

def render_expected(cases):
    return "".join("%d\n" % tower_height(blocks) for blocks in cases)

def emit(name, cases):
    with open(os.path.join("in", name + ".txt"), "w", newline="\n") as handle:
        handle.write("".join(render_case(blocks) for blocks in cases) + "0\n")
    with open(os.path.join("out", name + ".out"), "w", newline="\n") as handle:
        handle.write(render_expected(cases))

sample_cases = [
    [(31, 41, 59), (26, 53, 58), (97, 93, 23), (84, 62, 64), (33, 83, 27)],
    [(1, 1, 1)],
]
emit("1_sample", sample_cases)

edge_cases = [
    [(1, 1, 1)],
    [(2, 3, 4)],
    [(2500, 2500, 2500)] * 30,
    [(1, 1, 1)] * 30,
    [(2500, 1, 1), (1, 2500, 1), (1, 1, 2500)],
    [(1, 2, 3), (3, 4, 5), (5, 6, 7)],
    [(5, 7, 9)] * 30,
    [(2500, 2499, 1), (2499, 2498, 1), (2498, 2497, 1)],
]
emit("2_edges", edge_cases)

wide_cases = [
    [(2500 - pos, 2499 - pos, 2500) for pos in range(30)],
    [(rng_dim, 2501 - rng_dim, 2500) for rng_dim in range(1, 31)],
    [(2500, 2500, 1)] * 30,
    [(2, 3, 2500), (3, 4, 2500), (4, 5, 2500), (5, 6, 2500)] * 7 + [(1, 2, 3), (2, 3, 4)],
]
emit("3_wide", wide_cases)

rng = random.Random(20261124)
random_cases = []
for case_index in range(200):
    block_count = rng.randint(1, 30)
    if case_index % 5 == 0:
        block_count = 30
    blocks = [(rng.randint(1, 2500), rng.randint(1, 2500), rng.randint(1, 2500))
              for _ in range(block_count)]
    random_cases.append(blocks)
emit("4_random", random_cases)

io_cases = []
for case_index in range(2000):
    blocks = [(rng.randint(1, 2500), rng.randint(1, 2500), rng.randint(1, 2500))
              for _ in range(30)]
    io_cases.append(blocks)
emit("5_io", io_cases)
