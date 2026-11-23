import os
import random
from functools import lru_cache

PRINTABLE = [chr(code) for code in range(32, 127) if chr(code) != 'd']

SAMPLE_INPUT = "00001123444456789\n000011234444446789\n"
SAMPLE_OUTPUT = "18\n00d1123444456789\n\n18\n00d1123\n444d6789\n\n"


def simulate_line(program):
    content = ""
    for key in program:
        if key == 'd':
            content += content
        else:
            content += key
    return content


def compute_cost_tables(text):
    length = len(text)
    cost = [[0] * (length + 1) for _ in range(length + 1)]
    dcount = [[0] * (length + 1) for _ in range(length + 1)]
    for span in range(1, length + 1):
        for begin in range(length - span + 1):
            end = begin + span
            best_cost = cost[begin][end - 1] + 1
            best_dcount = dcount[begin][end - 1]
            if span % 2 == 0:
                half = span // 2
                if text[begin:begin + half] == text[begin + half:end]:
                    double_cost = cost[begin][begin + half] + 1
                    double_dcount = dcount[begin][begin + half] + 1
                    if double_cost < best_cost or (double_cost == best_cost and double_dcount < best_dcount):
                        best_cost = double_cost
                        best_dcount = double_dcount
            cost[begin][end] = best_cost
            dcount[begin][end] = best_dcount
    return cost, dcount


def partition_dp(text, cost):
    length = len(text)
    best = [None] * (length + 1)
    best[0] = (0, 0, (), 0)
    for end in range(1, length + 1):
        current = None
        for split in range(end):
            line_cost = cost[split][end]
            candidate = (best[split][0] + line_cost + 1, best[split][1] + 1, best[split][2] + (line_cost,), split)
            if current is None or candidate[:3] < current[:3]:
                current = candidate
        best[end] = current
    return best


def reconstruct_program(text, cost, dcount, begin, end):
    reversed_keys = []
    left = begin
    right = end
    while left < right:
        if cost[left][right] == cost[left][right - 1] + 1 and dcount[left][right] == dcount[left][right - 1]:
            reversed_keys.append(text[right - 1])
            right -= 1
        else:
            reversed_keys.append('d')
            right = left + (right - left) // 2
    return ''.join(reversed(reversed_keys))


def line_best_bruteforce(text):
    target = text
    needed = set(target)

    @lru_cache(maxsize=None)
    def search(content):
        if content == target:
            return (0, 0, "")
        result = None
        for char in needed:
            grown = content + char
            if not target.startswith(grown):
                continue
            cost, dcount, program = search(grown)
            candidate = (cost + 1, dcount, char + program)
            if result is None or candidate[:2] < result[:2]:
                result = candidate
        doubled = content + content
        if doubled != content and target.startswith(doubled):
            cost, dcount, program = search(doubled)
            candidate = (cost + 1, dcount + 1, 'd' + program)
            if result is None or candidate[:2] < result[:2]:
                result = candidate
        return result

    return search("")


def brute_objective(text):
    length = len(text)
    line_costs = {(begin, end): line_best_bruteforce(text[begin:end])[0]
                  for begin in range(length) for end in range(begin + 1, length + 1)}

    def indexed(begin, end):
        return line_costs[(begin, end)]

    best = None
    for mask in range(1 << max(0, length - 1)):
        bounds = [0]
        for position in range(length - 1):
            if mask & (1 << position):
                bounds.append(position + 1)
        bounds.append(length)
        costs = tuple(indexed(bounds[k], bounds[k + 1]) for k in range(len(bounds) - 1))
        objective = (sum(costs) + len(costs) + 1, len(costs), costs)
        if best is None or objective < best:
            best = objective
    return best


