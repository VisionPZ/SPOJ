#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse(text):
    tokens = text.split()
    cursor = 0
    cases = []
    while cursor < len(tokens):
        count = int(tokens[cursor]); cursor += 1
        if count == 0:
            break
        words = tokens[cursor:cursor + count]
        cursor += count
        cases.append(words)
    return cases


def edges_of(words):
    edges = []
    for word in words:
        if len(word) == 1:
            code = (ord(word) - 97) * 26 + ord(word) - 97
            edges.append((code, code, 1))
        else:
            first = (ord(word[0]) - 97) * 26 + ord(word[1]) - 97
            last = (ord(word[-2]) - 97) * 26 + ord(word[-1]) - 97
            edges.append((first, last, len(word)))
    return edges


def positive_cycle(edges, shift):
    distance = [0.0] * 676
    for step in range(676):
        changed = False
        for source, target, length in edges:
            candidate = distance[source] + length - shift
            if candidate > distance[target] + 1e-9:
                distance[target] = candidate
                changed = True
                if step == 675:
                    return True
        if not changed:
            return False
    return False


def oracle(text):
    lines = []
    for words in parse(text):
        edges = edges_of(words)
        if not positive_cycle(edges, 0.0):
            lines.append("No solution.")
            continue
        low, high = 0.0, max(length for _, _, length in edges) + 1.0
        for _ in range(40):
            middle = (low + high) / 2.0
            if positive_cycle(edges, middle):
                low = middle
            else:
                high = middle
        scaled = int(low * 100 + 1e-6)
        lines.append(f"{scaled // 100}.{scaled % 100:02d}")
    return "\n".join(lines) + "\n"


def brute_oracle(words):
    edges = edges_of(words)
    adjacent = {}
    for source, target, length in edges:
        adjacent.setdefault(source, []).append((target, length))
    best = None
    for start in adjacent:
        stack = [(start, [start], 0)]
        while stack:
            vertex, path, total = stack.pop()
            for target, length in adjacent.get(vertex, []):
                if target == start:
                    average = (total + length) / len(path)
                    if best is None or average > best:
                        best = average
                elif target not in path and target > start:
                    stack.append((target, path + [target], total + length))
    if best is None:
        return "No solution."
    scaled = int(best * 100 + 1e-6)
    return f"{scaled // 100}.{scaled % 100:02d}"


SAMPLE = """3
intercommunicational
alkylbenzenesulfonate
tetraiodophenolphthalein
0
"""
SAMPLE_OUT = """21.66
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_oracle(parse(SAMPLE)[0]) + "\n" == SAMPLE_OUT
assert oracle("1\naa\n0\n") == "2.00\n"
assert oracle("1\na\n0\n") == "1.00\n"
assert oracle("2\nabc\ncde\n0\n") == "No solution.\n"
assert oracle("2\nabc\nbcab\n0\n") == "3.50\n"
assert brute_oracle(["abc", "bcab"]) + "\n" == "3.50\n"


def write(name, cases):
    text = "".join(f"{len(words)}\n" + "\n".join(words) + "\n0\n" for words in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ["aa"], ["a"], ["abc", "cde"], ["ab", "ba"], ["abc", "ca", "bcb"], ["zzzz"],
    ])
    rng = random.Random(20261125)
    wide = ["".join(rng.choice("abcdefghijklmnopqrstuvwxyz") for _ in range(1000))
            for _ in range(300)]
    write("3_wide", [wide])
    random_cases = []
    for _ in range(4):
        case = ["".join(rng.choice("abcd") for _ in range(rng.randint(1, 12)))
                for _ in range(20)]
        assert oracle(f"{len(case)}\n" + "\n".join(case) + "\n0\n") == brute_oracle(case) + "\n"
        random_cases.append(case)
    write("4_random", random_cases)
    io_cases = [["ab", "ba"] for _ in range(200)]
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", parse(SAMPLE))
build()
