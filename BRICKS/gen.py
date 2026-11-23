import collections
import itertools
import os
import random


def merge_inversions(values):
    if len(values) < 2:
        return 0
    middle = len(values) // 2
    left = values[:middle]
    right = values[middle:]
    count = merge_inversions(left) + merge_inversions(right)
    merged = []
    left_index = 0
    right_index = 0
    while left_index < len(left) and right_index < len(right):
        if left[left_index] <= right[right_index]:
            merged.append(left[left_index])
            left_index += 1
        else:
            merged.append(right[right_index])
            right_index += 1
            count += len(left) - left_index
    merged.extend(left[left_index:])
    merged.extend(right[right_index:])
    values[:] = merged
    return count


def bfs_answer(start, target, edges):
    if collections.Counter(start) != collections.Counter(target):
        return -1
    edge_set = set(frozenset(pair) for pair in edges)
    if start == target:
        return 0
    queue = collections.deque([(start, 0)])
    seen = {start}
    while queue:
        state, depth = queue.popleft()
        for index in range(len(state) - 1):
            if frozenset((state[index], state[index + 1])) in edge_set:
                nxt = state[:index] + state[index + 1] + state[index] + state[index + 2:]
                if nxt == target:
                    return depth + 1
                if nxt not in seen:
                    seen.add(nxt)
                    queue.append((nxt, depth + 1))
    return -1


def oracle_merge(start, target, edges):
    if collections.Counter(start) != collections.Counter(target):
        return -1
    target_positions = collections.defaultdict(list)
    for position, letter in enumerate(target):
        target_positions[letter].append(position)
    used = collections.Counter()
    positions = []
    for letter in start:
        positions.append(target_positions[letter][used[letter]])
        used[letter] += 1
    total_inversions = merge_inversions(list(positions))
    neighbour = collections.defaultdict(set)
    for left_letter, right_letter in edges:
        neighbour[left_letter].add(right_letter)
        neighbour[right_letter].add(left_letter)
    connected_inversions = 0
    for left_letter in sorted(neighbour):
        for right_letter in sorted(neighbour[left_letter]):
            if left_letter >= right_letter:
                continue
            filtered = [positions[index] for index in range(len(start))
                        if start[index] in (left_letter, right_letter)]
            connected_inversions += merge_inversions(filtered)
    if connected_inversions != total_inversions:
        return -1
    return connected_inversions % (2 ** 32)


def verify_oracle():
    assert oracle_merge("ab", "ba", []) == -1
    assert oracle_merge("ab", "ba", [("a", "b")]) == 1
    assert oracle_merge("abc", "cba", [("a", "b"), ("b", "c"), ("c", "a")]) == 3
    assert oracle_merge("abba", "baab", [("a", "b")]) == 2
    assert oracle_merge("abc", "cba", [("a", "b"), ("b", "c")]) == -1
    alphabet = "abc"
    all_edges = list(itertools.combinations(alphabet, 2))
    words = [''.join(p) for length in range(1, 4)
             for p in itertools.product(alphabet, repeat=length)]
    for edge_count in range(len(all_edges) + 1):
        for edges in itertools.combinations(all_edges, edge_count):
            for start in words:
                for target in words:
                    if collections.Counter(start) != collections.Counter(target):
                        continue
                    expected = bfs_answer(start, target, edges)
                    actual = oracle_merge(start, target, edges)
                    assert actual == expected, (start, target, edges, expected, actual)


def format_case(start, target, pairs):
    lines = [start, target, str(len(pairs))]
    lines.extend("%s %s" % pair for pair in pairs)
    return "\n".join(lines) + "\n"


def render(cases):
    input_lines = [str(len(cases))]
    output_lines = []
    for start, target, pairs in cases:
        input_lines.append(format_case(start, target, pairs).rstrip("\n"))
        output_lines.append(str(oracle_merge(start, target, pairs)))
    return "\n".join(input_lines) + "\n", "\n".join(output_lines) + "\n"