def oracle_output(text):
    if len(text) == 0:
        return "1\n\n"
    cost, dcount = compute_cost_tables(text)
    best = partition_dp(text, cost)
    total = best[len(text)][0] + 1
    bounds = [len(text)]
    position = len(text)
    while position > 0:
        position = best[position][3]
        bounds.append(position)
    bounds.reverse()
    programs = [reconstruct_program(text, cost, dcount, bounds[k], bounds[k + 1]) for k in range(len(bounds) - 1)]
    for segment_index, program in enumerate(programs):
        assert simulate_line(program) == text[bounds[segment_index]:bounds[segment_index + 1]]
    assert total == sum(len(program) for program in programs) + len(programs) + 1
    return str(total) + '\n' + ''.join(program + '\n' for program in programs) + '\n'


def check_known_constants():
    assert line_best_bruteforce("a")[:2] == (1, 0)
    assert line_best_bruteforce("aa")[:2] == (2, 0)
    assert line_best_bruteforce("aaa")[:2] == (3, 0)
    assert line_best_bruteforce("aaaa")[:2] == (3, 1)
    assert line_best_bruteforce("abab")[:2] == (3, 1)
    assert line_best_bruteforce("abcabcabcabc")[:2] == (5, 2)
    assert compute_cost_tables("abab")[0][0][4] == 3
    assert oracle_output(SAMPLE_INPUT.splitlines()[0]) == "18\n00d1123444456789\n\n"
    assert oracle_output(SAMPLE_INPUT.splitlines()[1]) == "18\n00d1123\n444d6789\n\n"


def cross_check(text):
    cost, _ = compute_cost_tables(text)
    best = partition_dp(text, cost)
    dp_objective = (best[len(text)][0] + 1, best[len(text)][1], best[len(text)][2])
    assert brute_objective(text) == dp_objective, (text, brute_objective(text), dp_objective)


def make_cases():
    sample = ["00001123444456789", "000011234444446789"]
    edges = ["a", "ab", "aa", "aaa", "abab", "abcabcabcabc", "abcefghij", "a" * 16, "  x y  ", "Z"]
    wide = [
        "a" * 600,
        "ab" * 300,
        "abc" * 200,
        "0123456789" * 60,
        "".join(random.Random(11).choice(PRINTABLE) for _ in range(600)),
        "".join(chr(32 + (k * 7 + 3) % 95) for k in range(600)).replace('d', 'D'),
        " " * 300 + "xy" + " " * 298,
        "ab" * 149 + "c" * 302,
        "".join(random.Random(500).choice(PRINTABLE) for _ in range(600)),
        "q" * 599 + "r",
    ]
    generator = random.Random(20261123)
    random_cases = []
    for _ in range(10):
        size = generator.randint(1, 600)
        random_cases.append(''.join(generator.choice(PRINTABLE) for _ in range(size)))
    io_cases = []
    for _ in range(10):
        io_cases.append(''.join(random.Random(9000 + len(io_cases)).choice(PRINTABLE) for _ in range(600)))
    return {
        "1_sample": sample,
        "2_edges": edges,
        "3_wide": wide,
        "4_random": random_cases,
        "5_io": io_cases,
    }


def main():
    root = os.path.dirname(os.path.abspath(__file__))
    check_known_constants()
    cases = make_cases()
    for name, lines in cases.items():
        for text in lines:
            assert len(text) <= 600
            assert 'd' not in text
            if len(text) <= 12:
                cross_check(text)
        in_path = os.path.join(root, "in", name + ".txt")
        out_path = os.path.join(root, "out", name + ".out")
        with open(in_path, "w", newline='\n') as handle:
            handle.write(''.join(line + '\n' for line in lines))
        with open(out_path, "w", newline='\n') as handle:
            handle.write(''.join(oracle_output(line) for line in lines))
    sample_in = open(os.path.join(root, "in", "1_sample.txt")).read()
    sample_out = open(os.path.join(root, "out", "1_sample.out")).read()
    assert sample_in == SAMPLE_INPUT
    assert sample_out == SAMPLE_OUTPUT
    print("gen.py: oracles agree, constants hold, five pairs written")


if __name__ == "__main__":
    main()
