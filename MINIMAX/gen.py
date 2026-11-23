import itertools
import os
import random

INF = 10 ** 9
ROOT = os.path.dirname(os.path.abspath(__file__))


def oracle_dp(input_count, sorter_pairs):
    base_size = 1
    while base_size < input_count + 1:
        base_size *= 2
    tree = [INF] * (2 * base_size)

    def lower_value(position, new_value):
        node = position + base_size
        if new_value >= tree[node]:
            return
        tree[node] = new_value
        node //= 2
        while node >= 1:
            left_child = tree[2 * node]
            right_child = tree[2 * node + 1]
            smaller = left_child if left_child < right_child else right_child
            if smaller == tree[node]:
                return
            tree[node] = smaller
            node //= 2

    def range_minimum(left_pos, right_pos):
        best = INF
        low_node = left_pos + base_size
        high_node = right_pos + base_size
        while low_node <= high_node:
            if low_node & 1:
                if tree[low_node] < best:
                    best = tree[low_node]
                low_node += 1
            if not (high_node & 1):
                if tree[high_node] < best:
                    best = tree[high_node]
                high_node -= 1
            low_node //= 2
            high_node //= 2
        return best

    lower_value(1, 0)
    best_costs = [INF] * (input_count + 1)
    best_costs[1] = 0
    for left_edge, right_edge in sorter_pairs:
        if left_edge > right_edge:
            left_edge, right_edge = right_edge, left_edge
        trial_cost = range_minimum(left_edge, right_edge) + 1
        if trial_cost < best_costs[right_edge]:
            best_costs[right_edge] = trial_cost
            lower_value(right_edge, trial_cost)
    return best_costs[input_count]


def oracle_brute(input_count, sorter_pairs):
    permutations = list(itertools.permutations(range(1, input_count + 1)))
    sorter_count = len(sorter_pairs)
    for chosen_size in range(sorter_count + 1):
        for chosen in itertools.combinations(range(sorter_count), chosen_size):
            works = True
            for values in permutations:
                arrangement = list(values)
                for sorter_index in chosen:
                    left_edge, right_edge = sorter_pairs[sorter_index]
                    arrangement[left_edge - 1:right_edge] = sorted(
                        arrangement[left_edge - 1:right_edge]
                    )
                if arrangement[-1] != input_count:
                    works = False
                    break
            if works:
                return chosen_size
    return -1


def check_known_results():
    sample = [(20, 30), (1, 10), (10, 20), (20, 30), (15, 25), (30, 40)]
    assert oracle_dp(40, sample) == 4
    assert oracle_dp(10, [(1, 9), (2, 6), (6, 7), (7, 10)]) == 2
    assert oracle_dp(4, [(2, 4), (1, 2), (2, 3), (3, 4)]) == 3
    assert oracle_dp(3, [(2, 3), (1, 3), (1, 3), (2, 3)]) == 1
    assert oracle_dp(2, [(1, 2)]) == 1
    assert oracle_brute(3, [(2, 3), (1, 3), (1, 3), (2, 3)]) == 1
    assert oracle_brute(4, [(2, 4), (1, 2), (2, 3), (3, 4)]) == 3
    assert oracle_brute(5, [(1, 2), (2, 3), (3, 4), (4, 5)]) == 4
    rng = random.Random(90210)
    checked = 0
    for input_count in range(2, 6):
        for _ in range(50):
            chain = []
            right_edge = input_count
            while right_edge > 1:
                left_edge = rng.randint(1, right_edge - 1)
                chain.append((left_edge, right_edge))
                right_edge = left_edge
            chain.sort(key=lambda pair: pair[1])
            sorter_pairs = list(chain)
            for _ in range(rng.randint(0, 3)):
                left_edge = rng.randint(1, input_count - 1)
                right_edge = rng.randint(left_edge + 1, input_count)
                sorter_pairs.append((left_edge, right_edge))
            rng.shuffle(sorter_pairs)
            reference = oracle_brute(input_count, sorter_pairs)
            if reference < 0:
                continue
            checked += 1
            assert oracle_dp(input_count, sorter_pairs) == reference
    assert checked > 100


