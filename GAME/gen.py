#!/usr/bin/env python3
import os
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_IN = """3
A
B
C
A B
B C
5
A
B
C
D
E
A B
C D
A E
C E
0
"""

SAMPLE_OUT = """Round #1
B defeats A
C advances with wildcard
Round #2
C defeats B
Winner: C

Round #1
A defeats B
C defeats D
E advances with wildcard
Round #2
E defeats A
C advances with wildcard
Round #3
E defeats C
Winner: E

"""


def parse_cases(text):
    tokens = text.split()
    cursor = 0
    cases = []
    while True:
        team_count = int(tokens[cursor]); cursor += 1
        if team_count == 0:
            break
        names = tokens[cursor:cursor + team_count]; cursor += team_count
        lookup = {name: index for index, name in enumerate(names)}
        games = []
        for _ in range(team_count - 1):
            first = lookup[tokens[cursor]]; cursor += 1
            second = lookup[tokens[cursor]]; cursor += 1
            games.append((first, second))
        cases.append((names, games))
    return cases


def make_input(cases):
    pieces = []
    for names, games in cases:
        pieces.append(str(len(names)) + "\n")
        pieces.extend(name + "\n" for name in names)
        pieces.extend(f"{names[first]} {names[second]}\n" for first, second in games)
    pieces.append("0\n")
    return "".join(pieces)


