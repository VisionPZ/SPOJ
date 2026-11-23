import itertools
import random

PHI = (1 + 5 ** 0.5) / 2

ICOSA_VERTICES = []
for firstSign in (1, -1):
    for secondSign in (1, -1):
        ICOSA_VERTICES.append((0, firstSign, secondSign * PHI))
        ICOSA_VERTICES.append((firstSign, secondSign * PHI, 0))
        ICOSA_VERTICES.append((firstSign * PHI, 0, secondSign))


def squared_distance(left, right):
    return sum((left[axis] - right[axis]) ** 2 for axis in range(3))


def vector_subtract(left, right):
    return tuple(left[axis] - right[axis] for axis in range(3))


def vector_cross(left, right):
    return (left[1] * right[2] - left[2] * right[1],
            left[2] * right[0] - left[0] * right[2],
            left[0] * right[1] - left[1] * right[0])


def vector_dot(left, right):
    return sum(left[axis] * right[axis] for axis in range(3))


ICOSA_EDGES = [(left, right)
               for left in range(12)
               for right in range(left + 1, 12)
               if abs(squared_distance(ICOSA_VERTICES[left],
                                       ICOSA_VERTICES[right]) - 4) < 1e-7]
ICOSA_NEIGHBORS = [set() for _ in range(12)]
for edgeLeft, edgeRight in ICOSA_EDGES:
    ICOSA_NEIGHBORS[edgeLeft].add(edgeRight)
    ICOSA_NEIGHBORS[edgeRight].add(edgeLeft)

ICOSA_FACES = []
for faceLeft, faceMiddle, faceRight in itertools.combinations(range(12), 3):
    if (faceMiddle in ICOSA_NEIGHBORS[faceLeft] and
            faceRight in ICOSA_NEIGHBORS[faceLeft] and
            faceRight in ICOSA_NEIGHBORS[faceMiddle]):
        normal = vector_cross(vector_subtract(ICOSA_VERTICES[faceMiddle],
                                              ICOSA_VERTICES[faceLeft]),
                              vector_subtract(ICOSA_VERTICES[faceRight],
                                              ICOSA_VERTICES[faceLeft]))
        centroid = tuple(ICOSA_VERTICES[faceLeft][axis] +
                         ICOSA_VERTICES[faceMiddle][axis] +
                         ICOSA_VERTICES[faceRight][axis]
                         for axis in range(3))
        if vector_dot(normal, centroid) < 0:
            faceMiddle, faceRight = faceRight, faceMiddle
        ICOSA_FACES.append((faceLeft, faceMiddle, faceRight))

assert len(ICOSA_VERTICES) == 12
assert len(ICOSA_EDGES) == 30
assert len(ICOSA_FACES) == 20

NEIGHBOR_CYCLES = []
for center in range(12):
    around = list(ICOSA_NEIGHBORS[center])
    successor = {neighbor: set() for neighbor in around}
    for faceLeft, faceMiddle, faceRight in ICOSA_FACES:
        for first, second, third in ((faceLeft, faceMiddle, faceRight),
                                     (faceMiddle, faceRight, faceLeft),
                                     (faceRight, faceLeft, faceMiddle)):
            if first == center:
                successor[second].add(third)
                successor[third].add(second)
    start = around[0]
    order = [start]
    previous = None
    current = start
    while True:
        choices = [item for item in successor[current] if item != previous]
        if not choices:
            break
        following = choices[0]
        if following == start:
            break
        order.append(following)
        previous, current = current, following
    NEIGHBOR_CYCLES.append(order)

TRUNC_FACES = []
for center in range(12):
    TRUNC_FACES.append(([(center, neighbor) for neighbor in NEIGHBOR_CYCLES[center]], 'P'))
for faceLeft, faceMiddle, faceRight in ICOSA_FACES:
    TRUNC_FACES.append(([(faceLeft, faceMiddle), (faceMiddle, faceLeft),
                         (faceMiddle, faceRight), (faceRight, faceMiddle),
                         (faceRight, faceLeft), (faceLeft, faceRight)], 'H'))

TRUNC_NEIGHBORS = {}
EDGE_FACES = {}
for faceIndex, (faceVertices, faceKind) in enumerate(TRUNC_FACES):
    for vertexIndex in range(len(faceVertices)):
        firstVertex = faceVertices[vertexIndex]
        secondVertex = faceVertices[(vertexIndex + 1) % len(faceVertices)]
        TRUNC_NEIGHBORS.setdefault(firstVertex, set()).add(secondVertex)
        TRUNC_NEIGHBORS.setdefault(secondVertex, set()).add(firstVertex)
        edgeKey = frozenset((firstVertex, secondVertex))
        EDGE_FACES.setdefault(edgeKey, []).append(faceIndex)

INCIDENT_FACES = {vertex: set() for vertex in TRUNC_NEIGHBORS}
for faceIndex, (faceVertices, faceKind) in enumerate(TRUNC_FACES):
    for vertex in faceVertices:
        INCIDENT_FACES[vertex].add(faceIndex)

HH_EDGES = [edgeKey for edgeKey, faces in EDGE_FACES.items()
            if all(TRUNC_FACES[faceIndex][1] == 'H' for faceIndex in faces)]

assert len(TRUNC_NEIGHBORS) == 60
assert len(TRUNC_FACES) == 32
assert len(EDGE_FACES) == 90
assert sum(1 for _, kind in TRUNC_FACES if kind == 'P') == 12
assert sum(1 for _, kind in TRUNC_FACES if kind == 'H') == 20
assert len(HH_EDGES) == 30


