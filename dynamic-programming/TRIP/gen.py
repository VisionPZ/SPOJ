#!/usr/bin/env python3
import itertools
import os
import random

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
IN_DIR = os.path.join(BASE_DIR, "in")
OUT_DIR = os.path.join(BASE_DIR, "out")


def brute_trips(alice_route, bob_route):
    best_length = 0
    found = set()
    for keep_count in range(len(alice_route), 0, -1):
        for chosen in itertools.combinations(range(len(alice_route)), keep_count):
            candidate = "".join(alice_route[pos] for pos in chosen)
            bob_pos = 0
            for char in candidate:
                while bob_pos < len(bob_route) and bob_route[bob_pos] != char:
                    bob_pos += 1
                if bob_pos == len(bob_route):
                    break
                bob_pos += 1
            else:
                found.add(candidate)
        if found:
            return sorted(found)
    return [""]


def oracle_trips(alice_route, bob_route):
    alice_length = len(alice_route)
    bob_length = len(bob_route)
    length_table = [[0] * (bob_length + 1) for _ in range(alice_length + 1)]
    for left_index in range(alice_length - 1, -1, -1):
        for right_index in range(bob_length - 1, -1, -1):
            if alice_route[left_index] == bob_route[right_index]:
                length_table[left_index][right_index] = 1 + length_table[left_index + 1][right_index + 1]
            else:
                length_table[left_index][right_index] = max(
                    length_table[left_index + 1][right_index],
                    length_table[left_index][right_index + 1],
                )
    answer_table = [[set() for _ in range(bob_length + 1)] for _ in range(alice_length + 1)]
    for left_index in range(alice_length + 1):
        answer_table[left_index][bob_length].add("")
    for right_index in range(bob_length + 1):
        answer_table[alice_length][right_index].add("")
    for left_index in range(alice_length - 1, -1, -1):
        for right_index in range(bob_length - 1, -1, -1):
            best_length = length_table[left_index][right_index]
            candidates = []
            if alice_route[left_index] == bob_route[right_index] and best_length == 1 + length_table[left_index + 1][right_index + 1]:
                candidates.extend(alice_route[left_index] + tail for tail in answer_table[left_index + 1][right_index + 1])
            if best_length == length_table[left_index + 1][right_index]:
                candidates.extend(answer_table[left_index + 1][right_index])
            if best_length == length_table[left_index][right_index + 1]:
                candidates.extend(answer_table[left_index][right_index + 1])
            answer_table[left_index][right_index] = set(candidates)
    return sorted(answer_table[0][0])


SAMPLE_ALICE = "abcabcaa"
SAMPLE_BOB = "acbacba"
SAMPLE_EXPECTED = ["ababa", "abaca", "abcba", "acaba", "acaca", "acbaa", "acbca"]
assert oracle_trips(SAMPLE_ALICE, SAMPLE_BOB) == SAMPLE_EXPECTED
assert brute_trips(SAMPLE_ALICE, SAMPLE_BOB) == SAMPLE_EXPECTED
for alice_route, bob_route, expected in [
    ("a", "a", ["a"]),
    ("ab", "ba", ["a", "b"]),
    ("abc", "acb", ["ab", "ac"]),
]:
    assert oracle_trips(alice_route, bob_route) == expected
    assert brute_trips(alice_route, bob_route) == expected
assert len(oracle_trips("aaabbabbababbaababaababaabbaaaabababaabbabaaaabb", "baabaaabaabababaabbbabababbabaaaaabbaaaabbbaaabab")) == 996


def render(alice_routes, bob_routes):
    input_chunks = [str(len(alice_routes))]
    output_chunks = []
    for alice_route, bob_route in zip(alice_routes, bob_routes):
        trips = oracle_trips(alice_route, bob_route)
        assert 1 <= len(trips) <= 1000
        input_chunks.append(alice_route)
        input_chunks.append(bob_route)
        output_chunks.append("\n".join(trips) + "\n")
    return "\n".join(input_chunks) + "\n", "\n".join(output_chunks)


def write_case(case_name, alice_routes, bob_routes):
    input_text, output_text = render(alice_routes, bob_routes)
    with open(os.path.join(IN_DIR, case_name + ".txt"), "w") as input_file:
        input_file.write(input_text)
    with open(os.path.join(OUT_DIR, case_name + ".out"), "w") as output_file:
        output_file.write(output_text)


def make_random_cases():
    generator = random.Random(987654321)
    alice_routes = []
    bob_routes = []
    while len(alice_routes) < 6:
        alphabet = generator.choice(["ab", "abc", "abcd"])
        alice_length = generator.randint(10, 26)
        bob_length = generator.randint(10, 26)
        alice_route = "".join(generator.choice(alphabet) for _ in range(alice_length))
        bob_route = "".join(generator.choice(alphabet) for _ in range(bob_length))
        if 2 <= len(oracle_trips(alice_route, bob_route)) <= 1000:
            alice_routes.append(alice_route)
            bob_routes.append(bob_route)
    return alice_routes, bob_routes


def main():
    os.makedirs(IN_DIR, exist_ok=True)
    os.makedirs(OUT_DIR, exist_ok=True)
    write_case("1_sample", [SAMPLE_ALICE], [SAMPLE_BOB])
    write_case(
        "2_edges",
        ["a", "abc", "abc", "ab", "aaaa", "abcabc"],
        ["a", "abc", "acb", "ba", "aa", "abcabc"],
    )
    write_case(
        "3_wide",
        ["a" * 80, "a" * 40 + "b" * 40, "ab" * 40, "abcdefghij" * 8],
        ["a" * 80, "b" * 40 + "a" * 40, "ba" * 40, "abcdefghij" * 8],
    )
    write_case("4_random", *make_random_cases())
    write_case(
        "5_io",
        [
            "aaabbabbababbaababaababaabbaaaabababaabbabaaaabb",
            "aaaabaaaaabbbbbbabaaaaaabaaabaaaabbabbaaaaabbbbbbbb",
            "bbbbaababbabbbaababbbbababaabaababababbabaa",
            "aabababbabaabaaaabbbaababbabbabbbabbbbaabbbaababb",
            "baaabaaabaabaaabbaababbabbaababbaababbabbaabbbbabba",
            "aabbaaaaaababababbabababbbabbabbabababbababbab",
        ],
        [
            "baabaaabaabababaabbbabababbabaaaaabbaaaabbbaaabab",
            "babaababbaabbababbaababbabaabababaaaaba",
            "baaaaababababbabbbaabbaaababbbababaabaaab",
            "babaaababaabaabababaaababababaabaabaabbabaa",
            "ababababbaaaababbbbbaaaababbbaabbabaaabaaababbba",
            "baaabaaaabbabaaaabaaaaabbbbbbbbbaabbbaabababaa",
        ],
    )


if __name__ == "__main__":
    main()
