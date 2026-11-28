#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def valid(triples):
    information = {}
    for own, first_word, second_word in triples:
        if first_word.endswith("jk") and second_word.endswith("jk"):
            gender, first_parent, second_parent = "M", first_word[:-2], second_word[:-2]
        elif first_word.endswith("gvw") and second_word.endswith("gvw"):
            gender, first_parent, second_parent = "F", first_word[:-3], second_word[:-3]
        else:
            return False
        if not first_parent or not second_parent or first_parent == second_parent:
            return False
        if own in information:
            return False
        information[own] = (gender, first_parent, second_parent)
    listed_names = set(information)

    partner = {}
    for _own, (_gender, first_parent, second_parent) in information.items():
        for person, spouse in ((first_parent, second_parent), (second_parent, first_parent)):
            if person in partner and partner[person] != spouse:
                return False
            partner[person] = spouse

    for _own, (_gender, first_parent, second_parent) in information.items():
        first_gender = information.get(first_parent, ("?",))[0]
        second_gender = information.get(second_parent, ("?",))[0]
        if first_gender == "M" and second_gender == "M":
            return False

    def parent_key(name):
        if name not in information:
            return None
        _gender, first_parent, second_parent = information[name]
        return tuple(sorted((first_parent, second_parent)))

    for _own, (_gender, first_parent, second_parent) in information.items():
        if parent_key(first_parent) is not None and parent_key(first_parent) == parent_key(second_parent):
            return False

    adjacency = {name: [] for name in listed_names}
    indegree = {name: 0 for name in listed_names}
    for own, (_gender, first_parent, second_parent) in information.items():
        for parent in (first_parent, second_parent):
            if parent in information:
                adjacency[parent].append(own)
                indegree[own] += 1
    queue = deque(name for name in listed_names if indegree[name] == 0)
    processed = 0
    while queue:
        current = queue.popleft()
        processed += 1
        for child in adjacency[current]:
            indegree[child] -= 1
            if indegree[child] == 0:
                queue.append(child)
    if processed != len(listed_names):
        return False

    graph = {}
    for own, (_gender, first_parent, second_parent) in information.items():
        graph.setdefault(own, set())
        for parent in (first_parent, second_parent):
            graph.setdefault(own, set()).add(parent)
            graph.setdefault(parent, set()).add(own)
    start = next(iter(listed_names))
    reached = {start}
    queue = deque([start])
    while queue:
        current = queue.popleft()
        for neighbour in graph.get(current, ()):
            if neighbour not in reached:
                reached.add(neighbour)
                queue.append(neighbour)
    return all(name in reached for name in listed_names)


def oracle(text):
    lines = text.strip().split("\n")
    case_count = int(lines[0])
    cursor = 1
    answers = []
    for _case in range(case_count):
        person_count = int(lines[cursor])
        cursor += 1
        triples = [tuple(lines[cursor + index].split()) for index in range(person_count)]
        cursor += person_count
        answers.append("YES" if valid(triples) else "NO")
    return "\n".join(answers) + "\n"


def alpha_suffix(index):
    result = ""
    while True:
        result = chr(97 + index % 26) + result
        index //= 26
        if index == 0:
            return result


def valid_chain(count, prefix="c", male_prefix="m", female_prefix="f"):
    triples = [(prefix + alpha_suffix(0), male_prefix + alpha_suffix(0) + "gvw",
                female_prefix + alpha_suffix(0) + "gvw")]
    for index in range(1, count):
        triples.append((prefix + alpha_suffix(index),
                        prefix + alpha_suffix(index - 1) + "gvw",
                        male_prefix + alpha_suffix(index) + "gvw"))
    return triples


def bad_suffix():
    return [("a", "bjk", "cgvw")]


def two_men():
    return [("a", "xjk", "yjk"), ("b", "ujk", "vjk"), ("c", "ajk", "bjk")]


def sibling_marriage():
    return [("sa", "agvw", "bgvw"), ("sb", "agvw", "bgvw"), ("child", "sagvw", "sbgvw")]


def bad_partner():
    return [("docs", "afegvw", "fegvw"), ("draw", "rridajk", "cajk"),
            ("pito", "docsjk", "drawjk"), ("extra", "docsjk", "fejk")]


SAMPLE = """1
3
docs afegvw fegvw
draw rridajk cajk
pito docsjk drawjk
"""
SAMPLE_OUT = """YES
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert valid(valid_chain(5))
assert not valid(bad_suffix())
assert not valid(two_men())
assert not valid(sibling_marriage())
assert not valid(valid_chain(3) + valid_chain(3, "d", "n", "p"))
assert not valid(bad_partner())


def write_cases(name, cases):
    blocks = []
    for triples in cases:
        lines = [str(len(triples))]
        lines.extend(" ".join(triple) for triple in triples)
        blocks.append("\n".join(lines))
    text = str(len(cases)) + "\n" + "\n".join(blocks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    answers = ["YES" if valid(triples) else "NO" for triples in cases]
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")


def build():
    write_cases("2_edges", [
        [("a", "bjk", "cjk")],
        bad_suffix(),
        [("a", "bgvw", "cgvw")],
        two_men(),
    ])
    write_cases("3_wide", [valid_chain(100)])
    rng = random.Random(20261126)
    invalid_sets = [bad_suffix(), two_men(), sibling_marriage(), bad_partner(),
                    valid_chain(3) + valid_chain(3, "d", "n", "p")]
    random_cases = []
    for _ in range(8):
        if rng.random() < 0.5:
            random_cases.append(valid_chain(rng.randint(1, 12)))
        else:
            random_cases.append(rng.choice(invalid_sets))
    write_cases("4_random", random_cases)
    io_cases = []
    for index in range(30):
        if index % 2 == 0:
            io_cases.append(valid_chain(rng.randint(2, 8)))
        else:
            io_cases.append(rng.choice(invalid_sets))
    write_cases("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
