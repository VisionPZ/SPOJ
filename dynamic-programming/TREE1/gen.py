import itertools
import math
import os
import random
from functools import lru_cache

SAMPLE_INPUT = (
    "5 \n"
    "3 \n"
    "2 1 3 \n"
    "3 \n"
    "1 2 3 \n"
    "1 \n"
    "1 \n"
    "4 \n"
    "2 1 3 4 \n"
    "4 \n"
    "1 4 2 3 \n"
)
SAMPLE_EXPECTED = [2, 1, 1, 3, 1]


def insert_key(root, key):
    if root is None:
        return {"key": key, "left": None, "right": None}
    if key < root["key"]:
        root["left"] = insert_key(root["left"], key)
    else:
        root["right"] = insert_key(root["right"], key)
    return root


def preorder(root):
    if root is None:
        return []
    return [root["key"]] + preorder(root["left"]) + preorder(root["right"])


def build_from_prefix(keys):
    position = [0]

    def build(low_key, high_key):
        pivot = keys[position[0]]
        position[0] += 1
        left_count = pivot - low_key
        right_count = high_key - pivot
        node = {"key": pivot, "left": None, "right": None}
        if left_count > 0:
            node["left"] = build(low_key, pivot - 1)
        if right_count > 0:
            node["right"] = build(pivot + 1, high_key)
        return node

    tree = build(1, len(keys))
    assert position[0] == len(keys)
    return tree


def collect_subtree_sizes(root, sizes):
    if root is None:
        return 0
    size = 1 + collect_subtree_sizes(root["left"], sizes) + collect_subtree_sizes(root["right"], sizes)
    sizes.append(size)
    return size


def oracle(keys):
    tree = build_from_prefix(list(keys))
    sizes = []
    total = collect_subtree_sizes(tree, sizes)
    assert total == len(keys)
    product = 1
    for size in sizes:
        product *= size
    factorial = math.factorial(len(keys))
    assert factorial % product == 0
    return factorial // product


def brute_force(keys):
    count = 0
    target = list(keys)
    for permutation in itertools.permutations(range(1, len(target) + 1)):
        root = None
        for key in permutation:
            root = insert_key(root, key)
        if preorder(root) == target:
            count += 1
    return count


@lru_cache(None)
def min_product(size):
    if size == 0:
        return 1
    return size * min(min_product(left) * min_product(size - 1 - left) for left in range(size))


@lru_cache(None)
def best_split(size):
    if size == 0:
        return 0
    options = [(min_product(left) * min_product(size - 1 - left), left) for left in range(size)]
    return min(options)[1]


def make_min_tree(low_key, size):
    if size == 0:
        return None
    left_size = best_split(size)
    right_size = size - 1 - left_size
    pivot = low_key + left_size
    return {
        "key": pivot,
        "left": make_min_tree(low_key, left_size),
        "right": make_min_tree(pivot + 1, right_size),
    }


def min_tree_prefix(size):
    return preorder(make_min_tree(1, size))


def chain_prefix(size):
    return list(range(1, size + 1))


def random_prefix(size, rng):
    values = list(range(1, size + 1))
    rng.shuffle(values)
    root = None
    for key in values:
        root = insert_key(root, key)
    return preorder(root)


def run_asserts():
    assert [oracle(keys) for keys in ([2, 1, 3], [1, 2, 3], [1], [2, 1, 3, 4], [1, 4, 2, 3])] == SAMPLE_EXPECTED
    assert oracle(chain_prefix(30)) == 1
    assert oracle(min_tree_prefix(30)) == 4677301616364748800000
    assert min_product(30) == 56710659600
    for size in range(1, 6):
        seen = set()
        for permutation in itertools.permutations(range(1, size + 1)):
            root = None
            for key in permutation:
                root = insert_key(root, key)
            shape = tuple(preorder(root))
            if shape in seen:
                continue
            seen.add(shape)
            assert oracle(shape) == brute_force(shape), (size, shape)
    assert len(SAMPLE_INPUT.splitlines()) == 11


def write_case(name, datasets):
    expected = [oracle(keys) for keys in datasets]
    input_lines = [str(len(datasets))]
    for keys in datasets:
        input_lines.append(str(len(keys)))
        input_lines.append(" ".join(str(key) for key in keys))
    with open(os.path.join("in", name + ".txt"), "w") as input_file:
        input_file.write("\n".join(input_lines) + "\n")
    with open(os.path.join("out", name + ".out"), "w") as output_file:
        output_file.write("".join(str(value) + "\n" for value in expected))


def main():
    run_asserts()
    with open(os.path.join("in", "1_sample.txt"), "w") as input_file:
        input_file.write(SAMPLE_INPUT)
    with open(os.path.join("out", "1_sample.out"), "w") as output_file:
        output_file.write("".join(str(value) + "\n" for value in SAMPLE_EXPECTED))

    edges = [
        [1],
        [1, 2],
        [2, 1],
        [2, 1, 3],
        [1, 2, 3],
        [1, 4, 2, 3],
        chain_prefix(30),
        list(reversed(chain_prefix(30))),
        min_tree_prefix(29),
        min_tree_prefix(30),
    ]
    write_case("2_edges", edges)

    wide = [min_tree_prefix(30)]
    rng = random.Random(4400)
    for _ in range(9):
        wide.append(random_prefix(30, rng))
    write_case("3_wide", wide)

    random_generator = random.Random(91237)
    random_datasets = []
    for _ in range(10):
        size = random_generator.randint(1, 30)
        random_datasets.append(random_prefix(size, random_generator))
    write_case("4_random", random_datasets)

    io_datasets = [min_tree_prefix(30) for _ in range(10)]
    write_case("5_io", io_datasets)


if __name__ == "__main__":
    main()
