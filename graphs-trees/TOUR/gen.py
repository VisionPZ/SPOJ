import os
import random

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

SAMPLE = """1
3
2 3 2
1 3
0
"""


def build_can_beat(beats, player_total):
    """Row masks of rivals that a player may beat, as one big integer."""
    rows = []
    for player in range(player_total):
        mask = 0
        for rival in range(player_total):
            if rival != player and not beats[rival][player]:
                mask |= 1 << rival
        rows.append(mask)
    return rows


def oracle(beats, player_total):
    """Count the unique source strongly connected component of the beats graph."""
    adjacency = [[] for _ in range(player_total)]
    reverse = [[] for _ in range(player_total)]
    for victim in range(player_total):
        for better in range(player_total):
            if beats[better][victim]:
                adjacency[better].append(victim)
                reverse[victim].append(better)
    visited = [False] * player_total
    finish = []
    for start in range(player_total):
        if visited[start]:
            continue
        stack = [(start, 0)]
        visited[start] = True
        while stack:
            node, index = stack[-1]
            if index < len(adjacency[node]):
                stack[-1] = (node, index + 1)
                nxt = adjacency[node][index]
                if not visited[nxt]:
                    visited[nxt] = True
                    stack.append((nxt, 0))
            else:
                finish.append(node)
                stack.pop()
    component = [-1] * player_total
    count = 0
    for start in reversed(finish):
        if component[start] != -1:
            continue
        stack = [start]
        component[start] = count
        while stack:
            node = stack.pop()
            for nxt in reverse[node]:
                if component[nxt] == -1:
                    component[nxt] = count
                    stack.append(nxt)
        count += 1
    indegree = [0] * count
    for source in range(player_total):
        for target in adjacency[source]:
            if component[source] != component[target]:
                indegree[component[target]] += 1
    sources = [index for index, value in enumerate(indegree) if value == 0]
    winners = 0
    if len(sources) == 1:
        winners = sum(1 for node in range(player_total) if component[node] == sources[0])
    return "%d\n" % winners


assert oracle([[False, True, True], [False, False, True], [False, False, False]], 3) == "1\n"


def random_test(rng, player_total):
    beats = [[False] * player_total for _ in range(player_total)]
    pairs = [(a, b) for a in range(player_total) for b in range(a + 1, player_total)]
    rng.shuffle(pairs)
    for first, second in pairs[:rng.randint(0, len(pairs))]:
        if rng.random() < 0.5:
            beats[first][second] = True
        else:
            beats[second][first] = True
    lines = ["%d" % player_total]
    for player in range(player_total):
        better = [rival + 1 for rival in range(player_total) if beats[rival][player]]
        lines.append("%d %s" % (len(better), " ".join(map(str, better))) if better else "0")
    expected = oracle(beats, player_total)
    return "\n".join(lines) + "\n", expected


def write(name, tests):
    body = "%d\n" % len(tests) + "".join(test for test, _ in tests)
    open("in/%s.txt" % name, "w").write(body)
    open("out/%s.out" % name, "w").write("".join(expected for _, expected in tests))


open("in/1_sample.txt", "w").write(SAMPLE)
open("out/1_sample.out", "w").write("1\n")

tiny = [("\n".join(["1", "0"]) + "\n", "1\n")]
for seed, size in [(1, 2), (2, 2), (3, 3), (4, 4), (5, 5), (6, 8), (7, 9), (8, 12)]:
    tiny.append(random_test(random.Random(seed), size))
write("2_edges", tiny)

medium = [random_test(random.Random(20 + i), 300) for i in range(6)]
write("3_wide", medium)

many = [random_test(random.Random(50 + i), 1000) for i in range(3)]
write("4_random", many)

io_tests = [random_test(random.Random(70 + i), 1000) for i in range(5)]
write("5_io", io_tests)