def chain_with_decoys(input_count, sorter_count, rng, decoy_fraction=1):
    chain = []
    right_edge = input_count
    while right_edge > 1:
        left_edge = rng.randint(1, right_edge - 1)
        chain.append((left_edge, right_edge))
        right_edge = left_edge
    chain.sort(key=lambda pair: pair[1])
    result = [None] * sorter_count
    chain_slots = sorted(rng.sample(range(sorter_count), len(chain)))
    for slot, sorter_pair in zip(chain_slots, chain):
        result[slot] = sorter_pair
    for slot in range(sorter_count):
        if result[slot] is None:
            left_edge = rng.randint(1, input_count - 1)
            right_edge = rng.randint(left_edge + 1, input_count)
            result[slot] = (left_edge, right_edge)
    del decoy_fraction
    return result


def render_case(input_count, sorter_pairs):
    lines = ["%d %d" % (input_count, len(sorter_pairs))]
    for left_edge, right_edge in sorter_pairs:
        lines.append("%d %d" % (left_edge, right_edge))
    return "\n".join(lines) + "\n"


def write_pair(name, input_text, output_text):
    with open(os.path.join(ROOT, "in", name + ".txt"), "w") as input_file:
        input_file.write(input_text)
    with open(os.path.join(ROOT, "out", name + ".out"), "w") as output_file:
        output_file.write(output_text)


def main():
    check_known_results()

    sample_input = (
        "1\n"
        "40 6 \n"
        "20 30 \n"
        "1 10 \n"
        "10 20 \n"
        "20 30 \n"
        "15 25 \n"
        "30 40 \n"
    )
    write_pair("1_sample", sample_input, "4\n")

    edge_cases = [
        (2, [(1, 2)]),
        (2, [(1, 2), (1, 2), (1, 2)]),
        (3, [(2, 3), (1, 3), (1, 3), (2, 3)]),
        (4, [(2, 4), (1, 2), (2, 3), (3, 4)]),
        (5, [(1, 2), (2, 3), (3, 4), (4, 5)]),
        (5, [(1, 5)]),
        (10, [(1, 9), (2, 6), (6, 7), (7, 10)]),
        (50000, [(1, 50000)]),
    ]
    edge_input = str(len(edge_cases)) + "\n"
    edge_output = ""
    for input_count, sorter_pairs in edge_cases:
        edge_input += render_case(input_count, sorter_pairs)
        edge_output += str(oracle_dp(input_count, sorter_pairs)) + "\n"
    write_pair("2_edges", edge_input, edge_output)

    rng = random.Random(4711)
    wide_cases = [
        (50000, chain_with_decoys(50000, 500000, rng)),
        (2, [(1, 2)] * 500000),
    ]
    wide_input = str(len(wide_cases)) + "\n"
    wide_output = ""
    for input_count, sorter_pairs in wide_cases:
        wide_input += render_case(input_count, sorter_pairs)
        answer = oracle_dp(input_count, sorter_pairs)
        assert answer <= input_count
        wide_output += str(answer) + "\n"
    write_pair("3_wide", wide_input, wide_output)

    rng = random.Random(1234567)
    random_cases = []
    for _ in range(10):
        input_count = rng.randint(2, 12000)
        sorter_count = rng.randint(1, 60000)
        random_cases.append((input_count, chain_with_decoys(input_count, sorter_count, rng)))
    random_input = str(len(random_cases)) + "\n"
    random_output = ""
    for input_count, sorter_pairs in random_cases:
        random_input += render_case(input_count, sorter_pairs)
        random_output += str(oracle_dp(input_count, sorter_pairs)) + "\n"
    write_pair("4_random", random_input, random_output)

    io_case_count = 200000
    io_input = str(io_case_count) + "\n" + "2 1\n1 2\n" * io_case_count
    assert oracle_dp(2, [(1, 2)]) == 1
    write_pair("5_io", io_input, "1\n" * io_case_count)


if __name__ == "__main__":
    main()
