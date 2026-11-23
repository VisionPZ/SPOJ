#!/usr/bin/env python3
import os
import random

BASE = os.path.dirname(os.path.abspath(__file__))


def oracle(words):
    """Decide by constructing an Eulerian trail with Hierholzer's algorithm."""
    total = len(words)
    if total == 0:
        return True
    base = [[] for _ in range(26)]
    for word in words:
        base[ord(word[0]) - 97].append(ord(word[-1]) - 97)
    for start in range(26):
        if not base[start]:
            continue
        adj = [list(lst) for lst in base]
        stack = [(start, None)]
        circuit = []
        while stack:
            vertex, incoming = stack[-1]
            if adj[vertex]:
                nxt = adj[vertex].pop()
                stack.append((nxt, (vertex, nxt)))
            else:
                stack.pop()
                if incoming is not None:
                    circuit.append(incoming)
        if len(circuit) != total:
            continue
        circuit.reverse()
        if circuit[0][0] != start:
            continue
        if all(circuit[k][1] == circuit[k + 1][0] for k in range(total - 1)):
            return True
    return False


def render(cases):
    lines = [str(len(cases))]
    for words in cases:
        lines.append(str(len(words)))
        lines.extend(words)
    return "\n".join(lines) + "\n"


def expected(cases):
    possible = "Ordering is possible.\n"
    impossible = "The door cannot be opened.\n"
    return "".join(possible if oracle(words) else impossible for words in cases)


def emit(name, cases):
    with open(os.path.join(BASE, "in", name + ".txt"), "w") as handle:
        handle.write(render(cases))
    with open(os.path.join(BASE, "out", name + ".out"), "w") as handle:
        handle.write(expected(cases))


def main():
    sample = [
        ["acm", "ibm"],
        ["acm", "malform", "mouse"],
        ["ok", "ok"],
    ]
    assert oracle(sample[0]) is False
    assert oracle(sample[1]) is True
    assert oracle(sample[2]) is False
    emit("1_sample", sample)

    edges = [
        ["ab"],
        ["aa"],
        ["ab", "bc", "ca"],
        ["ab", "bc", "cd"],
        ["ab", "cb"],
        ["ab", "cd"],
        ["ab", "ab"],
        ["ab", "bc", "db"],
        ["zy", "yx", "xz"],
        ["ab", "ba", "cd", "dc"],
        ["abc", "cde", "efg", "gha"],
        ["qz", "zq", "qz"],
    ]
    assert oracle(["ab"]) is True
    assert oracle(["ab", "bc", "ca"]) is True
    assert oracle(["ab", "cd"]) is False
    assert oracle(["ab", "ab"]) is False
    emit("2_edges", edges)

    long_a = "a" + "b" * 999
    long_b = "b" + "a" * 999
    wide_possible = [long_a] * 5000 + [long_b] * 5000
    wide_impossible = ["a" + "b" * 999] * 5000
    assert oracle(wide_possible[:4] + [long_b] * 4) is True
    assert oracle(wide_impossible[:3]) is False
    emit("3_wide", [wide_possible, wide_impossible])

    rng = random.Random(20261123)
    alphabet = "abcdefghijklmnopqrstuvwxyz"
    random_cases = []
    for _ in range(40):
        count = rng.randint(1, 300)
        words = []
        for _ in range(count):
            length = rng.randint(2, 24)
            words.append("".join(rng.choice(alphabet) for _ in range(length)))
        random_cases.append(words)
    emit("4_random", random_cases)

    io_cases = []
    for index in range(500):
        if index % 2 == 0:
            io_cases.append(["ab", "bc", "ca"])
        else:
            io_cases.append(["ab", "ab"])
    emit("5_io", io_cases)

    big_rng = random.Random(777)
    big_lines = ["20"]
    for _ in range(20):
        count = 5000
        big_lines.append(str(count))
        for _ in range(count):
            first = big_rng.choice(alphabet)
            last = big_rng.choice(alphabet)
            middle = big_rng.choice(alphabet) * 997
            big_lines.append(first + middle + last)
    with open("/tmp/WORDS1_big.txt", "w") as handle:
        handle.write("\n".join(big_lines) + "\n")


if __name__ == "__main__":
    main()
