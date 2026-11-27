import os
import random


def value_at(components, position):
    return sum(component[position % len(component)] for component in components)


def render(components, size, queries):
    lines = [str(size)]
    lines.append(" ".join(str(value_at(components, position)) for position in range(size * size)))
    lines.append(" ".join(str(position) for position in queries))
    return "\n".join(lines) + "\n"


def oracle(components, queries):
    return " ".join(str(value_at(components, position)) for position in queries) + "\n"


def emit(name, size, components, queries):
    os.makedirs("in", exist_ok=True)
    os.makedirs("out", exist_ok=True)
    with open(os.path.join("in", name + ".txt"), "w", encoding="utf-8") as stream:
        stream.write(render(components, size, queries))
    with open(os.path.join("out", name + ".out"), "w", encoding="utf-8") as stream:
        stream.write(oracle(components, queries))


SAMPLE_SIZE = 3
SAMPLE_COMPONENTS = [[10], [5, -8], [0, 1, 2]]
SAMPLE_QUERIES = [10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000]
assert render(SAMPLE_COMPONENTS, SAMPLE_SIZE, SAMPLE_QUERIES) == """3
15 3 17 2 16 4 15 3 17
10 100 1000 10000 100000 1000000 10000000 100000000 1000000000
"""
assert oracle(SAMPLE_COMPONENTS, SAMPLE_QUERIES) == "16 16 16 16 16 16 16 16 16\n"


def random_components(rng, size, count, magnitude):
    components = []
    for _ in range(count):
        period = rng.randint(1, size)
        components.append([rng.randint(-magnitude, magnitude) for _ in range(period)])
    return components


def main():
    os.makedirs("in", exist_ok=True)
    os.makedirs("out", exist_ok=True)

    emit("1_sample", SAMPLE_SIZE, SAMPLE_COMPONENTS, SAMPLE_QUERIES)

    queries_small = [0, 1, 2, 999999999]
    emit("2_edges", 2, [[7], [3, -5]], queries_small)

    rng = random.Random(20261128)
    wide_components = random_components(rng, 257, 24, 10**9)
    wide_queries = [rng.randint(0, 10**9 - 1) for _ in range(257 * 257)]
    wide_queries[:9] = SAMPLE_QUERIES
    emit("3_wide", 257, wide_components, wide_queries)

    for case_index in range(1, 9):
        size = rng.randint(3, 14)
        components = random_components(rng, size, rng.randint(1, size), 1000)
        queries = [rng.randint(0, 10**9 - 1) for _ in range(size * size)]
        queries[:4] = [0, size, size * size, 10**9 - 1]
        emit(f"4_random_{case_index}", size, components, queries)

    io_components = random_components(rng, 257, 40, 10**9)
    io_queries = [rng.randint(10**8, 10**9 - 1) for _ in range(257 * 257)]
    emit("5_io", 257, io_components, io_queries)


if __name__ == "__main__":
    main()
