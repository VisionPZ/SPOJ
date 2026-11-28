import os
import random
from itertools import product


def sim_active(n, program):
    counts = [1] * (n + 1)
    active = set(range(1, n + 1))
    for lower, upper in program:
        moved = counts[upper]
        counts[upper] = 0
        active.discard(upper)
        if moved > 0:
            counts[lower] += moved
            active.add(lower)
    return active


def oracle_sim(n, program):
    final_active = sim_active(n, program)
    stranded_final = final_active - {1}
    possible_strands = set(stranded_final)
    for deleted in range(len(program)):
        reduced = program[:deleted] + program[deleted + 1:]
        possible_strands |= (sim_active(n, reduced) - {1})
    return 2 * len(stranded_final) + len(possible_strands - stranded_final)


def oracle_brute(n, program, max_extra=4):
    pairs = [(a, b) for a in range(1, n + 1) for b in range(a + 1, n + 1)]

    def is_min_finding(full):
        sets = [frozenset([p]) for p in range(1, n + 1)]
        for lower, upper in full:
            sets[lower - 1] = sets[lower - 1] | sets[upper - 1]
            sets[upper - 1] = frozenset()
        return sets[0] == frozenset(range(1, n + 1))

    def is_reliable(full):
        if not is_min_finding(full):
            return False
        for skip in range(len(full)):
            if not is_min_finding(full[:skip] + full[skip + 1:]):
                return False
        return True

    for extra_count in range(max_extra + 1):
        for extra in product(pairs, repeat=extra_count):
            if is_reliable(list(program) + list(extra)):
                return extra_count
    return None


assert oracle_brute(2, []) == 2
assert oracle_brute(3, []) == 4
assert oracle_brute(3, [(1, 2), (2, 3), (1, 2)]) == 2
assert oracle_brute(3, [(1, 2), (1, 3), (2, 3)]) == 1
assert oracle_sim(4, []) == 6
assert oracle_sim(5, []) == 8

cross_rng = random.Random(20241124)
for _ in range(60):
    small_n = cross_rng.randint(2, 3)
    pairs = [(a, b) for a in range(1, small_n + 1) for b in range(a + 1, small_n + 1)]
    length = cross_rng.randint(0, 4)
    prog = [cross_rng.choice(pairs) for _ in range(length)]
    brute_result = oracle_brute(small_n, prog, 4)
    assert brute_result is not None
    assert oracle_sim(small_n, prog) == brute_result


def format_case(datasets):
    lines = [str(len(datasets))]
    for n, program in datasets:
        lines.append(str(n) + " " + str(len(program)))
        flat = []
        for lower, upper in program:
            flat.append(str(lower))
            flat.append(str(upper))
        lines.append(" ".join(flat))
    return "\n".join(lines) + "\n"


def expected_output(datasets):
    return "".join(str(oracle_sim(n, program)) + "\n" for n, program in datasets)


here = os.path.dirname(os.path.abspath(__file__))
out_dir = os.path.join(here, "out")
in_dir = os.path.join(here, "in")
os.makedirs(out_dir, exist_ok=True)
os.makedirs(in_dir, exist_ok=True)


def emit(name, datasets):
    with open(os.path.join(in_dir, name + ".txt"), "w") as handle:
        handle.write(format_case(datasets))
    with open(os.path.join(out_dir, name + ".out"), "w") as handle:
        handle.write(expected_output(datasets))


emit("1_sample", [(3, [(1, 2), (2, 3), (1, 2)])])

edges = [
    (2, []),
    (2, [(1, 2)]),
    (2, [(1, 2), (1, 2)]),
    (3, []),
    (4, []),
    (5, [(1, 3), (1, 2)]),
    (3, [(1, 2), (2, 3)]),
    (10000, []),
]
emit("2_edges", edges)

wide_rng = random.Random(6151)
wide = []
for n_val, m_val in [(10000, 100), (10000, 100), (500, 1200), (2, 1)]:
    prog = []
    for _ in range(m_val):
        lower = wide_rng.randint(1, n_val - 1)
        upper = wide_rng.randint(lower + 1, n_val)
        prog.append((lower, upper))
    wide.append((n_val, prog))
emit("3_wide", wide)

random_rng = random.Random(778899)
random_sets = []
for _ in range(10):
    n_val = random_rng.randint(2, 300)
    m_val = random_rng.randint(0, 500)
    prog = []
    for _ in range(m_val):
        lower = random_rng.randint(1, n_val - 1)
        upper = random_rng.randint(lower + 1, n_val)
        prog.append((lower, upper))
    random_sets.append((n_val, prog))
emit("4_random", random_sets)

io_rng = random.Random(424242)
io_sets = []
for _ in range(10):
    n_val = 10000
    m_val = 200
    prog = []
    for _ in range(m_val):
        lower = io_rng.randint(1, n_val - 1)
        upper = io_rng.randint(lower + 1, n_val)
        prog.append((lower, upper))
    io_sets.append((n_val, prog))
emit("5_io", io_sets)

big_rng = random.Random(999331)
big_sets = []
for _ in range(10):
    n_val = 10000
    m_val = 25000
    prog = []
    for _ in range(m_val):
        lower = big_rng.randint(1, n_val - 1)
        upper = big_rng.randint(lower + 1, n_val)
        prog.append((lower, upper))
    big_sets.append((n_val, prog))
with open("/tmp/EXCHNG_big.txt", "w") as handle:
    handle.write(format_case(big_sets))
