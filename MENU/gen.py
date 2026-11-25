import random
import sys
from pathlib import Path

sys.setrecursionlimit(10000)
ROOT = Path(__file__).resolve().parent


def solve_case(day_count, dish_count, budget, costs, values):
    memo = {}

    def state_value(day, run_index, dish, spent):
        if day == 1:
            if run_index == 0 and spent == costs[dish] and costs[dish] <= budget:
                return 2 * values[dish]
            return -1
        key = (day, run_index, dish, spent)
        cached = memo.get(key)
        if cached is not None:
            return cached
        previous_spent = spent - costs[dish]
        if previous_spent < 0:
            return -1
        best = -1
        if run_index == 0:
            for previous_dish in range(1, dish_count + 1):
                if previous_dish == dish:
                    continue
                for previous_run in range(3):
                    prior = state_value(day - 1, previous_run, previous_dish, previous_spent)
                    if prior >= 0 and prior + 2 * values[dish] > best:
                        best = prior + 2 * values[dish]
        elif run_index == 1:
            prior = state_value(day - 1, 0, dish, previous_spent)
            if prior >= 0:
                best = prior + values[dish]
        else:
            first = state_value(day - 1, 1, dish, previous_spent)
            second = state_value(day - 1, 2, dish, previous_spent)
            best = max(first, second)
        memo[key] = best
        return best

    best_benefit = -1
    best_cost = budget + 1
    best_run = 0
    best_dish = 0
    for run_index in range(3):
        for dish in range(1, dish_count + 1):
            for spent in range(budget + 1):
                value = state_value(day_count, run_index, dish, spent)
                if value < 0:
                    continue
                if value > best_benefit or (value == best_benefit and spent < best_cost):
                    best_benefit = value
                    best_cost = spent
                    best_run = run_index
                    best_dish = dish
    if best_benefit < 0:
        return "0.0", []

    menu = [0] * (day_count + 1)
    day, run_index, dish, spent, value = day_count, best_run, best_dish, best_cost, best_benefit
    while day >= 1:
        menu[day] = dish
        if day == 1:
            break
        previous_spent = spent - costs[dish]
        if run_index == 0:
            wanted = value - 2 * values[dish]
            found = False
            for prior_run in range(3):
                for prior_dish in range(1, dish_count + 1):
                    if prior_dish == dish:
                        continue
                    if state_value(day - 1, prior_run, prior_dish, previous_spent) == wanted:
                        run_index = prior_run
                        dish = prior_dish
                        value = wanted
                        found = True
                        break
                if found:
                    break
        elif run_index == 1:
            value -= values[dish]
            run_index = 0
        else:
            if state_value(day - 1, 1, dish, previous_spent) == value:
                run_index = 1
            else:
                run_index = 2
        spent = previous_spent
        day -= 1
    return "%d.%d" % (best_benefit // 2, (best_benefit % 2) * 5), menu[1:]


def brute_force(day_count, dish_count, budget, costs, values):
    best = [-1, budget + 1]

    def walk(day, last_dish, run_length, spent, benefit):
        if day > day_count:
            if benefit > best[0] or (benefit == best[0] and spent < best[1]):
                best[0] = benefit
                best[1] = spent
            return
        for dish in range(1, dish_count + 1):
            new_spent = spent + costs[dish]
            if new_spent > budget:
                continue
            if dish == last_dish and run_length > 0:
                new_run = min(run_length + 1, 3)
            else:
                new_run = 1
            if new_run == 1:
                added = 2 * values[dish]
            elif new_run == 2:
                added = values[dish]
            else:
                added = 0
            walk(day + 1, dish, new_run, new_spent, benefit + added)

    walk(1, 0, 0, 0, 0)
    return tuple(best)


def doubled(text):
    whole, fraction = text.split(".")
    return int(whole) * 2 + int(fraction) // 5


def encode_input(cases):
    parts = []
    for day_count, dish_count, budget, costs, values in cases:
        parts.append("%d %d %d\n" % (day_count, dish_count, budget))
        for dish in range(1, dish_count + 1):
            parts.append("%d %d\n" % (costs[dish], values[dish]))
    parts.append("0 0 0\n")
    return "".join(parts)


def oracle(text):
    tokens = text.split()
    cursor = 0
    parts = []
    while True:
        day_count = int(tokens[cursor]); cursor += 1
        dish_count = int(tokens[cursor]); cursor += 1
        budget = int(tokens[cursor]); cursor += 1
        if day_count == dish_count == budget == 0:
            break
        costs = [0]
        values = [0]
        for _ in range(dish_count):
            costs.append(int(tokens[cursor])); cursor += 1
            values.append(int(tokens[cursor])); cursor += 1
        benefit, menu = solve_case(day_count, dish_count, budget, costs, values)
        if not menu:
            parts.append(benefit + "\n\n")
        else:
            parts.append(benefit + "\n")
            parts.append(" ".join(str(x) for x in menu) + " \n\n")
    return "".join(parts)


def write(name, cases, input_text=None):
    if input_text is None:
        input_text = encode_input(cases)
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(input_text))


