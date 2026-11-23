import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))


def hmask(value, width_mask):
    return value ^ ((value << 1) & width_mask) ^ (value >> 1)


def ge_solve(work_rows, width, height):
    all_on = (1 << width) - 1
    row_images = [[0] * width for _ in range(height)]
    offsets = [0] * height
    for col in range(width):
        row_images[0][col] = 1 << col
        row_images[1][col] = hmask(1 << col, all_on)
    offsets[1] = work_rows[0] ^ all_on
    for row in range(1, height - 1):
        for col in range(width):
            row_images[row + 1][col] = hmask(row_images[row][col], all_on) ^ row_images[row - 1][col]
        offsets[row + 1] = hmask(offsets[row], all_on) ^ offsets[row - 1] ^ work_rows[row] ^ all_on
    final_coeff = [hmask(row_images[height - 1][col], all_on) ^ row_images[height - 2][col]
                   for col in range(width)]
    final_target = work_rows[height - 1] ^ all_on ^ hmask(offsets[height - 1], all_on) ^ offsets[height - 2]
    equations = [0] * width
    for bit in range(width):
        equation = 0
        for col in range(width):
            if (final_coeff[col] >> bit) & 1:
                equation |= 1 << col
        if (final_target >> bit) & 1:
            equation |= 1 << width
        equations[bit] = equation
    pivot_count = 0
    pivot_columns = [0] * width
    for col in range(width):
        selected = -1
        for row in range(pivot_count, width):
            if (equations[row] >> col) & 1:
                selected = row
                break
        if selected < 0:
            continue
        equations[pivot_count], equations[selected] = equations[selected], equations[pivot_count]
        for row in range(width):
            if row != pivot_count and ((equations[row] >> col) & 1):
                equations[row] ^= equations[pivot_count]
        pivot_columns[pivot_count] = col
        pivot_count += 1
    for row in range(pivot_count, width):
        if (equations[row] >> width) & 1:
            return None
    first_pattern = 0
    pivot_index = pivot_count - 1
    while pivot_index >= 0:
        if (equations[pivot_index] >> width) & 1:
            first_pattern |= 1 << pivot_columns[pivot_index]
        pivot_index -= 1
    press = [0] * height
    press[0] = first_pattern
    press[1] = hmask(first_pattern, all_on) ^ offsets[1]
    for row in range(1, height - 1):
        press[row + 1] = work_rows[row] ^ all_on ^ hmask(press[row], all_on) ^ press[row - 1]
    return press


def brute_solve(work_rows, width, height):
    all_on = (1 << width) - 1
    for pattern in range(1 << width):
        press = [0] * height
        press[0] = pattern
        for row in range(height - 1):
            press[row + 1] = work_rows[row] ^ all_on ^ hmask(press[row], all_on) ^ press[row - 1]
        if (work_rows[height - 1] ^ all_on ^ hmask(press[height - 1], all_on) ^ press[height - 2]) == 0:
            return press
    return None


def verify(work_rows, width, height, press):
    board = [[(work_rows[row] >> col) & 1 for col in range(width)] for row in range(height)]
    for row in range(height):
        for col in range(width):
            if (press[row] >> col) & 1:
                for nr, nc in ((row, col), (row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1)):
                    if 0 <= nr < height and 0 <= nc < width:
                        board[nr][nc] ^= 1
    return all(all(value == 1 for value in row) for row in board)


def orient(width, height, source_rows):
    if height < width:
        work_width = height
        work_height = width
        work_rows = []
        for column in range(width):
            mask = 0
            for row in range(height):
                if (source_rows[row] >> column) & 1:
                    mask |= 1 << row
            work_rows.append(mask)
        return work_width, work_height, work_rows, True
    return width, height, list(source_rows), False


def output_text(width, height, source_rows):
    work_width, work_height, work_rows, transposed = orient(width, height, source_rows)
    press = ge_solve(work_rows, work_width, work_height)
    if press is None:
        return "-1\n"
    steps = []
    for row in range(work_height):
        for col in range(work_width):
            if (press[row] >> col) & 1:
                if transposed:
                    steps.append((row + 1, col + 1))
                else:
                    steps.append((col + 1, row + 1))
    lines = [str(len(steps))]
    lines.extend("{} {}".format(first, second) for first, second in steps)
    return "\n".join(lines) + "\n"


def rows_from_strings(strings):
    return [sum(1 << col for col, char in enumerate(row) if char == "1") for row in strings]


