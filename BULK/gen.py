import os
import random

IN_DIR = 'in'
OUT_DIR = 'out'


def cubes_box(x0, x1, y0, y1, z0, z1):
    return {(x, y, z) for x in range(x0, x1 + 1)
            for y in range(y0, y1 + 1) for z in range(z0, z1 + 1)}


def plane_cells(cubes):
    cells = {}
    for (x, y, z) in cubes:
        if (x - 1, y, z) not in cubes:
            cells.setdefault((0, x, -1), set()).add((y, z))
        if (x + 1, y, z) not in cubes:
            cells.setdefault((0, x + 1, 1), set()).add((y, z))
        if (x, y - 1, z) not in cubes:
            cells.setdefault((1, y, -1), set()).add((z, x))
        if (x, y + 1, z) not in cubes:
            cells.setdefault((1, y + 1, 1), set()).add((z, x))
        if (x, y, z - 1) not in cubes:
            cells.setdefault((2, z, -1), set()).add((x, y))
        if (x, y, z + 1) not in cubes:
            cells.setdefault((2, z + 1, 1), set()).add((x, y))
    return cells


def rects_from_cells(cellset):
    remaining = set(cellset)
    rectangles = []
    while remaining:
        first_u = min(u for (u, v) in remaining)
        first_v = min(v for (u, v) in remaining if u == first_u)
        last_v = first_v
        while (first_u, last_v + 1) in remaining:
            last_v += 1
        last_u = first_u
        while all((last_u + 1, value_v) in remaining
                  for value_v in range(first_v, last_v + 1)):
            last_u += 1
        for value_u in range(first_u, last_u + 1):
            for value_v in range(first_v, last_v + 1):
                remaining.remove((value_u, value_v))
        rectangles.append([(first_u, first_v), (last_u + 1, first_v),
                           (last_u + 1, last_v + 1), (first_u, last_v + 1)])
    return rectangles


def polygon_to_3d(axis, plane, polygon):
    result = []
    for (u_coord, v_coord) in polygon:
        if axis == 0:
            result.append((plane, u_coord, v_coord))
        elif axis == 1:
            result.append((v_coord, plane, u_coord))
        else:
            result.append((u_coord, v_coord, plane))
    return result


def build_faces(cubes, rng, overrides=None):
    cells = plane_cells(cubes)
    faces = []
    for plane_key in sorted(cells):
        axis, plane, side = plane_key
        polygons = (overrides or {}).get(plane_key)
        if polygons is None:
            polygons = rects_from_cells(cells[plane_key])
        for polygon in polygons:
            points = polygon_to_3d(axis, plane, polygon)
            if rng.random() < 0.45:
                points = points[::-1]
            faces.append(points)
    rng.shuffle(faces)
    return faces


def format_case(faces):
    lines = [str(len(faces))]
    for points in faces:
        coordinates = [' '.join(str(value) for value in point) for point in points]
        lines.append(str(len(points)) + '  ' + '  '.join(coordinates))
    return '\n'.join(lines) + '\n'


def random_polycube(rng, target_count, extent):
    cubes = {(0, 0, 0)}
    while len(cubes) < target_count:
        base = rng.choice(tuple(cubes))
        axis = rng.randrange(3)
        step = rng.choice((-1, 1))
        neighbor = list(base)
        neighbor[axis] += step
        if all(0 <= value < extent for value in neighbor):
            cubes.add(tuple(neighbor))
    return cubes


def emit_to(input_path, output_path, cases, rng):
    input_lines = [str(len(cases))]
    output_lines = []
    for cubes, overrides in cases:
        faces = build_faces(cubes, rng, overrides)
        assert 6 <= len(faces) <= 250, (input_path, len(faces))
        for points in faces:
            assert 4 <= len(points) <= 200
        input_lines.append(format_case(faces).rstrip('\n'))
        output_lines.append('The bulk is composed of %d units.' % len(cubes))
    with open(input_path, 'w') as handle:
        handle.write('\n'.join(input_lines) + '\n')
    with open(output_path, 'w') as handle:
        handle.write('\n'.join(output_lines) + '\n')


def emit(test_name, cases, rng):
    emit_to(os.path.join(IN_DIR, test_name + '.txt'),
            os.path.join(OUT_DIR, test_name + '.out'), cases, rng)


