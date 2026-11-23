import math
import random
import functools


def cross(origin, first, second):
    return (first[0] - origin[0]) * (second[1] - origin[1]) - (first[1] - origin[1]) * (second[0] - origin[0])


def squaredDistance(first, second):
    return (first[0] - second[0]) ** 2 + (first[1] - second[1]) ** 2


def oracle(points):
    seen = set()
    unique = []
    for position, (pointX, pointY) in enumerate(points, 1):
        if (pointX, pointY) in seen:
            continue
        seen.add((pointX, pointY))
        unique.append((pointX, pointY, position))

    if not unique:
        return 0.0, []

    pivot = unique[0]
    for candidate in unique[1:]:
        if candidate[1] < pivot[1] or (candidate[1] == pivot[1] and candidate[0] < pivot[0]):
            pivot = candidate

    if len(unique) == 1:
        return 0.0, [pivot[2]]

    def angleCompare(first, second):
        turn = cross(pivot, first, second)
        if turn > 0:
            return -1
        if turn < 0:
            return 1
        firstDistance = squaredDistance(pivot, first)
        secondDistance = squaredDistance(pivot, second)
        if firstDistance < secondDistance:
            return -1
        if firstDistance > secondDistance:
            return 1
        return 0

    others = [candidate for candidate in unique if candidate is not pivot]
    others.sort(key=functools.cmp_to_key(angleCompare))

    stack = [pivot]
    for candidate in others:
        while len(stack) >= 2 and cross(stack[-2], stack[-1], candidate) <= 0:
            stack.pop()
        stack.append(candidate)

    perimeter = 0.0
    for position, corner in enumerate(stack):
        following = stack[(position + 1) % len(stack)]
        perimeter += math.hypot(corner[0] - following[0], corner[1] - following[1])
    return perimeter, [corner[2] for corner in stack]


def formatCase(perimeter, hull):
    return "%.2f\n%s\n\n" % (perimeter, " ".join(str(index) for index in hull))


SAMPLE_INPUT = """8

5
0 0
0 5
10 5
3 3
10 0

1
0 0

3
0 0
1 0
2 0

4
0 0
0 0
0 1
1 0

3
0 0
0 1
1 0

6
0 0
-1 -1
1 1
2 2
3 3
4 4

2
10 0
0 0

7
-3 -4
2 -3
4 3
-4 2
0 5
2 -3
-1 4

"""

SAMPLE_OUTPUT = """30.00
1 5 3 2

0.00
1

4.00
1 3

3.41
1 4 3

3.41
1 3 2

14.14
2 6

20.00
2 1

26.98
1 2 3 5 4

"""

assert formatCase(*oracle([(0, 0), (10, 0)])) == "20.00\n1 2\n\n"
assert formatCase(*oracle([(0, 0), (1, 0), (2, 0)])) == "4.00\n1 3\n\n"
assert formatCase(*oracle([(5, 5)])) == "0.00\n1\n\n"
assert formatCase(*oracle([(0, 0), (0, 0), (0, 1), (1, 0)])) == "3.41\n1 4 3\n\n"


def sampleCases():
    groups = [
        [(0, 0), (0, 5), (10, 5), (3, 3), (10, 0)],
        [(0, 0)],
        [(0, 0), (1, 0), (2, 0)],
        [(0, 0), (0, 0), (0, 1), (1, 0)],
        [(0, 0), (0, 1), (1, 0)],
        [(0, 0), (-1, -1), (1, 1), (2, 2), (3, 3), (4, 4)],
        [(10, 0), (0, 0)],
        [(-3, -4), (2, -3), (4, 3), (-4, 2), (0, 5), (2, -3), (-1, 4)],
    ]
    return groups


def edgeCases():
    return [
        [(0, 0)],
        [(5, 5), (5, 5)],
        [(10, 0), (0, 0)],
        [(0, 0), (1, 0), (2, 0)],
        [(-4, -4), (-3, -3), (-2, -2), (-1, -1), (0, 0)],
        [(0, 0), (0, 0), (0, 1), (1, 0)],
        [(-3, -7)],
        [(7, 2), (7, 2), (7, 2), (8, 2), (7, 3), (8, 3), (7, 2)],
        [(-10000, -10000), (10000, -10000), (10000, 10000), (-10000, 10000)],
        [(0, 0), (1, 0), (2, 0), (1, 0), (3, 0), (0, 0)],
    ]


def circleCase(count, radius, rng):
    points = []
    phase = rng.random() * 6.283185307179586
    for position in range(count):
        angle = phase + 6.283185307179586 * position / count
        pointX = int(round(radius * math.cos(angle)))
        pointY = int(round(radius * math.sin(angle)))
        points.append((pointX, pointY))
    return points


def writeCase(handle, points):
    handle.write("%d\n" % len(points))
    for pointX, pointY in points:
        handle.write("%d %d\n" % (pointX, pointY))
    handle.write("\n")


def generate():
    sampleGroups = sampleCases()
    sampled = [formatCase(*oracle(group)) for group in sampleGroups]
    assert "".join(sampled) == SAMPLE_OUTPUT

    with open("in/1_sample.txt", "w") as inputHandle:
        inputHandle.write(SAMPLE_INPUT)
    with open("out/1_sample.out", "w") as outputHandle:
        outputHandle.write(SAMPLE_OUTPUT)

    edges = edgeCases()
    with open("in/2_edges.txt", "w") as inputHandle, open("out/2_edges.out", "w") as outputHandle:
        inputHandle.write("%d\n\n" % len(edges))
        for group in edges:
            writeCase(inputHandle, group)
            outputHandle.write(formatCase(*oracle(group)))

    rng = random.Random(20201123)
    wide = [circleCase(100000, 10000, rng),
            [(rng.randint(-3, 3), rng.randint(-3, 3)) for _ in range(100000)]]
    with open("in/3_wide.txt", "w") as inputHandle, open("out/3_wide.out", "w") as outputHandle:
        inputHandle.write("%d\n\n" % len(wide))
        for group in wide:
            writeCase(inputHandle, group)
            outputHandle.write(formatCase(*oracle(group)))

    randomRng = random.Random(777001)
    randomized = []
    for _ in range(20):
        count = randomRng.randint(1, 50000)
        randomized.append([(randomRng.randint(-10000, 10000), randomRng.randint(-10000, 10000))
                           for _ in range(count)])
    with open("in/4_random.txt", "w") as inputHandle, open("out/4_random.out", "w") as outputHandle:
        inputHandle.write("%d\n\n" % len(randomized))
        for group in randomized:
            writeCase(inputHandle, group)
            outputHandle.write(formatCase(*oracle(group)))

    ioRng = random.Random(31415)
    with open("in/5_io.txt", "w") as inputHandle, open("out/5_io.out", "w") as outputHandle:
        inputHandle.write("100\n\n")
        for _ in range(100):
            group = circleCase(100000, 10000, ioRng)
            writeCase(inputHandle, group)
            outputHandle.write(formatCase(*oracle(group)))


generate()
