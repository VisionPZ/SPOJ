#!/usr/bin/env python3
import os
import random
from functools import lru_cache

BASE = 97
FAILURE = "Message cannot be decrypted."


def find_edges(words, alphabet_size):
    edges = []
    for left_word, right_word in zip(words, words[1:]):
        shared = min(len(left_word), len(right_word))
        position = 0
        while position < shared and left_word[position] == right_word[position]:
            position += 1
        if position < shared:
            left_letter = ord(left_word[position]) - BASE
            right_letter = ord(right_word[position]) - BASE
            if 0 <= left_letter < alphabet_size and 0 <= right_letter < alphabet_size and left_letter != right_letter:
                edges.append((left_letter, right_letter))
    return edges


def brute_force(edges, alphabet_size):
    import itertools
    found = None
    count = 0
    for candidate in itertools.permutations(range(alphabet_size)):
        if all(candidate[left] < candidate[right] for left, right in edges):
            count += 1
            if count > 1:
                return 0, None
            found = candidate
    return count, found


def topo_count(edges, alphabet_size):
    successors = [set() for _ in range(alphabet_size)]
    indegree = [0] * alphabet_size
    for left, right in edges:
        if right not in successors[left]:
            successors[left].add(right)
            indegree[right] += 1
    predecessors = [0] * alphabet_size
    for left in range(alphabet_size):
        for right in successors[left]:
            predecessors[right] |= 1 << left
    working = indegree[:]
    queue = [letter for letter in range(alphabet_size) if working[letter] == 0]
    visited = 0
    while queue:
        current = queue.pop()
        visited += 1
        for nxt in successors[current]:
            working[nxt] -= 1
            if working[nxt] == 0:
                queue.append(nxt)
    if visited != alphabet_size:
        return 0, None
    full_mask = (1 << alphabet_size) - 1

    @lru_cache(maxsize=None)
    def walk(placed_mask):
        if placed_mask == full_mask:
            return 1, ()
        total = 0
        first_order = None
        for letter in range(alphabet_size):
            if (placed_mask >> letter) & 1:
                continue
            if predecessors[letter] & ~placed_mask:
                continue
            count, tail = walk(placed_mask | (1 << letter))
            if count == 0:
                continue
            if total == 0:
                first_order = (letter,) + tail
            total += count
            if total >= 2:
                return 2, first_order
        return total, first_order

    return walk(0)


def decide(words, alphabet_size, message):
    edges = find_edges(words, alphabet_size)
    if alphabet_size <= 7:
        count, answer = brute_force(edges, alphabet_size)
    else:
        count, answer = topo_count(edges, alphabet_size)
    if count != 1:
        return FAILURE
    rank = [0] * alphabet_size
    if alphabet_size <= 7:
        for letter, value in enumerate(answer):
            rank[letter] = value
    else:
        for position, letter in enumerate(answer):
            rank[letter] = position
    highest = BASE + alphabet_size - 1
    decoded = []
    for char in message:
        code = ord(char)
        if BASE <= code <= highest:
            decoded.append(chr(BASE + rank[code - BASE]))
        else:
            decoded.append(char)
    return "".join(decoded)


def encrypt(text, cipher, alphabet_size):
    highest = BASE + alphabet_size - 1
    result = []
    for char in text:
        code = ord(char)
        if BASE <= code <= highest:
            result.append(chr(BASE + cipher[code - BASE]))
        else:
            result.append(char)
    return "".join(result)


def make_case(rng, alphabet_size, word_count, longest_word, message_length):
    cipher = list(range(alphabet_size))
    rng.shuffle(cipher)
    plain_words = set()
    attempts = 0
    while len(plain_words) < word_count and attempts < 20000:
        attempts += 1
        length = rng.randint(1, longest_word)
        plain_words.add("".join(chr(BASE + rng.randrange(alphabet_size)) for _ in range(length)))
    plain_words = sorted(plain_words)
    words = [encrypt(word, cipher, alphabet_size) for word in plain_words]
    alphabet_chars = "".join(chr(BASE + index) for index in range(alphabet_size))
    extras = " ,.!?-'" + "XYZ019" + alphabet_chars
    plain_message = "".join(rng.choice(extras) for _ in range(message_length))
    message = encrypt(plain_message, cipher, alphabet_size)
    return alphabet_size, words, message


