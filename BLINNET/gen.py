import os
import random

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

SAMPLE = """2
4
gdansk
2
2 1
3 3
bydgoszcz
3
1 1
3 1
4 4
torun
3
1 3
2 1
4 1
warszawa
2
2 4
3 1
3
ixowo
2
2 1
3 3
iyekowo
2
1 1
3 7
zetowo
2
1 3
2 7
"""


def prim(neighbour_lists, city_count):
    """Grow the tree one city at a time from city 0 (a different route than Kruskal)."""
    connected = [False] * city_count
    cheapest = [10 ** 18] * city_count
    cheapest[0] = 0
    total = 0
    for _ in range(city_count):
        best_city, best_cost = -1, 10 ** 18
        for city in range(city_count):
            if not connected[city] and cheapest[city] < best_cost:
                best_city, best_cost = city, cheapest[city]
        connected[best_city] = True
        total += best_cost
        for neighbour, cost in neighbour_lists[best_city]:
            if not connected[neighbour] and cost < cheapest[neighbour]:
                cheapest[neighbour] = cost
    return total


def build(rng, city_count, extra_edges, max_cost):
    names = ["".join(rng.choice("abcdefghijklmnopqrstuvwxyz") for _ in range(rng.randint(2, 10)))
             for _ in range(city_count)]
    if len(set(names)) < city_count:
        names = ["c%d" % i for i in range(city_count)]
    edges = []
    for index in range(1, city_count):
        edges.append((index, rng.randrange(0, index), rng.randint(1, max_cost)))
    for _ in range(extra_edges):
        first, second = rng.randrange(0, city_count), rng.randrange(0, city_count)
        if first != second:
            edges.append((first, second, rng.randint(1, max_cost)))
    neighbour_lists = [[] for _ in range(city_count)]
    for first, second, cost in edges:
        neighbour_lists[first].append((second, cost))
        neighbour_lists[second].append((first, cost))
    lines = ["%d" % city_count]
    for index in range(city_count):
        lines.append(names[index])
        lines.append("%d" % len(neighbour_lists[index]))
        for second, cost in neighbour_lists[index]:
            lines.append("%d %d" % (second + 1, cost))
    return "\n".join(lines) + "\n\n", "%d\n" % prim(neighbour_lists, city_count)


def write(name, tests):
    body = "%d\n" % len(tests) + "".join(test for test, _ in tests)
    open("in/%s.txt" % name, "w").write(body)
    open("out/%s.out" % name, "w").write("".join(expected for _, expected in tests))


open("in/1_sample.txt", "w").write(SAMPLE)
open("out/1_sample.out", "w").write("3\n4\n")

assert prim([[(1, 1), (2, 3)], [(0, 1), (2, 1), (3, 4)], [(0, 3), (1, 1), (3, 1)],
             [(1, 4), (2, 1)]], 4) == 3

tiny = []
tiny.append(("2\na\n1\n2 5\nb\n1\n1 5\n\n", "5\n"))
for seed, size, extra in [(1, 3, 0), (2, 4, 1), (3, 5, 3), (4, 8, 8), (5, 12, 20)]:
    rng = random.Random(seed)
    tiny.append(build(rng, size, extra, 1000))
write("2_edges", tiny)

medium = [build(random.Random(20 + i), 2000, 6000, 10 ** 9) for i in range(6)]
write("3_wide", medium)

big = [build(random.Random(50 + i), 10000, 30000, 10 ** 9) for i in range(4)]
write("4_random", big)

io_tests = [build(random.Random(90 + i), 10000, 90000, 10 ** 9 // 10) for i in range(6)]
write("5_io", io_tests)