def case_text(width, height, strings):
    return "{} {}\n".format(width, height) + "\n".join(strings) + "\n\n"


def write_case(name, cases):
    input_parts = []
    output_parts = []
    for width, height, strings in cases:
        source_rows = rows_from_strings(strings)
        input_parts.append(case_text(width, height, strings))
        output_parts.append(output_text(width, height, source_rows))
    with open(os.path.join(HERE, "in", name + ".txt"), "w") as handle:
        handle.write("".join(input_parts) + "0 0\n")
    with open(os.path.join(HERE, "out", name + ".out"), "w") as handle:
        handle.write("".join(output_parts))


def random_strings(width, height, rng):
    return ["".join(rng.choice("01") for _ in range(width)) for _ in range(height)]


def check_preconditions():
    sample_out = output_text(4, 3, rows_from_strings(["0111", "1010", "1000"]))
    assert sample_out == "3\n1 2\n1 3\n4 3\n", sample_out
    all_on = output_text(3, 3, rows_from_strings(["111", "111", "111"]))
    assert all_on == "0\n", all_on
    rng = random.Random(4242)
    for _ in range(1200):
        width = rng.randint(3, 7)
        height = rng.randint(3, 7)
        strings = random_strings(width, height, rng)
        source_rows = rows_from_strings(strings)
        work_width, work_height, work_rows, _ = orient(width, height, source_rows)
        fast = ge_solve(work_rows, work_width, work_height)
        slow = brute_solve(work_rows, work_width, work_height)
        assert (fast is None) == (slow is None), (strings, fast, slow)
        if fast is not None:
            assert verify(work_rows, work_width, work_height, fast), (strings, fast)
            assert verify(work_rows, work_width, work_height, slow), (strings, slow)
    size = 15
    all_on_mask = (1 << size) - 1
    effect = [0] * size
    for row in range(size):
        for col in range(size):
            degree = 1
            for nr, nc in ((row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1)):
                if 0 <= nr < size and 0 <= nc < size:
                    degree += 1
            if degree % 2:
                effect[row] |= 1 << col
    press_all = [all_on_mask] * size
    initial = [row ^ all_on_mask for row in effect]
    assert verify(initial, size, size, press_all)
    assert sum(bin(mask).count("1") for mask in press_all) == 225
    forced_rows = rows_from_strings(full_press_board())
    forced_press = ge_solve(forced_rows, size, size)
    assert forced_press is not None
    assert sum(bin(mask).count("1") for mask in forced_press) == 225


def full_press_board():
    size = 15
    all_on_mask = (1 << size) - 1
    effect = [0] * size
    for row in range(size):
        for col in range(size):
            degree = 1
            for nr, nc in ((row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1)):
                if 0 <= nr < size and 0 <= nc < size:
                    degree += 1
            if degree % 2:
                effect[row] |= 1 << col
    return ["".join("0" if (effect[row] >> col) & 1 else "1" for col in range(size))
            for row in range(size)]


def main():
    check_preconditions()
    sample = [(4, 3, ["0111", "1010", "1000"])]
    write_case("1_sample", sample)

    edges = [
        (3, 3, ["111", "111", "111"]),
        (3, 3, ["000", "000", "000"]),
        (5, 3, ["01010", "10101", "01010"]),
        (3, 5, ["010", "101", "010", "101", "010"]),
        (4, 4, ["1000", "0000", "0000", "0000"]),
        (6, 4, ["010110", "101001", "001010", "110100"]),
    ]
    write_case("2_edges", edges)

    wide = [
        (15, 15, ["0" * 15 for _ in range(15)]),
        (15, 15, ["1" * 15 for _ in range(15)]),
        (15, 3, ["101010101010101", "010101010101010", "111000111000111"]),
        (3, 15, ["101", "010", "101", "010", "101", "010", "101", "010",
                 "101", "010", "101", "010", "101", "010", "101"]),
        (14, 15, [random_strings(14, 1, random.Random(700 + row))[0] for row in range(15)]),
    ]
    write_case("3_wide", wide)

    rng = random.Random(20261124)
    random_cases = []
    for _ in range(200):
        width = rng.randint(3, 15)
        height = rng.randint(3, 15)
        random_cases.append((width, height, random_strings(width, height, rng)))
    write_case("4_random", random_cases)

    io_cases = [(15, 15, full_press_board()) for _ in range(800)]
    write_case("5_io", io_cases)


if __name__ == "__main__":
    main()