def make_chain_case(rng, alphabet_size, message_length):
    plain_words = [chr(BASE + index) for index in range(alphabet_size)]
    cipher = list(range(alphabet_size))
    rng.shuffle(cipher)
    words = [encrypt(word, cipher, alphabet_size) for word in plain_words]
    extras = " ,.!?-'" + "".join(chr(BASE + index) for index in range(alphabet_size))
    plain_message = "".join(rng.choice(extras) for _ in range(message_length))
    message = encrypt(plain_message, cipher, alphabet_size)
    return alphabet_size, words, message


def write_cases(name, cases):
    with open("in/" + name + ".txt", "w", newline="\n") as source:
        source.write(str(len(cases)) + "\n")
        for alphabet_size, words, message in cases:
            source.write(str(alphabet_size) + " " + str(len(words)) + "\n")
            for word in words:
                source.write(word + "\n")
            source.write(message + "\n")
    with open("out/" + name + ".out", "w", newline="\n") as target:
        for alphabet_size, words, message in cases:
            target.write(decide(words, alphabet_size, message) + "\n")


def write_sample():
    source_data = (
        "2\n"
        "5 6\n"
        "cebdbac\n"
        "cac\n"
        "ecd\n"
        "dca\n"
        "aba\n"
        "bac\n"
        "cedab\n"
        "4 4\n"
        "cca\n"
        "cad\n"
        "aac\n"
        "bca\n"
        "bdac\n"
    )
    target_data = "abcde\nMessage cannot be decrypted.\n"
    with open("in/1_sample.txt", "w", newline="\n") as source:
        source.write(source_data)
    with open("out/1_sample.out", "w", newline="\n") as target:
        target.write(target_data)


assert decide(["cebdbac", "cac", "ecd", "dca", "aba", "bac"], 5, "cedab") == "abcde"
assert decide(["cca", "cad", "aac", "bca"], 4, "bdac") == FAILURE
assert decide(["a"], 1, "abc!") == "abc!"
assert decide(["a", "b"], 2, "ba") == "ba"
assert decide(["b", "a"], 2, "ab") == "ba"
assert decide(["a", "ab"], 2, "ab") == FAILURE
assert decide(["c", "b", "a"], 3, "cba") == "abc"
assert decide(["abcd", "abdc", "acbd", "acdb"], 4, "dcba") == FAILURE


os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)
write_sample()

edges_cases = [
    (1, ["a"], "a b!?"),
    (1, ["a"], ""),
    (2, ["ab", "ba"], "abba"),
    (3, ["a", "ab", "abc"], "abc"),
    (4, ["abcd", "abdc", "acbd", "acdb"], "dcba"),
    (26, [chr(BASE + index) for index in range(26)], "zyxwvutsrqponmlkjihgfedcba"),
    (5, ["a", "b", "c", "d", "e"], "edcba"),
    (26, ["a", "ab", "abc", "abcd"], "abcd"),
    (7, ["a", "b", "c", "d", "e", "f", "g"], "abcdefg"),
    (2, ["a", "aa", "ab"], "aba"),
]
assert decide(edges_cases[4][1], edges_cases[4][0], edges_cases[4][2]) == FAILURE
assert decide(edges_cases[8][1], edges_cases[8][0], edges_cases[8][2]) == "abcdefg"
write_cases("2_edges", edges_cases)

wide_rng = random.Random(913771)
wide_cases = []
for _ in range(400):
    wide_cases.append(make_case(wide_rng, 26, 60, 20, 200))
write_cases("3_wide", wide_cases)

random_rng = random.Random(20261123)
random_cases = []
for _ in range(320):
    size = random_rng.randint(1, 26)
    count = random_rng.randint(1, 40 if size <= 7 else 90)
    random_cases.append(make_case(random_rng, size, count, 10, random_rng.randint(0, 120)))
write_cases("4_random", random_cases)

io_rng = random.Random(5150)
io_cases = []
for _ in range(600):
    io_cases.append(make_chain_case(io_rng, 26, 6000))
write_cases("5_io", io_cases)

print("generated", len(random_cases), "random cases and", len(io_cases), "IO cases")
