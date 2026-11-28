import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
GOAL = tuple(range(12))
JUMPS = (1, 3, 6, 12)


def build_adjacency():
    adjacency = []
    for position in range(12):
        edges = []
        for other in range(12):
            if other == position:
                continue
            for step_index in range(3):
                if abs(position - other) != JUMPS[step_index]:
                    continue
                if position // JUMPS[step_index + 1] != other // JUMPS[step_index + 1]:
                    continue
                edges.append(other)
                break
        adjacency.append(tuple(edges))
    return tuple(adjacency)


ADJACENCY = build_adjacency()


def swap_positions(state, left, right):
    changed = list(state)
    changed[left], changed[right] = changed[right], changed[left]
    return tuple(changed)


def goal_distances(max_depth):
    table = {GOAL: 0}
    layer = [GOAL]
    for depth in range(1, max_depth + 1):
        following = []
        for state in layer:
            blank = state.index(0)
            for target in ADJACENCY[blank]:
                neighbor = swap_positions(state, blank, target)
                if neighbor not in table:
                    table[neighbor] = depth
                    following.append(neighbor)
        layer = following
    return table


GOAL_TABLE = goal_distances(12)


def oracle(state):
    if state in GOAL_TABLE:
        return GOAL_TABLE[state]
    visited = {state: 0}
    layer = [state]
    best = None
    for depth in range(1, 13):
        following = []
        for current in layer:
            blank = current.index(0)
            for target in ADJACENCY[blank]:
                neighbor = swap_positions(current, blank, target)
                if neighbor in visited:
                    continue
                visited[neighbor] = depth
                if neighbor in GOAL_TABLE:
                    candidate = depth + GOAL_TABLE[neighbor]
                    if best is None or candidate < best:
                        best = candidate
                following.append(neighbor)
        layer = following
        if best is not None and depth >= best:
            break
    if best is None:
        raise ValueError("state too far from sorted order")
    return best


def brute_force(state):
    if state == GOAL:
        return 0
    visited = {state}
    layer = [state]
    for depth in range(1, 20):
        following = []
        for current in layer:
            blank = current.index(0)
            for target in ADJACENCY[blank]:
                neighbor = swap_positions(current, blank, target)
                if neighbor == GOAL:
                    return depth
                if neighbor not in visited:
                    visited.add(neighbor)
                    following.append(neighbor)
        layer = following
    raise ValueError("brute force failed")


def random_walk(rng, length):
    state = list(GOAL)
    blank = 0
    previous = -1
    for _ in range(length):
        options = [target for target in ADJACENCY[blank] if target != previous]
        if not options:
            options = list(ADJACENCY[blank])
        target = rng.choice(options)
        state[blank], state[target] = state[target], state[blank]
        previous = blank
        blank = target
    return tuple(state)


def format_case(states):
    lines = [str(len(states))]
    lines += [" ".join(str(value) for value in state) for state in states]
    return "\n".join(lines) + "\n"


def write_pair(name, states):
    input_text = format_case(states)
    output_text = "".join(str(oracle(state)) + "\n" for state in states)
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(output_text)


SAMPLE_IN = (
    "2\n"
    "1 10 2 3 0 5 7 4 8 6 9 11\n"
    "6 4 1 0 3 5 9 7 2 10 11 8\n"
)
SAMPLE_OUT = "8\n9\n"
FIRST_SAMPLE = (1, 10, 2, 3, 0, 5, 7, 4, 8, 6, 9, 11)
SECOND_SAMPLE = (6, 4, 1, 0, 3, 5, 9, 7, 2, 10, 11, 8)

assert format_case([FIRST_SAMPLE, SECOND_SAMPLE]) == SAMPLE_IN
assert oracle(FIRST_SAMPLE) == 8
assert oracle(SECOND_SAMPLE) == 9
assert oracle(GOAL) == 0
assert all(oracle(swap_positions(GOAL, 0, target)) == 1 for target in ADJACENCY[0])
assert len(ADJACENCY[0]) == 3 and len(ADJACENCY[1]) == 4

check_rng = random.Random(31)
for _ in range(8):
    near_goal = random_walk(check_rng, 5)
    assert oracle(near_goal) == brute_force(near_goal)

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)

edge_states = [
    GOAL,
    swap_positions(GOAL, 0, 1),
    swap_positions(GOAL, 0, 3),
    swap_positions(GOAL, 0, 6),
    random_walk(random.Random(104), 4),
    random_walk(random.Random(101), 2),
    random_walk(random.Random(102), 3),
    random_walk(random.Random(103), 5),
]
write_pair("2_edges", edge_states)

wide_rng = random.Random(2026)
write_pair("3_wide", [random_walk(wide_rng, wide_rng.choice((16, 17, 18))) for _ in range(5)])

random_rng = random.Random(20261125)
write_pair("4_random", [random_walk(random_rng, random_rng.randint(8, 18)) for _ in range(20)])

io_rng = random.Random(77)
write_pair("5_io", [random_walk(io_rng, io_rng.randint(3, 8)) for _ in range(100)])
