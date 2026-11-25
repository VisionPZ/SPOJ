#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    outputs = []
    for _ in range(case_count):
        node_count = tokens[cursor]
        segment_count = tokens[cursor + 1]
        cursor += 2
        segments = []
        for _ in range(segment_count):
            first_node = tokens[cursor]
            second_node = tokens[cursor + 1]
            length = tokens[cursor + 2]
            cursor += 3
            segments.append([first_node, second_node, length])
        changed = True
        while changed:
            changed = False
            for station in range(1, node_count + 1):
                incident = []
                for index, segment in enumerate(segments):
                    if segment[0] == station and segment[1] == station:
                        incident.extend([index, index])
                    elif segment[0] == station:
                        incident.append(index)
                    elif segment[1] == station:
                        incident.append(index)
                if len(incident) != 2:
                    continue
                first_index, second_index = incident
                if (first_index == second_index and
                        segments[first_index][0] == station and
                        segments[first_index][1] == station):
                    continue
                first_segment = segments[first_index]
                second_segment = segments[second_index]
                first_neighbor = (first_segment[1] if first_segment[0] == station
                                  else first_segment[0])
                second_neighbor = (second_segment[1] if second_segment[0] == station
                                   else second_segment[0])
                merged_length = first_segment[2] + second_segment[2]
                if first_index == second_index:
                    segments = [segment for index, segment in enumerate(segments)
                                if index != first_index]
                else:
                    segments = [segment for index, segment in enumerate(segments)
                                if index not in (first_index, second_index)]
                segments.append([first_neighbor, second_neighbor, merged_length])
                changed = True
                break
        normalized = []
        for first_node, second_node, length in segments:
            if first_node > second_node:
                first_node, second_node = second_node, first_node
            normalized.append((first_node, second_node, length))
        normalized.sort()
        lines = [str(len(normalized))]
        lines.extend(f"{first} {second} {length}" for first, second, length in normalized)
        outputs.append("\n".join(lines))
    return "\n\n".join(outputs) + "\n"


SAMPLE = """2

3 2
1 2 1
2 3 1

4 4
1 2 1
2 3 2
3 4 3
4 2 1
"""
SAMPLE_OUT = """1
1 3 2

2
1 2 1
2 2 6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1\n1 2 5\n") == "1\n1 2 5\n"
assert oracle("1\n4 3\n1 2 1\n2 3 2\n3 4 3\n") == "1\n1 4 6\n"


def write(name, cases):
    parts = [str(len(cases))]
    for node_count, segments in cases:
        parts.append(f"{node_count} {len(segments)}")
        parts.extend(f"{first} {second} {length}" for first, second, length in segments)
    text = "\n\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_connected(node_count, extra_edges, rng):
    segments = [(parent, child, rng.randint(1, 30))
                for child in range(2, node_count + 1)
                for parent in [rng.randint(1, child - 1)]]
    existing = {frozenset((first, second)) for first, second, _ in segments}
    for _ in range(extra_edges):
        first = rng.randint(1, node_count)
        second = rng.randint(1, node_count)
        if first == second or frozenset((first, second)) in existing:
            continue
        existing.add(frozenset((first, second)))
        segments.append((first, second, rng.randint(1, 30)))
    return segments


def build():
    write("2_edges", [
        (2, [(1, 2, 7)]),
        (3, [(1, 2, 1), (2, 3, 1)]),
        (5, [(1, 2, 1), (2, 3, 2), (3, 4, 3), (4, 5, 4), (5, 1, 5), (1, 4, 6)]),
        (6, [(1, 2, 1), (2, 3, 1), (3, 1, 1), (1, 4, 2), (4, 5, 2), (5, 6, 2), (6, 4, 2)]),
    ])
    rng = random.Random(20261129)
    wide_cases = []
    for _ in range(4):
        nodes = rng.randint(120, 200)
        wide_cases.append((nodes, random_connected(nodes, rng.randint(20, 60), rng)))
    write("3_wide", wide_cases)
    random_cases = []
    for _ in range(12):
        nodes = rng.randint(4, 35)
        random_cases.append((nodes, random_connected(nodes, rng.randint(0, nodes // 2), rng)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(250):
        io_cases.append((6, random_connected(6, rng.randint(0, 5), rng)))
    write("5_io", io_cases)
    big_segments = random_connected(2000, 1000, rng)
    big_parts = ["1", f"2000 {len(big_segments)}"]
    big_parts.extend(f"{first} {second} {length}" for first, second, length in big_segments)
    Path("/tmp/RAIL_big.txt").write_text("\n".join(big_parts) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
