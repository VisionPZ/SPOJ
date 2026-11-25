#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def expand_instructions(task_lines):
    kinds = []
    arguments = []
    for token in task_lines:
        if token[0] == "C":
            kinds.extend(["C"] * int(token[1:]))
            arguments.extend([0] * int(token[1:]))
        else:
            kinds.append(token[0])
            arguments.append(int(token[1:]))
    return kinds, arguments


def oracle(text):
    lines = text.splitlines()
    cursor = 0
    answers = []
    while cursor < len(lines) and lines[cursor].strip():
        header = lines[cursor].split()
        task_count = int(header[0])
        resource_count = int(header[1])
        cursor += 1
        starts = []
        bases = []
        all_kinds = []
        all_arguments = []
        for _ in range(task_count):
            fields = lines[cursor].split()
            cursor += 1
            starts.append(int(fields[0]))
            bases.append(int(fields[1]))
            kinds, arguments = expand_instructions(fields[3:3 + int(fields[2])])
            all_kinds.append(kinds)
            all_arguments.append(arguments)
        answers.append(" ".join(str(value) for value in simulate(task_count, resource_count,
                                                                 starts, bases, all_kinds,
                                                                 all_arguments)))
    return "\n".join(answers) + "\n"


def simulate(task_count, resource_count, starts, bases, all_kinds, all_arguments):
    ceiling = [0] * (resource_count + 1)
    for task_index in range(task_count):
        for kind, argument in zip(all_kinds[task_index], all_arguments[task_index]):
            if kind == "L":
                ceiling[argument] = max(ceiling[argument], bases[task_index])
    owners = [-1] * (resource_count + 1)
    stacks = [[] for _ in range(task_count)]
    positions = [0] * task_count
    finished = [False] * task_count
    results = [0] * task_count
    clock = min(starts)
    remaining = task_count
    while remaining:
        running = [task for task in range(task_count)
                   if not finished[task] and starts[task] <= clock]
        current = list(bases)
        for _ in range(task_count + 2):
            changed = False
            for task in running:
                position = positions[task]
                if all_kinds[task][position] != "L":
                    continue
                wanted = all_arguments[task][position]
                inherited = bases[task]
                if owners[wanted] != -1:
                    inherited = max(inherited, current[owners[wanted]])
                for resource in range(1, resource_count + 1):
                    holder = owners[resource]
                    if holder != -1 and holder != task and ceiling[resource] >= current[task]:
                        inherited = max(inherited, current[holder])
                if inherited > current[task]:
                    current[task] = inherited
                    changed = True
            if not changed:
                break
        blocked = [False] * task_count
        for task in running:
            position = positions[task]
            if all_kinds[task][position] != "L":
                continue
            wanted = all_arguments[task][position]
            if owners[wanted] != -1:
                blocked[task] = True
                continue
            for resource in range(1, resource_count + 1):
                holder = owners[resource]
                if holder != -1 and holder != task and ceiling[resource] >= current[task]:
                    blocked[task] = True
                    break
        chosen = -1
        for task in running:
            if not blocked[task] and (chosen == -1 or current[task] > current[chosen]):
                chosen = task
        if chosen == -1:
            clock += 1
            continue
        position = positions[chosen]
        kind = all_kinds[chosen][position]
        argument = all_arguments[chosen][position]
        if kind == "C":
            clock += 1
        elif kind == "L":
            owners[argument] = chosen
            stacks[chosen].append(argument)
        else:
            resource = stacks[chosen].pop()
            owners[resource] = -1
        positions[chosen] += 1
        if positions[chosen] == len(all_kinds[chosen]):
            finished[chosen] = True
            results[chosen] = clock
            remaining -= 1
    return results


SAMPLE = """3 1
50 2 5 C1 L1 C1 U1 C1
1 1 5 C1 L1 C100 U1 C1
70 3 1 C1
3 3
5 3 5 C1 L1 C1 U1 C1
3 2 9 C1 L2 C1 L3 C1 U3 C1 U2 C1
1 1 9 C1 L3 C3 L2 C1 U2 C1 U3 C1
"""
SAMPLE_OUT = """106 107 71
8 15 16
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n1 1 1 C5\n") == "6\n"
assert oracle("1 1\n10 1 2 L1 C3 U1\n") == "13\n"
assert oracle("2 1\n1 2 2 L1 C1 U1\n2 1 1 C1\n") == "2 3\n"


def format_case(task_count, resource_count, tasks):
    lines = [f"{task_count} {resource_count}"]
    for start, base, instructions in tasks:
        lines.append(f"{start} {base} {len(instructions)} " + " ".join(instructions))
    return "\n".join(lines) + "\n"


def random_task(rng, resource_count, base, complexity):
    instructions = []
    held = []
    for _ in range(complexity):
        choices = ["compute"]
        if len(held) < min(3, resource_count):
            choices.append("lock")
        if held:
            choices.append("unlock")
        choice = rng.choice(choices)
        if choice == "compute":
            instructions.append("C" + str(rng.randint(1, 8)))
        elif choice == "lock":
            available = [resource for resource in range(1, resource_count + 1)
                         if resource not in held]
            resource = rng.choice(available)
            held.append(resource)
            instructions.append("L" + str(resource))
        else:
            resource = held.pop()
            instructions.append("U" + str(resource))
    while held:
        instructions.append("U" + str(held.pop()))
    if not instructions:
        instructions.append("C1")
    return instructions


def build():
    rng = random.Random(20261126)
    edges = [
        format_case(1, 1, [(1, 1, ["C5"])]),
        format_case(2, 1, [(1, 2, ["L1", "C2", "U1"]), (3, 1, ["C2"])]),
        format_case(3, 2, [(1, 3, ["L1", "L2", "C2", "U2", "U1"]),
                           (2, 2, ["L2", "C3", "U2"]), (4, 1, ["C1"])]),
    ]
    write("2_edges", edges)
    priorities = list(range(1, 21))
    wide_tasks = []
    for task_index in range(20):
        start = rng.randint(1, 100)
        wide_tasks.append((start, priorities[task_index],
                           random_task(rng, 6, priorities[task_index], 12)))
    write("3_wide", [format_case(20, 6, wide_tasks)])
    random_cases = []
    for _ in range(6):
        task_count = rng.randint(2, 6)
        resource_count = rng.randint(1, 4)
        priorities = list(range(1, task_count + 1))
        rng.shuffle(priorities)
        tasks = []
        for task_index in range(task_count):
            tasks.append((rng.randint(1, 20), priorities[task_index],
                          random_task(rng, resource_count, priorities[task_index], 8)))
        random_cases.append(format_case(task_count, resource_count, tasks))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(120):
        task_count = rng.randint(2, 4)
        resource_count = rng.randint(1, 2)
        priorities = list(range(1, task_count + 1))
        rng.shuffle(priorities)
        tasks = []
        for task_index in range(task_count):
            tasks.append((rng.randint(1, 10), priorities[task_index],
                          random_task(rng, resource_count, priorities[task_index], 4)))
        io_cases.append(format_case(task_count, resource_count, tasks))
    write("5_io", io_cases)


def write(name, cases):
    text = "".join(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
