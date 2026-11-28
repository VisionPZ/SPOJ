#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(cases):
    answer_lines = []
    for node_count, edges, commands in cases:
        adjacency = [[] for _ in range(node_count + 1)]
        weight_by_id = [0] * (len(edges) + 1)
        for edge_id, (left_node, right_node, cost) in enumerate(edges, 1):
            adjacency[left_node].append((right_node, edge_id))
            adjacency[right_node].append((left_node, edge_id))
            weight_by_id[edge_id] = cost

        parent = [0] * (node_count + 1)
        parent_edge = [0] * (node_count + 1)
        depth = [0] * (node_count + 1)
        parent[1] = -1
        stack = [1]
        while stack:
            node = stack.pop()
            for neighbor, edge_id in adjacency[node]:
                if neighbor != parent[node]:
                    parent[neighbor] = node
                    parent_edge[neighbor] = edge_id
                    depth[neighbor] = depth[node] + 1
                    stack.append(neighbor)

        for command in commands:
            if command[0] == 'CHANGE':
                _, edge_id, new_cost = command
                weight_by_id[edge_id] = new_cost
                continue
            _, first_node, second_node = command
            best = 0
            left_node, right_node = first_node, second_node
            while depth[left_node] > depth[right_node]:
                best = max(best, weight_by_id[parent_edge[left_node]])
                left_node = parent[left_node]
            while depth[right_node] > depth[left_node]:
                best = max(best, weight_by_id[parent_edge[right_node]])
                right_node = parent[right_node]
            while left_node != right_node:
                best = max(best, weight_by_id[parent_edge[left_node]])
                left_node = parent[left_node]
                best = max(best, weight_by_id[parent_edge[right_node]])
                right_node = parent[right_node]
            answer_lines.append(str(best))
    return ''.join(line + '\n' for line in answer_lines)


def brute_query(case, command, weight_by_id):
    node_count, edges, _ = case
    adjacency = [[] for _ in range(node_count + 1)]
    for edge_id, (left_node, right_node, _) in enumerate(edges, 1):
        adjacency[left_node].append((right_node, edge_id))
        adjacency[right_node].append((left_node, edge_id))
    _, first_node, second_node = command
    queue = deque([first_node])
    came_from = {first_node: (0, 0)}
    while queue:
        node = queue.popleft()
        if node == second_node:
            break
        for neighbor, edge_id in adjacency[node]:
            if neighbor not in came_from:
                came_from[neighbor] = (node, edge_id)
                queue.append(neighbor)
    best = 0
    node = second_node
    while node != first_node:
        previous_node, edge_id = came_from[node]
        best = max(best, weight_by_id[edge_id])
        node = previous_node
    return best


def brute_oracle(cases):
    answer_lines = []
    for case in cases:
        _, edges, commands = case
        weight_by_id = [0] * (len(edges) + 1)
        for edge_id, (_, _, cost) in enumerate(edges, 1):
            weight_by_id[edge_id] = cost
        for command in commands:
            if command[0] == 'CHANGE':
                weight_by_id[command[1]] = command[2]
            else:
                answer_lines.append(str(brute_query(case, command, weight_by_id)))
    return ''.join(line + '\n' for line in answer_lines)


def render_input(cases):
    chunks = [str(len(cases)) + '\n']
    for node_count, edges, commands in cases:
        chunks.append('\n')
        chunks.append(str(node_count) + '\n')
        chunks.extend(f'{left} {right} {cost}\n' for left, right, cost in edges)
        chunks.extend(' '.join(str(part) for part in command) + '\n' for command in commands)
        chunks.append('DONE\n')
    return ''.join(chunks)


def write(name, cases):
    input_text = render_input(cases)
    (ROOT / 'in' / f'{name}.txt').write_text(input_text)
    (ROOT / 'out' / f'{name}.out').write_text(oracle(cases))


def random_tree(node_count, rng, shape):
    edges = []
    for node in range(2, node_count + 1):
        if shape == 'chain':
            parent = node - 1
        elif shape == 'star':
            parent = 1
        elif shape == 'balanced':
            parent = node // 2
        else:
            parent = rng.randint(1, node - 1)
        edges.append((parent, node, rng.randint(1, 1000000)))
    return edges


