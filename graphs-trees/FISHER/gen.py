import random

INF = 10 ** 15


def oracle_time_dp(state_count, time_limit, travel, toll):
    stride = time_limit + 1
    dp = [[INF] * stride for _ in range(state_count)]
    dp[0][0] = 0
    for elapsed in range(1, time_limit + 1):
        for node in range(state_count):
            best = dp[node][elapsed - 1]
            for prior in range(state_count):
                needed = travel[prior][node]
                if needed <= elapsed:
                    candidate = dp[prior][elapsed - needed] + toll[prior][node]
                    if candidate < best:
                        best = candidate
            dp[node][elapsed] = best
    best_toll = INF
    best_time = 0
    for elapsed in range(time_limit + 1):
        reached = dp[state_count - 1][elapsed]
        if reached < best_toll:
            best_toll = reached
            best_time = elapsed
    return best_toll, best_time


def brute_force(state_count, time_limit, travel, toll):
    best_toll = INF
    best_time = 0
    stack = [(0, 0, 0, frozenset([0]))]
    while stack:
        node, elapsed, cost, seen = stack.pop()
        if node == state_count - 1:
            if cost < best_toll or (cost == best_toll and elapsed < best_time):
                best_toll = cost
                best_time = elapsed
            continue
        for target in range(state_count):
            if target in seen:
                continue
            arrival = elapsed + travel[node][target]
            if arrival <= time_limit and cost + toll[node][target] <= best_toll:
                stack.append((target, arrival, cost + toll[node][target], seen | {target}))
    return best_toll, best_time


def random_case(rng, state_count, time_limit, max_travel, max_toll, positive_toll=False):
    travel = []
    toll = []
    for row in range(state_count):
        travel_row = []
        toll_row = []
        for col in range(state_count):
            if row == col:
                travel_row.append(0)
                toll_row.append(0)
            else:
                travel_row.append(rng.randint(1, max_travel))
                lower = 1 if positive_toll else 0
                toll_row.append(rng.randint(lower, max_toll))
        travel.append(travel_row)
        toll.append(toll_row)
    return travel, toll


def format_case(state_count, time_limit, travel, toll):
    lines = ["%d %d" % (state_count, time_limit)]
    for row in travel:
        lines.append(" ".join(str(value) for value in row))
    lines.append("")
    for row in toll:
        lines.append(" ".join(str(value) for value in row))
    lines.append("")
    return "\n".join(lines) + "\n"


sample_travel = [
    [0, 5, 2, 3],
    [5, 0, 2, 3],
    [3, 1, 0, 2],
    [3, 3, 2, 0],
]
sample_toll = [
    [0, 2, 2, 7],
    [2, 0, 1, 2],
    [2, 2, 0, 5],
    [7, 2, 5, 0],
]

assert oracle_time_dp(4, 7, sample_travel, sample_toll) == (6, 6)
assert brute_force(4, 7, sample_travel, sample_toll) == (6, 6)

hand_travel = [
    [0, 1, 5],
    [1, 0, 1],
    [5, 1, 0],
]
hand_toll = [
    [0, 3, 1],
    [3, 0, 4],
    [1, 4, 0],
]
assert oracle_time_dp(3, 2, hand_travel, hand_toll) == (7, 2)

for seed in range(30):
    rng = random.Random(seed + 10000)
    size = rng.randint(3, 6)
    budget = rng.randint(2, 14)
    travel_matrix, toll_matrix = random_case(rng, size, budget, 5, 9, True)
    oracle_result = oracle_time_dp(size, budget, travel_matrix, toll_matrix)
    brute_result = brute_force(size, budget, travel_matrix, toll_matrix)
    assert oracle_result == brute_result, (seed, oracle_result, brute_result)

sample_input = "4 7\n0 5 2 3\n5 0 2 3\n3 1 0 2\n3 3 2 0\n\n0 2 2 7\n2 0 1 2\n2 2 0 5\n7 2 5 0\n\n0 0\n"
sample_output = "6 6\n"

edge_cases = []
edge_answers = []

travel, toll = random_case(random.Random(1), 3, 1, 2, 4)
edge_cases.append((3, 1, travel, toll))

travel = [[0, 1, 1], [1, 0, 1], [1, 1, 0]]
toll = [[0, 5, 2], [5, 0, 5], [2, 5, 0]]
edge_cases.append((3, 2, travel, toll))

travel = [[0, 1, 20], [1, 0, 1], [20, 1, 0]]
toll = [[0, 1, 1], [1, 0, 1], [1, 1, 0]]
edge_cases.append((3, 3, travel, toll))

travel = [[0, 1, 2, 3], [1, 0, 1, 2], [2, 1, 0, 1], [3, 2, 1, 0]]
toll = [[0, 0, 0, 9], [0, 0, 0, 0], [0, 0, 0, 0], [9, 0, 0, 0]]
edge_cases.append((4, 3, travel, toll))

travel, toll = random_case(random.Random(7), 6, 4, 3, 6)
edge_cases.append((6, 4, travel, toll))

for state_count, time_limit, travel, toll in edge_cases:
    edge_answers.append(oracle_time_dp(state_count, time_limit, travel, toll))

wide_cases = []
wide_rng = random.Random(2024)
for budget in (999, 500, 120):
    wide_cases.append(random_case(wide_rng, 50, budget, 9, 20))

random_cases = []
random_rng = random.Random(777)
for _ in range(24):
    size = random_rng.randint(4, 50)
    budget = random_rng.randint(5, 999)
    travel, toll = random_case(random_rng, size, budget, 12, 30)
    random_cases.append((size, budget, travel, toll))

io_cases = []
io_rng = random.Random(31337)
for _ in range(30000):
    io_cases.append(random_case(io_rng, 3, 20, 6, 12))


def write_pair(name, cases):
    input_parts = []
    output_parts = []
    for state_count, time_limit, travel, toll in cases:
        input_parts.append(format_case(state_count, time_limit, travel, toll))
        answer = oracle_time_dp(state_count, time_limit, travel, toll)
        output_parts.append("%d %d\n" % (answer[0], answer[1]))
    input_parts.append("0 0\n")
    with open("in/%s.txt" % name, "w") as handle:
        handle.write("".join(input_parts))
    with open("out/%s.out" % name, "w") as handle:
        handle.write("".join(output_parts))


with open("in/1_sample.txt", "w") as handle:
    handle.write(sample_input)
with open("out/1_sample.out", "w") as handle:
    handle.write(sample_output)

write_pair("2_edges", edge_cases)
write_pair("3_wide", [(50, budget, travel, toll)
                      for (budget, (travel, toll)) in zip((999, 500, 120), wide_cases)])
write_pair("4_random", random_cases)
write_pair("5_io", [(3, 20, travel, toll) for travel, toll in io_cases])
