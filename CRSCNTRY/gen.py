import os
import random

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)


def lcs_naive(left, right):
    width = len(right)
    previous = [0] * (width + 1)
    for value in left:
        current = [0] * (width + 1)
        for position in range(width):
            if value == right[position]:
                current[position + 1] = previous[position] + 1
            else:
                take_above = previous[position + 1]
                take_left = current[position]
                current[position + 1] = take_above if take_above >= take_left else take_left
        previous = current
    return previous[width]


def solve_dataset(agnes, tom_routes):
    answer = 0
    for tom in tom_routes:
        score = lcs_naive(agnes, tom)
        if score > answer:
            answer = score
    return answer


assert lcs_naive([1, 2, 3, 4, 5, 6, 7, 8, 9], [1, 3, 1, 3, 5, 7, 8, 9, 3, 4]) == 6
assert lcs_naive([1, 3, 5, 7], [3, 7, 5, 1]) == 2
assert lcs_naive([1, 2, 1, 1], [1, 1, 1]) == 3
assert lcs_naive([1, 2, 3], [4, 5, 6]) == 0


SAMPLE_INPUT = """3
1 2 3 4 5 6 7 8 9 0
1 3 8 2 0
2 5 7 8 9 0
1 1 1 1 1 1 2 3 0
1 3 1 3 5 7 8 9 3 4 0
1 2 35 0
0
1 3 5 7 0
3 7 5 1 0
0
1 2 1 1 0
1 1 1 0
0
"""

SAMPLE_OUTPUT = "6\n2\n3\n"


def parse_input(text):
    tokens = list(map(int, text.split()))
    position = 0
    count = tokens[position]
    position += 1
    datasets = []
    for _ in range(count):
        agnes = []
        while tokens[position] != 0:
            agnes.append(tokens[position])
            position += 1
        position += 1
        routes = []
        while tokens[position] != 0:
            route = []
            while tokens[position] != 0:
                route.append(tokens[position])
                position += 1
            position += 1
            routes.append(route)
        position += 1
        datasets.append((agnes, routes))
    return datasets


def route_line(route):
    return " ".join(str(value) for value in route) + " 0\n"


def write_case(name, datasets):
    body = [str(len(datasets)) + "\n"]
    answers = []
    for agnes, tom_routes in datasets:
        body.append(route_line(agnes))
        for tom in tom_routes:
            body.append(route_line(tom))
        body.append("0\n")
        answers.append(str(solve_dataset(agnes, tom_routes)) + "\n")
    with open("in/" + name + ".txt", "w") as handle:
        handle.write("".join(body))
    with open("out/" + name + ".out", "w") as handle:
        handle.write("".join(answers))


with open("in/1_sample.txt", "w") as handle:
    handle.write(SAMPLE_INPUT)
with open("out/1_sample.out", "w") as handle:
    handle.write(SAMPLE_OUTPUT)
assert [solve_dataset(agnes, routes) for agnes, routes in parse_input(SAMPLE_INPUT)] == [6, 2, 3]

edge_datasets = [
    ([1, 2], [[2, 1]]),
    ([7, 7], [[7, 7]]),
    ([1, 2], [[3, 4]]),
    ([1, 1, 1, 1], [[1, 1]]),
    ([998, 999, 1000], [[1000, 999, 998]]),
    ([1000, 1000], [[1000]]),
    ([5, 3], [[5], [3], [3, 5]]),
    ([1, 2, 3], [[3, 2, 1], [1, 2], [2, 3], [1, 3]]),
    ([2, 2], [[2, 2, 2], [2, 2]]),
    ([1, 1000], [[1000, 1], [1, 1000], [500, 500]]),
]
write_case("2_edges", edge_datasets)

increasing = list(range(1, 1001)) + list(range(1, 1001))
decreasing = list(reversed(increasing))
wide_datasets = [
    (increasing, [decreasing]),
    ([1] * 2000, [[1] * 2000]),
    ([1] * 2000, [[2] * 2000]),
    (increasing, [increasing, decreasing, [1000] * 2000]),
]
write_case("3_wide", wide_datasets)

rng = random.Random(20261123)
random_datasets = []
for dataset_index in range(10):
    agnes_length = rng.randint(2, 250)
    agnes = [rng.randint(1, 1000) for _ in range(agnes_length)]
    routes = []
    for route_index in range(rng.randint(1, 6)):
        route_length = rng.randint(2, 250)
        routes.append([rng.randint(1, 1000) for _ in range(route_length)])
    random_datasets.append((agnes, routes))
write_case("4_random", random_datasets)

io_datasets = []
for dataset_index in range(10):
    agnes = list(range(1, 1001)) + list(range(1, 1001))
    routes = [
        list(range(1000, 0, -1)) + list(range(1000, 0, -1)),
        list(range(1, 1001)) + list(range(1000, 0, -1)),
    ]
    io_datasets.append((agnes, routes))
write_case("5_io", io_datasets)

print("generated 5 test pairs with", len(random_datasets), "random datasets")
