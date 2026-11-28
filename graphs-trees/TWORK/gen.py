#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse_input(text):
    tokens = text.split()
    pos = 0
    case_count = int(tokens[pos]); pos += 1
    cases = []
    for _ in range(case_count):
        n = int(tokens[pos]); m = int(tokens[pos + 1]); pos += 2
        adjacency = [set() for _ in range(n + 1)]
        edges = []
        for _ in range(m):
            a = int(tokens[pos]); b = int(tokens[pos + 1]); pos += 2
            adjacency[a].add(b)
            adjacency[b].add(a)
            edges.append((a, b))
        cases.append((n, m, edges, adjacency))
    return cases


def validate(input_text, output_text):
    cases = parse_input(input_text)
    tokens = output_text.split()
    pos = 0
    for n, m, edges, adjacency in cases:
        if pos >= len(tokens):
            return False
        k = int(tokens[pos]); pos += 1
        if k < 0 or 4 * k < n or 3 * k > n:
            return False
        used = [False] * (n + 1)
        for _ in range(k):
            if pos + 2 >= len(tokens):
                return False
            first = int(tokens[pos]); center = int(tokens[pos + 1]); third = int(tokens[pos + 2])
            pos += 3
            members = (first, center, third)
            if len(set(members)) != 3:
                return False
            if any(member < 1 or member > n or used[member] for member in members):
                return False
            valid_group = ((center in adjacency[first] and center in adjacency[third]) or
                           (first in adjacency[center] and third in adjacency[center]) or
                           (first in adjacency[third] and center in adjacency[third]))
            if not valid_group:
                return False
            for member in members:
                used[member] = True
    return pos == len(tokens)


def max_groups_bruteforce(n, edges):
    adjacency = [set() for _ in range(n + 1)]
    for a, b in edges:
        adjacency[a].add(b)
        adjacency[b].add(a)
    used = [False] * (n + 1)

    def recurse():
        best = 0
        for a in range(1, n + 1):
            if used[a]:
                continue
            for b in range(a + 1, n + 1):
                if used[b]:
                    continue
                for c in range(b + 1, n + 1):
                    if used[c]:
                        continue
                    valid = ((b in adjacency[a] and c in adjacency[a]) or
                             (a in adjacency[b] and c in adjacency[b]) or
                             (a in adjacency[c] and b in adjacency[c]))
                    if not valid:
                        continue
                    for member in (a, b, c):
                        used[member] = True
                    best = max(best, 1 + recurse())
                    for member in (a, b, c):
                        used[member] = False
        return best

    return recurse()


def cycle_case(n, seed, extra=0):
    perm = list(range(1, n + 1))
    random.Random(seed).shuffle(perm)
    edges = [(perm[i], perm[(i + 1) % n]) for i in range(n)]
    adjacency = [set() for _ in range(n + 1)]
    for a, b in edges:
        adjacency[a].add(b)
        adjacency[b].add(a)
    picker = random.Random(seed + 991)
    if n <= 1000:
        candidates = [(a, b) for a in range(1, n + 1) for b in range(a + 1, n + 1)
                      if len(adjacency[a]) < 3 and len(adjacency[b]) < 3
                      and b not in adjacency[a]]
        picker.shuffle(candidates)
        added = 0
        for first, second in candidates:
            if added >= extra:
                break
            if len(adjacency[first]) >= 3 or len(adjacency[second]) >= 3:
                continue
            edges.append((first, second))
            adjacency[first].add(second)
            adjacency[second].add(first)
            added += 1
        assert added == extra
    else:
        added = 0
        attempts = 0
        while added < extra and attempts < 100 * extra + 1000:
            first = picker.randint(1, n)
            second = picker.randint(1, n)
            attempts += 1
            if first == second or second in adjacency[first]:
                continue
            if len(adjacency[first]) >= 3 or len(adjacency[second]) >= 3:
                continue
            edges.append((first, second))
            adjacency[first].add(second)
            adjacency[second].add(first)
            added += 1
        assert added == extra
    groups = []
    for start in range(0, n - 2, 3):
        groups.append((perm[start], perm[start + 1], perm[start + 2]))
    return n, n + extra, edges, groups


def k4_chain_case(blocks):
    n = 4 * blocks
    edges = []
    groups = []
    for block in range(blocks):
        base = 4 * block + 1
        a, b, c, d = base, base + 1, base + 2, base + 3
        for x, y in ((a, c), (a, d), (b, c), (b, d), (c, d)):
            edges.append((x, y))
        groups.append((a, c, b))
        if block > 0:
            edges.append((4 * (block - 1) + 1, b))
    return n, len(edges), edges, groups