def find_cycle(randomizer, minLength, maxLength):
    for attempt in range(120):
        closingEnds = tuple(randomizer.choice(HH_EDGES))
        firstEnd, lastEnd = closingEnds
        budget = [0]
        found = [None]

        def search(current, path, visited):
            budget[0] += 1
            if budget[0] > 60000:
                return False
            if lastEnd in TRUNC_NEIGHBORS[current] and len(path) >= minLength:
                found[0] = path + [lastEnd]
                return True
            if len(path) >= maxLength:
                return False
            options = [candidate for candidate in TRUNC_NEIGHBORS[current]
                       if candidate not in visited and candidate != lastEnd]
            randomizer.shuffle(options)
            for candidate in options:
                visited.add(candidate)
                if search(candidate, path + [candidate], visited):
                    return True
                visited.remove(candidate)
            return False

        search(firstEnd, [firstEnd], {firstEnd})
        if found[0] is not None:
            return found[0]
    return None


def geometric_oracle(cycle, greenSide):
    cycleLength = len(cycle)
    cycleEdges = [frozenset((cycle[index], cycle[(index + 1) % cycleLength]))
                  for index in range(cycleLength)]
    dualNeighbors = [set() for _ in range(32)]
    for edgeKey, faces in EDGE_FACES.items():
        if edgeKey in cycleEdges:
            continue
        firstFace, secondFace = faces
        dualNeighbors[firstFace].add(secondFace)
        dualNeighbors[secondFace].add(firstFace)
    seen = set()
    components = []
    for seed in range(32):
        if seed in seen:
            continue
        stack = [seed]
        component = {seed}
        seen.add(seed)
        while stack:
            current = stack.pop()
            for neighbor in dualNeighbors[current]:
                if neighbor not in seen:
                    seen.add(neighbor)
                    component.add(neighbor)
                    stack.append(neighbor)
        components.append(component)
    assert len(components) == 2
    components.sort(key=lambda component: min(component))
    greenFaces = components[greenSide % 2]
    vertexValues = [sum(1 for face in INCIDENT_FACES[vertex] if face in greenFaces)
                    for vertex in cycle]
    assert all(value in (1, 2) for value in vertexValues)
    greenPentagons = sum(1 for face in greenFaces if TRUNC_FACES[face][1] == 'P')
    greenHexagons = sum(1 for face in greenFaces if TRUNC_FACES[face][1] == 'H')
    expected = (12 - greenPentagons, 20 - greenHexagons,
                greenPentagons + greenHexagons)
    return vertexValues, expected


def formula_check(vertexValues, expected):
    vertexCount = len(vertexValues)
    greenPieceSum = sum(vertexValues)
    state = 2
    pentagonVertices = 0
    for value in vertexValues:
        if state == 0:
            state = 0 if value == 1 else 2
            pentagonVertices += 1
        elif state == 1:
            state = 2 if value == 1 else 1
        else:
            if value == 1:
                state = 1
            else:
                state = 0
                pentagonVertices += 1
    assert state == 2
    greenPentagons = 2 * greenPieceSum - 3 * vertexCount + 6
    numerator = 10 * greenPentagons + greenPieceSum - 3 * pentagonVertices
    assert numerator % 6 == 0
    greenHexagons = numerator // 6
    assert (12 - greenPentagons, 20 - greenHexagons,
            greenPentagons + greenHexagons) == expected


SAMPLE_VALUES = [1, 2, 1, 2, 1, 2, 1, 1, 1, 2, 2, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1]
formula_check(SAMPLE_VALUES, (11, 15, 6))

randomizer = random.Random(20032003)

cyclePool = []
for targetLength in (4, 5, 6, 7, 8, 10, 12, 16, 20, 28, 36, 44, 50, 54, 56):
    for _ in range(8):
        candidate = find_cycle(randomizer, targetLength, targetLength + 3)
        if candidate is not None:
            cyclePool.append(candidate)
for _ in range(240):
    lower = randomizer.randint(4, 24)
    candidate = find_cycle(randomizer, lower, 60)
    if candidate is not None:
        cyclePool.append(candidate)
assert len(cyclePool) >= 300


def build_group(groupName, caseCount, minLength=None, maxLength=None):
    inputLines = []
    outputLines = []
    for _ in range(caseCount):
        if minLength is None and maxLength is None:
            cycle = randomizer.choice(cyclePool)
        else:
            choices = [item for item in cyclePool
                       if (minLength is None or len(item) >= minLength)
                       and (maxLength is None or len(item) <= maxLength)]
            cycle = randomizer.choice(choices)
        values, expected = geometric_oracle(cycle, randomizer.randint(0, 1))
        formula_check(values, expected)
        inputLines.append(str(len(values)))
        inputLines.append(' '.join(str(value) for value in values))
        outputLines.append('%d %d %d ' % expected)
    with open('in/%s.txt' % groupName, 'w') as inputFile:
        inputFile.write('%d\n' % caseCount)
        inputFile.write('\n'.join(inputLines))
        inputFile.write('\n')
    with open('out/%s.out' % groupName, 'w') as outputFile:
        outputFile.write('\n'.join(outputLines))
        outputFile.write('\n')


with open('in/1_sample.txt', 'w') as sampleInput:
    sampleInput.write('1\n21 \n')
    sampleInput.write(' '.join(str(value) for value in SAMPLE_VALUES))
    sampleInput.write(' \n')
with open('out/1_sample.out', 'w') as sampleOutput:
    sampleOutput.write('11 15 6 \n')

build_group('2_edges', 16, maxLength=10)
build_group('3_wide', 16, minLength=44)
build_group('4_random', 400)
build_group('5_io', 4000)
