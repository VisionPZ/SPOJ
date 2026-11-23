import heapq
import os
import random

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

SAMPLE = """1
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
2
gdansk warszawa
bydgoszcz warszawa
"""


def oracle_test(neighbour_lists, names, queries):
    """Dijkstra with a binary heap, run from every distinct source."""
    city_count = len(names)
    cache = {}
    answers = []
    for source_name, target_name in queries:
        source = names.index(source_name)
        target = names.index(target_name)
        if source not in cache:
            distance = [10 ** 18] * city_count
            distance[source] = 0
            queue = [(0, source)]
            settled = set()
            while queue:
                current_distance, current = heapq.heappop(queue)
                if current in settled:
                    continue
                settled.add(current)
                for neighbour, cost in neighbour_lists[current]:
                    candidate = current_distance + cost
                    if candidate < distance[neighbour]:
                        distance[neighbour] = candidate
                        heapq.heappush(queue, (candidate, neighbour))
            cache[source] = distance
        answers.append(str(cache[source][target]))
    return "\n".join(answers) + "\n"


def build(rng, city_count, extra_edges, query_count, max_cost=1000):
    names = ["c%d" % i for i in range(city_count)]
    edges = []
    for index in range(1, city_count):
        partner = rng.randrange(0, index)
        edges.append((index, partner, rng.randint(1, max_cost)))
    for _ in range(extra_edges):
        first = rng.randrange(0, city_count)
        second = rng.randrange(0, city_count)
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
    queries = []
    used_sources = set()
    for _ in range(query_count):
        first = rng.randrange(0, city_count)
        if len(used_sources) < min(query_count, city_count) and first in used_sources:
            continue
        used_sources.add(first)
        second = rng.randrange(0, city_count)
        queries.append((names[first], names[second]))
    lines.append("%d" % len(queries))
    for first, second in queries:
        lines.append("%s %s" % (first, second))
    text = "\n".join(lines) + "\n\n"
    expected = oracle_test(neighbour_lists, names, queries)
    return text, expected


def write(name, tests):
    body = "%d\n" % len(tests) + "".join(test for test, _ in tests)
    open("in/%s.txt" % name, "w").write(body)
    open("out/%s.out" % name, "w").write("".join(expected for _, expected in tests))


open("in/1_sample.txt", "w").write(SAMPLE)
open("out/1_sample.out", "w").write("3\n2\n")

tiny = []
tiny.append(build(random.Random(1), 2, 1, 2))
tiny.append(build(random.Random(2), 3, 0, 3))
tiny.append(build(random.Random(3), 5, 3, 4))
tiny.append(build(random.Random(4), 10, 1, 10))
tiny.append(build(random.Random(5), 6000, 0, 5, 5))
write("2_edges", tiny)

wide = [build(random.Random(10 + i), 10000, 30000, 100) for i in range(2)]
write("3_wide", wide)

random_graphs = [build(random.Random(30 + i), 4000, 12000, 100) for i in range(3)]
write("4_random", random_graphs)

big = [build(random.Random(70 + i), 10000, 30000, 20) for i in range(10)]
write("5_io", big)