def oracle_schedule(cases):
    result = []
    for names, games in cases:
        team_count = len(names)
        adjacency = [[] for _ in range(team_count)]
        for first, second in games:
            adjacency[first].append(second)
            adjacency[second].append(first)
        for neighbors in adjacency:
            neighbors.sort()
        degree = [len(neighbors) for neighbors in adjacency]
        alive = [True] * team_count
        remaining = team_count
        round_number = 1
        while remaining > 1:
            had_wildcard = (remaining % 2) == 1
            matches_leaf = [-1] * team_count
            seen_mark = [0] * team_count
            mark = 0

            def augment(parent):
                nonlocal mark
                mark += 1
                for leaf in adjacency[parent]:
                    if not alive[leaf] or degree[leaf] != 1 or seen_mark[leaf] == mark:
                        continue
                    seen_mark[leaf] = mark
                    previous_parent = matches_leaf[leaf]
                    if previous_parent < 0 or augment(previous_parent):
                        matches_leaf[leaf] = parent
                        return True
                return False

            for parent in range(team_count):
                if not alive[parent]:
                    continue
                for leaf in adjacency[parent]:
                    if alive[leaf] and degree[leaf] == 1:
                        augment(parent)
                        break
            chosen = sorted((leaf, matches_leaf[leaf]) for leaf in range(team_count) if matches_leaf[leaf] >= 0)
            chosen = chosen[:remaining // 2]
            assert len(chosen) == remaining // 2
            involved = set()
            result.append(f"Round #{round_number}")
            for leaf, parent in chosen:
                result.append(f"{names[parent]} defeats {names[leaf]}")
                involved.add(leaf)
                involved.add(parent)
            for leaf, parent in chosen:
                alive[leaf] = False
                degree[leaf] = 0
                degree[parent] -= 1
                remaining -= 1
            if had_wildcard:
                for team in range(team_count):
                    if alive[team] and team not in involved:
                        result.append(f"{names[team]} advances with wildcard")
                        break
            round_number += 1
        for team in range(team_count):
            if alive[team]:
                result.append(f"Winner: {names[team]}")
                break
        result.append("")
    return "\n".join(result) + "\n"


def validate_output(cases, output_text):
    blocks = output_text.split("\n\n")
    assert blocks[-1] == "" and len(blocks) == len(cases) + 1
    for case_index, (names, games) in enumerate(cases):
        lookup = {name: index for index, name in enumerate(names)}
        all_games = {frozenset((first, second)) for first, second in games}
        lines = blocks[case_index].split("\n")
        cursor = 0
        assert lines[cursor] == "Round #1"
        remaining = set(range(len(names)))
        used_games = set()
        round_number = 1
        while True:
            assert lines[cursor] == f"Round #{round_number}"
            cursor += 1
            games_here = []
            wildcard = None
            participants = set()
            while cursor < len(lines) and not lines[cursor].startswith("Round #") and not lines[cursor].startswith("Winner: "):
                line = lines[cursor]
                if " defeats " in line:
                    parts = line.split(" defeats ")
                    assert len(parts) == 2
                    winner = lookup[parts[0]]
                    loser = lookup[parts[1]]
                    assert winner in remaining and loser in remaining and winner != loser
                    game = frozenset((winner, loser))
                    assert game in all_games and game not in used_games
                    used_games.add(game)
                    games_here.append((winner, loser))
                    participants.add(winner)
                    participants.add(loser)
                elif line.endswith(" advances with wildcard"):
                    wildcard = lookup[line[:-len(" advances with wildcard")]]
                    assert wildcard in remaining
                else:
                    raise AssertionError("unexpected line: " + line)
                cursor += 1
            count = len(remaining)
            assert len(games_here) == count // 2
            assert len(participants) == 2 * len(games_here)
            if count % 2 == 1:
                assert wildcard is not None and wildcard not in participants
            else:
                assert wildcard is None
            for winner, loser in games_here:
                remaining.remove(loser)
            assert len(remaining) == (count + 1) // 2
            for game in all_games:
                if game not in used_games:
                    assert all(team in remaining for team in game)
            if cursor < len(lines) and lines[cursor].startswith("Winner: "):
                assert len(remaining) == 1
                assert lookup[lines[cursor][len("Winner: "):]] in remaining
                cursor += 1
                assert cursor == len(lines)
                break
            round_number += 1
        assert used_games == all_games


def valid_rounds(adjacency, alive_set):
    count = len(alive_set)
    if count == 1:
        return [frozenset()]
    needed = count // 2
    leaves = sorted(team for team in alive_set if sum(1 for other in adjacency[team] if other in alive_set) == 1)
    neighbor_of = {team: next(other for other in adjacency[team] if other in alive_set) for team in leaves}
    found = []
    def search(index, chosen, used_neighbors):
        if len(chosen) == needed:
            found.append(frozenset(chosen))
            return
        if index == len(leaves) or len(leaves) - index < needed - len(chosen):
            return
        team = leaves[index]
        if neighbor_of[team] not in used_neighbors:
            search(index + 1, chosen + [team], used_neighbors | {neighbor_of[team]})
        search(index + 1, chosen, used_neighbors)
    search(0, [], set())
    return found


def schedulable_brute(team_count, games):
    adjacency = [[] for _ in range(team_count)]
    for first, second in games:
        adjacency[first].append(second)
        adjacency[second].append(first)
    memo = {}
    def solve(alive_set):
        key = frozenset(alive_set)
        if key in memo:
            return memo[key]
        if len(key) == 1:
            memo[key] = True
            return True
        for losers in valid_rounds(adjacency, key):
            if solve(key - losers):
                memo[key] = True
                return True
        memo[key] = False
        return False
    return solve(frozenset(range(team_count)))


def prufer_trees(team_count):
    import itertools
    import heapq
    for sequence in itertools.product(range(team_count), repeat=team_count - 2):
        degree = [1] * team_count
        for value in sequence:
            degree[value] += 1
        leaves = [index for index in range(team_count) if degree[index] == 1]
        heapq.heapify(leaves)
        edges = []
        for value in sequence:
            leaf = heapq.heappop(leaves)
            edges.append((leaf, value))
            degree[leaf] -= 1
            degree[value] -= 1
            if degree[value] == 1:
                heapq.heappush(leaves, value)
        edges.append((heapq.heappop(leaves), heapq.heappop(leaves)))
        yield edges


assert oracle_schedule(parse_cases(SAMPLE_IN)) == SAMPLE_OUT
assert make_input(parse_cases(SAMPLE_IN)) == SAMPLE_IN
validate_output(parse_cases(SAMPLE_IN), SAMPLE_OUT)
sample_blocks = SAMPLE_OUT.split("\n\n")[:-1]
assert [block.count("Round #") for block in sample_blocks] == [2, 3]
assert [block.split("Winner: ")[1] for block in sample_blocks] == ["C", "E"]
assert SAMPLE_OUT.endswith("\n\n") and len(sample_blocks) == 2

counts = {}
for size in (4, 5, 6):
    counts[size] = sum(1 for edges in prufer_trees(size) if schedulable_brute(size, edges))
assert counts == {4: 12, 5: 120, 6: 360}
assert not schedulable_brute(4, [(0, 1), (0, 2), (0, 3)])
assert schedulable_brute(4, [(0, 1), (1, 2), (2, 3)])
assert schedulable_brute(3, [(0, 1), (1, 2)])


def random_name(rng, used):
    while True:
        length = rng.randint(2, 7)
        name = "".join(rng.choice("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ") for _ in range(length))
        if name not in used:
            used.add(name)
            return name


def grow_tree(team_count, rng):
    sizes = [team_count]
    while sizes[-1] > 1:
        sizes.append((sizes[-1] + 1) // 2)
    sizes.reverse()
    vertices = [0]
    edges = []
    for step in range(1, len(sizes)):
        additions = sizes[step] - sizes[step - 1]
        hosts = rng.sample(vertices, additions)
        for new_vertex, host in enumerate(hosts, start=len(vertices)):
            edges.append((host, new_vertex))
        vertices.extend(range(len(vertices), len(vertices) + additions))
    return edges


def make_case(team_count, rng):
    edges = grow_tree(team_count, rng)
    used_names = set()
    names = [random_name(rng, used_names) for _ in range(team_count)]
    games = []
    for first, second in edges:
        if rng.random() < 0.5:
            first, second = second, first
        games.append((first, second))
    rng.shuffle(games)
    return (names, games)


def write_case_set(name, cases):
    input_text = make_input(cases)
    output_text = oracle_schedule(cases)
    validate_output(cases, output_text)
    for names, games in cases:
        if len(names) <= 7:
            assert schedulable_brute(len(names), games)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

write_case_set("1_sample", parse_cases(SAMPLE_IN))

edge_rng = random.Random(7001)
edge_cases = [
    (["Q", "R"], [(0, 1)]),
    (["Cat", "Dog", "Eel"], [(0, 1), (1, 2)]),
    (["p", "q", "r", "s"], [(0, 1), (1, 2), (2, 3)]),
]
edge_cases += [make_case(size, edge_rng) for size in (5, 6, 7, 7, 8)]
write_case_set("2_edges", edge_cases)

wide_rng = random.Random(7002)
write_case_set("3_wide", [make_case(size, wide_rng) for size in (1000, 999, 512, 1000)])

random_rng = random.Random(7003)
random_sizes = [random_rng.randint(2, 160) for _ in range(24)]
write_case_set("4_random", [make_case(size, random_rng) for size in random_sizes])

io_rng = random.Random(7004)
write_case_set("5_io", [make_case(1000, io_rng) for _ in range(60)])

print("generated five pairs; sample and brute-force constants verified")