def cycle_chain_case(lengths):
    n = sum(lengths)
    edges = []
    groups = []
    spans = []
    offset = 1
    for length in lengths:
        vertices = list(range(offset, offset + length))
        for index in range(length):
            edges.append((vertices[index], vertices[(index + 1) % length]))
        spans.append(vertices)
        offset += length
    for index, (first, second) in enumerate(zip(spans, spans[1:])):
        outgoing = first[-1] if index % 2 == 0 else first[0]
        incoming = second[0] if (index + 1) % 2 == 0 else second[-1]
        edges.append((outgoing, incoming))
    for index, vertices in enumerate(spans):
        groups.append((vertices[1], vertices[2], vertices[3]))
        if index % 2 == 0 and len(vertices) > 4 and index + 1 < len(spans):
            previous = vertices
            other = previous[0]
            outgoing = previous[-1]
            incoming_spans = spans[index + 1]
            incoming = (incoming_spans[0] if (index + 1) % 2 == 0
                        else incoming_spans[-1])
            groups.append((other, outgoing, incoming))
    return n, len(edges), edges, groups


def case_text(case):
    n, m, edges, groups = case
    lines = [f"{n} {m}"]
    lines.extend(f"{a} {b}" for a, b in edges)
    answer = [str(len(groups))]
    answer.extend(f"{a} {c} {b}" for a, c, b in groups)
    return "\n".join(lines) + "\n", "\n".join(answer) + "\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(case_text(case)[0] for case in cases)
    output_text = "".join(case_text(case)[1] for case in cases)
    assert validate(input_text, output_text), name
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


SAMPLE_INPUT = ("1\n8 10\n1 2\n1 3\n2 5\n4 6\n3 7\n2 3\n"
                "5 6\n6 7\n7 8\n8 4\n")
SAMPLE_OUTPUT = "2\n1 3 7\n4 5 6\n"

assert SAMPLE_INPUT.startswith("1\n8 10\n")
assert validate(SAMPLE_INPUT, SAMPLE_OUTPUT)
assert not validate(SAMPLE_INPUT, "2\n1 3 7\n4 5 8\n")
assert not validate(SAMPLE_INPUT, "0\n")
assert max_groups_bruteforce(5, [(1, 2), (2, 3), (3, 4), (4, 5), (5, 1)]) == 1
assert max_groups_bruteforce(4, [(1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]) == 1


def build():
    write("1_sample", [(8, 10, [(1, 2), (1, 3), (2, 5), (4, 6), (3, 7), (2, 3),
                                 (5, 6), (6, 7), (7, 8), (8, 4)],
                        [(1, 3, 7), (4, 5, 6)])])

    write("2_edges", [
        cycle_case(4, 1001),
        (4, 6, [(1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)], [(2, 1, 3)]),
        k4_chain_case(2),
        cycle_chain_case([4, 4]),
        cycle_chain_case([5, 5, 5, 5]),
        cycle_case(12, 1002, 4),
    ])

    wide = [cycle_case(20000, 2001), cycle_case(19996, 2002, 4),
            cycle_case(4, 2003)]
    write("3_wide", wide)

    random.seed(7777)
    random_cases = []
    for index in range(20):
        n = 4 * random.randint(2, 100)
        extra = random.randint(0, n // 2)
        random_cases.append(cycle_case(n, 3000 + index, extra))
    write("4_random", random_cases)

    io_cases = [cycle_case(20000, 4000 + index) for index in range(20)]
    write("5_io", io_cases)


def example():
    edges = [(1, 2), (1, 3), (2, 5), (4, 6), (3, 7), (2, 3),
             (5, 6), (6, 7), (7, 8), (8, 4)]
    adjacency = [set() for _ in range(9)]
    for first, second in edges:
        adjacency[first].add(second)
        adjacency[second].add(first)
    available = set(range(1, 9))
    lines = []
    while True:
        centers = [scientist for scientist in sorted(available)
                   if len(adjacency[scientist] & available) >= 2]
        if not centers:
            break
        center = centers[0]
        first, second = sorted(adjacency[center] & available)[:2]
        lines.append(f"center {center}: neighbors {first}, {second} -> group {first} {center} {second}")
        available -= {center, first, second}
    lines.append(f"assigned {8 - len(available)} of 8; uncovered {100 * len(available) // 8}%")
    print("\n".join(lines))


if __name__ == "__main__":
    if len(sys.argv) == 4 and sys.argv[1] == "--check":
        source = Path(sys.argv[2]).read_text()
        result = Path(sys.argv[3]).read_text()
        sys.exit(0 if validate(source, result) else 1)
    if len(sys.argv) == 2 and sys.argv[1] == "--example":
        example()
    else:
        build()