SAMPLE_INPUT = '''2
12
4  10 10 10  10 10 20  10 20 20  10 20 10
4  20 10 10  20 10 20  20 20 20  20 20 10
4  10 10 10  10 10 20  20 10 20  20 10 10
4  10 20 10  10 20 20  20 20 20  20 20 10
4  10 10 10  10 20 10  20 20 10  20 10 10
5  10 10 20  10 20 20  20 20 20  20 15 20  20 10 20
4  14 14 14  14 14 16  14 16 16  14 16 14
4  16 14 14  16 14 16  16 16 16  16 16 14
4  14 14 14  14 14 16  16 14 16  16 14 14
4  14 16 14  14 16 16  16 16 16  16 16 14
4  14 14 14  14 16 14  16 16 14  16 14 14
4  14 14 16  14 16 16  16 16 16  16 14 16
12
4  20 20 30  20 30 30  30 30 30  30 20 30
4  10 10 10  10 40 10  40 40 10  40 10 10
6  10 10 20  20 10 20  20 30 20  30 30 20  30 40 20  10 40 20
6  20 10 20  20 20 20  30 20 20  30 40 20  40 40 20  40 10 20
4  10 10 10  40 10 10  40 10 20  10 10 20
4  10 40 10  40 40 10  40 40 20  10 40 20
4  20 20 20  30 20 20  30 20 30  20 20 30
4  20 30 20  30 30 20  30 30 30  20 30 30
4  10 10 10  10 40 10  10 40 20  10 10 20
4  40 10 10  40 40 10  40 40 20  40 10 20
4  20 20 20  20 30 20  20 30 30  20 20 30
4  30 20 20  30 30 20  30 30 30  30 20 30
'''


def main():
    os.makedirs(IN_DIR, exist_ok=True)
    os.makedirs(OUT_DIR, exist_ok=True)
    rng = random.Random(20201123)

    with open(os.path.join(IN_DIR, '1_sample.txt'), 'w') as handle:
        handle.write(SAMPLE_INPUT)
    with open(os.path.join(OUT_DIR, '1_sample.out'), 'w') as handle:
        handle.write('The bulk is composed of 992 units.\n'
                     'The bulk is composed of 10000 units.\n')

    assert len(cubes_box(0, 0, 0, 0, 0, 0)) == 1
    assert len(cubes_box(10, 19, 10, 19, 10, 19)) == 1000
    assert len(cubes_box(0, 9, 0, 9, 0, 9) - cubes_box(2, 7, 2, 7, 2, 7)) == 784
    assert len(cubes_box(0, 39, 0, 39, 0, 9)) == 16000

    edge_shapes = [
        cubes_box(0, 0, 0, 0, 0, 0),
        cubes_box(0, 2, 0, 0, 0, 0),
        {(0, 0, 0), (1, 0, 0), (1, 1, 0), (1, 1, 1)},
        cubes_box(0, 2, 0, 2, 0, 2) - {(1, 1, 1)},
        cubes_box(0, 4, 0, 4, 0, 4) - cubes_box(1, 3, 1, 3, 1, 3),
    ]
    assert [len(shape) for shape in edge_shapes] == [1, 3, 4, 26, 98]
    emit('2_edges', [(shape, None) for shape in edge_shapes], rng)

    concave_plate = cubes_box(0, 2, 0, 2, 0, 0) - {(2, 2, 0)}
    assert len(concave_plate) == 8
    concave_override = {(2, 1, 1): [[(0, 0), (3, 0), (3, 2), (2, 2), (2, 3), (0, 3)]]}
    wide_shapes = [
        cubes_box(10, 19, 10, 19, 10, 19),
        cubes_box(0, 9, 0, 9, 0, 9) - cubes_box(2, 7, 2, 7, 2, 7),
        cubes_box(0, 39, 0, 39, 0, 9),
        (cubes_box(0, 19, 0, 19, 0, 9) |
         cubes_box(5, 9, 5, 9, 10, 19) |
         cubes_box(0, 4, 15, 19, 10, 14)),
        concave_plate,
    ]
    assert [len(shape) for shape in wide_shapes] == [1000, 784, 16000, 4375, 8]
    wide_overrides = [None, None, None, None, concave_override]
    emit('3_wide', list(zip(wide_shapes, wide_overrides)), rng)

    random_cases = []
    for case_index in range(40):
        target = 10 + (case_index * 7) % 45
        extent = 5 + case_index % 3
        shape = random_polycube(rng, target, extent)
        random_cases.append((shape, None))
    emit('4_random', random_cases, rng)

    io_cases = []
    for case_index in range(1000):
        target = 1 + case_index % 9
        shape = random_polycube(rng, target, 3)
        io_cases.append((shape, None))
    emit('5_io', io_cases, rng)

    stress_cases = []
    for case_index in range(400):
        extent = 8 + case_index % 3
        target = 60 + (case_index * 13) % 140
        shape = random_polycube(rng, target, extent)
        stress_cases.append((shape, None))
    emit_to('/tmp/BULK_big.txt', '/tmp/BULK_big_expected.out', stress_cases, rng)


if __name__ == '__main__':
    main()
