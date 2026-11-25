#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    pos = 0
    test_count = int(tokens[pos])
    pos += 1
    output_lines = []
    for case_index in range(1, test_count + 1):
        line_count = int(tokens[pos])
        depth_target = int(tokens[pos + 1])
        pos += 2
        children = {}
        for _ in range(line_count):
            parent_name = tokens[pos]
            child_total = int(tokens[pos + 1])
            pos += 2
            child_names = tokens[pos:pos + child_total]
            pos += child_total
            children.setdefault(parent_name, []).extend(child_names)
            for child_name in child_names:
                children.setdefault(child_name, [])
        counts = {}
        for person_name in children:
            frontier = [person_name]
            for _ in range(depth_target):
                following = []
                for node in frontier:
                    following.extend(children[node])
                frontier = following
            counts[person_name] = len(frontier)
        candidates = [(name, count) for name, count in counts.items() if count > 0]
        candidates.sort(key=lambda item: (-item[1], item[0]))
        output_lines.append(f"Tree {case_index}:")
        cutoff = candidates[2][1] if len(candidates) >= 3 else None
        printed = 0
        for name, count in candidates:
            if printed < 3 or (cutoff is not None and count == cutoff):
                output_lines.append(f"{name} {count}")
                printed += 1
        output_lines.append("")
    return "\n".join(output_lines) + "\n"


SAMPLE = """3
8 2
Barney 2 Fred Ginger
Ingrid 1 Nolan
Cindy 1 Hal
Jeff 2 Oliva Peter
Don 2 Ingrid Jeff
Fred 1 Kathy
Andrea 4 Barney Cindy Don Eloise
Hal 2 Lionel Mary
6 1
Phillip 5 Jim Phil Jane Joe Paul
Jim 1 Jimmy
Phil 1 Philly
Jane 1 Janey
Joe 1 Joey
Paul 1 Pauly
6 2
Phillip 5 Jim Phil Jane Joe Paul
Jim 1 Jimmy
Phil 1 Philly
Jane 1 Janey
Joe 1 Joey
Paul 1 Pauly
"""
SAMPLE_OUT = """Tree 1:
Andrea 5
Don 3
Cindy 2

Tree 2:
Phillip 5
Jane 1
Jim 1
Joe 1
Paul 1
Phil 1

Tree 3:
Phillip 5

"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1\nA 1 B\nB 0\n") == "Tree 1:\nA 1\n\n"
assert oracle("1\n1 1\nB 0\n") == "Tree 1:\n\n"
assert oracle("1\n3 1\nA 1 B\nB 1 C\nC 0\n") == "Tree 1:\nA 1\nB 1\n\n"
assert oracle("1\n4 2\nA 2 B C\nB 2 D E\nC 0\nD 0\nE 0\n") == "Tree 1:\nA 2\n\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "4\n2 1\nA 1 B\nB 0\n1 1\nB 0\n3 1\nA 1 B\nB 1 C\nC 0\n4 2\nA 2 B C\nB 2 D E\nC 0\nD 0\nE 0\n")
    wide_lines = ["60 3"]
    names = ["Root"]
    for index in range(60):
        child = f"Node{index:02d}"
        wide_lines.append(f"Root 1 {child}" if index == 0 else f"Node{index - 1:02d} 1 {child}")
        names.append(child)
    write("3_wide", "1\n" + "\n".join(wide_lines) + "\n")
    rng = random.Random(20261121)
    cases = []
    case_texts = []
    for case_index in range(6):
        people = [f"P{case_index}_{index}" for index in range(rng.randint(6, 25))]
        lines = []
        for person_index, person in enumerate(people):
            if person_index == 0:
                children = people[1:]
            else:
                children = []
            rng.shuffle(children)
            lines.append(f"{person} {len(children)} " + " ".join(children))
        rng.shuffle(lines)
        case_texts.append(f"{len(people)} {rng.randint(1, 3)}\n" + "\n".join(lines) + "\n")
    write("4_random", f"{len(case_texts)}\n" + "".join(case_texts))
    io_cases = []
    for case_index in range(60):
        io_cases.append("2 1\n")
        io_cases.append(f"A{case_index} 1 B{case_index}\n")
        io_cases.append(f"B{case_index} 0\n")
    write("5_io", f"{len(io_cases) // 3}\n" + "".join(io_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