def write_pair(name, cases):
    input_text, output_text = render(cases)
    with open(os.path.join("in", name + ".txt"), "w") as handle:
        handle.write(input_text)
    with open(os.path.join("out", name + ".out"), "w") as handle:
        handle.write(output_text)


def sample_cases():
    return [
        ("ab", "ba", []),
        ("abc", "cba", [("a", "b"), ("c", "b"), ("c", "a")]),
        ("cabbbc", "cbabbc", [("a", "b")]),
        ("abba", "baab", [("a", "b")]),
    ]


def edge_cases():
    all_pairs = list(itertools.combinations("abcdefghijklmnopqrstuvwxyz", 2))
    reversed_alphabet = "".join(reversed("abcdefghijklmnopqrstuvwxyz"))
    big_letters = "abcdefgh"
    big_start = "".join(letter * 12500 for letter in big_letters)
    big_target = big_start[::-1]
    big_pairs = list(itertools.combinations(big_letters, 2))
    return [
        ("abcabc", "abcabc", []),
        ("a", "a", []),
        ("ab", "ba", [("a", "b")]),
        ("abcd", "abcd", []),
        ("a", "b", []),
        ("abcd", "dcba", [("a", "b"), ("b", "c"), ("c", "d")]),
        (reversed_alphabet, "abcdefghijklmnopqrstuvwxyz", all_pairs),
        ("cabbbc", "cbabbc", [("a", "b")]),
        ("zzzz", "zzzz", [("z", "z")]),
        (big_start, big_target, big_pairs),
    ]


def wide_cases():
    all_pairs = list(itertools.combinations("abcdefghijklmnopqrstuvwxyz", 2))
    alphabet = "abcdefgh"
    size = 100000
    ordered = "".join(letter * 12500 for letter in alphabet)
    reversed_ordered = ordered[::-1]
    rng = random.Random(20261123)
    shuffled = list(ordered)
    rng.shuffle(shuffled)
    wide_pairs = list(itertools.combinations(alphabet, 2))
    return [
        (reversed_ordered, ordered, wide_pairs),
        (ordered, ordered, []),
        ("".join(shuffled), ordered, wide_pairs),
        ("a" * size, "a" * size, []),
        (reversed_ordered, ordered, all_pairs),
    ]


def random_cases():
    rng = random.Random(776655)
    cases = []
    alphabet = "abcdefghijklmnopqrstuvwxyz"
    all_pairs = list(itertools.combinations(alphabet, 2))
    for case_index in range(24):
        size = rng.randint(1, 100000) if case_index % 4 == 0 else rng.randint(1, 400)
        start = "".join(rng.choice("abcde" if size > 1000 else alphabet)
                        for _ in range(size))
        target_chars = list(start)
        rng.shuffle(target_chars)
        target = "".join(target_chars)
        if case_index % 3 == 0:
            pairs = all_pairs
        else:
            pair_count = rng.randint(0, len(all_pairs))
            pairs = rng.sample(all_pairs, pair_count)
        cases.append((start, target, pairs))
    return cases


def io_cases():
    rng = random.Random(4321987)
    cases = []
    full_pairs = [("a", "b"), ("a", "c"), ("b", "c")]
    for _ in range(90000):
        start = "".join(rng.choice("abc") for _ in range(4))
        target_chars = list(start)
        rng.shuffle(target_chars)
        cases.append((start, "".join(target_chars), full_pairs))
    for _ in range(20000):
        start = "".join(rng.choice("abcdefghij") for _ in range(120))
        target_chars = list(start)
        rng.shuffle(target_chars)
        pairs = list(itertools.combinations("abcdefghij", 2))
        cases.append((start, "".join(target_chars), pairs))
    return cases


def main():
    verify_oracle()
    write_pair("1_sample", sample_cases())
    write_pair("2_edges", edge_cases())
    write_pair("3_wide", wide_cases())
    write_pair("4_random", random_cases())
    write_pair("5_io", io_cases())


if __name__ == "__main__":
    main()