SAMPLE_INPUT = (
    "2 1 5\n"
    "3 5\n"
    "3 5 20\n"
    "2 5\n"
    "18 6\n"
    "1 1\n"
    "3 3\n"
    "2 3\n"
    "0 0 0\n"
)
SAMPLE_OUTPUT = "0.0\n\n13.0\n1 5 1 \n\n"

assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert solve_case(2, 1, 5, [0, 3], [0, 5])[0] == "0.0"
assert solve_case(3, 5, 20, [0, 2, 18, 1, 3, 2],
                  [0, 5, 6, 1, 3, 3]) == ("13.0", [1, 5, 1])
assert solve_case(10, 4, 100, [0, 3, 7, 11, 3],
                  [0, 10, 12, 13, 65])[0] == "409.5"
assert brute_force(2, 1, 5, [0, 3], [0, 5]) == (-1, 6)

check_rng = random.Random(31415)
for _ in range(40):
    tiny_n = check_rng.randint(1, 4)
    tiny_costs = [0] + [check_rng.randint(1, 6) for _ in range(tiny_n)]
    tiny_values = [0] + [check_rng.randint(1, 20) for _ in range(tiny_n)]
    tiny_k = check_rng.randint(1, 4)
    tiny_budget = check_rng.randint(0, 8)
    oracle_benefit, oracle_menu = solve_case(tiny_k, tiny_n, tiny_budget,
                                              tiny_costs, tiny_values)
    brute_benefit, brute_cost = brute_force(tiny_k, tiny_n, tiny_budget,
                                            tiny_costs, tiny_values)
    if brute_benefit < 0:
        assert oracle_benefit == "0.0" and not oracle_menu
    else:
        assert doubled(oracle_benefit) == brute_benefit
        assert sum(tiny_costs[dish] for dish in oracle_menu) == brute_cost

rng = random.Random(20261125)
wide_costs = [0] + [rng.randint(1, 50) for _ in range(50)]
wide_values = [0] + [rng.randint(1, 10000) for _ in range(50)]
all_expensive = [0] + [50] * 50
all_cheap = [0] + [1] * 50
all_big = [0] + [10000] * 50

edges = [
    (1, 1, 0, [0, 1], [0, 5]),
    (1, 1, 1, [0, 1], [0, 5]),
    (2, 1, 1, [0, 1], [0, 5]),
    (2, 1, 2, [0, 1], [0, 5]),
    (3, 1, 100, [0, 50], [0, 10000]),
    (3, 2, 100, [0, 1, 1], [0, 10000, 1]),
    (21, 2, 100, [0, 4, 4], [0, 10000, 10000]),
    (2, 3, 3, [0, 1, 2, 3], [0, 5, 7, 9]),
    (1, 50, 0, all_big, all_big),
]

wide = [
    (21, 50, 100, wide_costs, wide_values),
    (21, 50, 0, wide_costs, wide_values),
    (1, 50, 100, wide_costs, wide_values),
    (21, 50, 100, all_expensive, wide_values),
    (21, 50, 100, all_cheap, all_big),
]

random_cases = []
for _ in range(5):
    costs = [0] + [rng.randint(1, 50) for _ in range(50)]
    values = [0] + [rng.randint(1, 10000) for _ in range(50)]
    random_cases.append((21, 50, 100, costs, values))
for _ in range(30):
    dish_n = rng.randint(1, 15)
    costs = [0] + [rng.randint(1, 50) for _ in range(dish_n)]
    values = [0] + [rng.randint(1, 10000) for _ in range(dish_n)]
    random_cases.append((rng.randint(1, 21), dish_n, rng.randint(0, 100),
                         costs, values))

io_cases = [(21, 1, 100, [0, 1], [0, 10000])] * 20000

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [], SAMPLE_INPUT)
write("2_edges", edges)
write("3_wide", wide)
write("4_random", random_cases)
write("5_io", io_cases)