def random_commands(rng, node_count, edge_count, command_count, change_ratio=0.3):
    commands = []
    for _ in range(command_count):
        if edge_count and rng.random() < change_ratio:
            commands.append(('CHANGE', rng.randint(1, edge_count), rng.randint(1, 1000000)))
        else:
            commands.append(('QUERY', rng.randint(1, node_count), rng.randint(1, node_count)))
    return commands


SAMPLE_CASES = [
    (3, [(1, 2, 1), (2, 3, 2)],
     [('QUERY', 1, 2), ('CHANGE', 1, 3), ('QUERY', 1, 2)]),
]

assert oracle(SAMPLE_CASES) == '1\n3\n'
assert render_input(SAMPLE_CASES) == '1\n\n3\n1 2 1\n2 3 2\nQUERY 1 2\nCHANGE 1 3\nQUERY 1 2\nDONE\n'

CHAIN_CASE = (3, [(1, 2, 5), (2, 3, 7)],
              [('QUERY', 1, 3), ('QUERY', 2, 2), ('CHANGE', 1, 9), ('QUERY', 1, 3)])
assert oracle([CHAIN_CASE]) == '7\n0\n9\n'
assert brute_oracle([CHAIN_CASE]) == oracle([CHAIN_CASE])

TINY_CASE = (6, [(1, 2, 3), (1, 3, 8), (2, 4, 4), (2, 5, 1), (3, 6, 6)],
             [('QUERY', 4, 6), ('QUERY', 5, 4), ('CHANGE', 3, 10), ('QUERY', 4, 6), ('QUERY', 6, 6)])
assert oracle([TINY_CASE]) == brute_oracle([TINY_CASE])

(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)

write('1_sample', SAMPLE_CASES)

rng = random.Random(20261125)
edge_cases = [
    (1, [], [('QUERY', 1, 1)]),
    (2, [(1, 2, 1)], [('QUERY', 1, 2), ('CHANGE', 1, 5), ('QUERY', 2, 1)]),
    (2, [(1, 2, 0)], [('QUERY', 1, 2), ('QUERY', 2, 2)]),
    (3, [(1, 2, 4), (1, 3, 4)], [('QUERY', 2, 3), ('QUERY', 2, 2)]),
    (5, [(1, 2, 2), (2, 3, 3), (3, 4, 4), (4, 5, 5)],
     [('QUERY', 1, 5), ('CHANGE', 2, 1), ('QUERY', 1, 5), ('QUERY', 5, 1)]),
]
for shape in ('star', 'chain', 'balanced', 'random'):
    node_count = rng.randint(6, 40)
    edges = random_tree(node_count, rng, shape)
    edge_cases.append((node_count, edges, random_commands(rng, node_count, len(edges), 60)))
write('2_edges', edge_cases)

wide_cases = []
chain_nodes = 10000
chain_edges = random_tree(chain_nodes, rng, 'chain')
wide_cases.append((chain_nodes, chain_edges, random_commands(rng, chain_nodes, chain_nodes - 1, 200)))
balanced_nodes = 10000
balanced_edges = random_tree(balanced_nodes, rng, 'balanced')
wide_cases.append((balanced_nodes, balanced_edges, random_commands(rng, balanced_nodes, balanced_nodes - 1, 400)))
star_nodes = 10000
star_edges = random_tree(star_nodes, rng, 'star')
wide_cases.append((star_nodes, star_edges, random_commands(rng, star_nodes, star_nodes - 1, 400)))
write('3_wide', wide_cases)

random_cases = []
for _ in range(20):
    node_count = rng.randint(2, 3000)
    shape = rng.choice(['chain', 'star', 'balanced', 'random'])
    edges = random_tree(node_count, rng, shape)
    commands = random_commands(rng, node_count, len(edges), 200)
    random_cases.append((node_count, edges, commands))
write('4_random', random_cases)

io_nodes = 10000
io_edges = random_tree(io_nodes, rng, 'star')
io_commands = [('QUERY', rng.randint(1, io_nodes), rng.randint(1, io_nodes)) for _ in range(100000)]
write('5_io', [(io_nodes, io_edges, io_commands)])

print('generated five cases, largest output', len(oracle([(io_nodes, io_edges, io_commands)])))
