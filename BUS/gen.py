import bisect
import heapq
import math
import random

INF = 10 ** 9


def extended_gcd(first_value, second_value):
    if second_value == 0:
        return first_value, 1, 0
    divisor, x_value, y_value = extended_gcd(second_value, first_value % second_value)
    return divisor, y_value, x_value - (first_value // second_value) * y_value


def chinese_remainder(first_offset, first_modulus, second_offset, second_modulus):
    divisor, _, _ = extended_gcd(first_modulus, second_modulus)
    difference = second_offset - first_offset
    if difference % divisor != 0:
        return None
    reduced_modulus = second_modulus // divisor
    inverse = pow(first_modulus // divisor, -1, reduced_modulus)
    multiplier = (difference // divisor * inverse) % reduced_modulus
    return (first_offset + first_modulus * multiplier) % (first_modulus // divisor * second_modulus)


def build_meeting_sets(routes):
    bus_count = len(routes)
    meeting_sets = {}
    for left_bus in range(bus_count):
        positions_left = {}
        for position, station in enumerate(routes[left_bus]):
            positions_left.setdefault(station, []).append(position)
        for right_bus in range(left_bus + 1, bus_count):
            positions_right = {}
            for position, station in enumerate(routes[right_bus]):
                positions_right.setdefault(station, []).append(position)
            first_length = len(routes[left_bus])
            second_length = len(routes[right_bus])
            period = first_length * second_length // math.gcd(first_length, second_length)
            found_times = set()
            for station in positions_left:
                if station not in positions_right:
                    continue
                for first_offset in positions_left[station]:
                    for second_offset in positions_right[station]:
                        candidate = chinese_remainder(first_offset, first_length, second_offset, second_length)
                        if candidate is not None:
                            found_times.add(candidate)
            if found_times:
                meeting_sets[(left_bus, right_bus)] = (sorted(found_times), period)
    return meeting_sets


def first_meeting_at_or_after(meeting_times, period, current_time):
    within_period = current_time % period
    position = bisect.bisect_left(meeting_times, within_period)
    if position < len(meeting_times):
        return current_time - within_period + meeting_times[position]
    return current_time - within_period + period + meeting_times[0]


def oracle_paths(routes):
    bus_count = len(routes)
    meeting_sets = build_meeting_sets(routes)
    latest_arrival = 0
    for source in range(bus_count):
        arrival = [INF] * bus_count
        arrival[source] = 0
        pending = [(0, source)]
        while pending:
            current_time, current_bus = heapq.heappop(pending)
            if current_time != arrival[current_bus]:
                continue
            for other_bus in range(bus_count):
                if other_bus == current_bus:
                    continue
                key = (min(current_bus, other_bus), max(current_bus, other_bus))
                if key not in meeting_sets:
                    continue
                meeting_times, period = meeting_sets[key]
                next_time = first_meeting_at_or_after(meeting_times, period, current_time)
                if next_time < arrival[other_bus]:
                    arrival[other_bus] = next_time
                    heapq.heappush(pending, (next_time, other_bus))
        for value in arrival:
            if value >= INF:
                return None
            if value > latest_arrival:
                latest_arrival = value
    return latest_arrival


def oracle_simulate(routes, minute_limit=50000):
    bus_count = len(routes)
    knowledge = [1 << bus_index for bus_index in range(bus_count)]
    complete_knowledge = (1 << bus_count) - 1
    for minute in range(minute_limit):
        for left_bus in range(bus_count):
            left_station = routes[left_bus][minute % len(routes[left_bus])]
            for right_bus in range(left_bus + 1, bus_count):
                if left_station == routes[right_bus][minute % len(routes[right_bus])]:
                    knowledge[left_bus] |= knowledge[right_bus]
                    knowledge[right_bus] |= knowledge[left_bus]
        if all(value == complete_knowledge for value in knowledge):
            return minute
    return None


assert oracle_paths([[1, 2, 3], [2, 3, 1], [2, 3, 4, 5]]) == 12
assert oracle_simulate([[1, 2, 3], [2, 3, 1], [2, 3, 4, 5]]) == 12
assert oracle_paths([[1, 2], [5, 8]]) is None
assert oracle_paths([[7]]) == 0
assert oracle_paths([[1, 2], [1, 2]]) == 0
assert oracle_paths([[1, 2], [2, 1]]) is None
assert oracle_paths([[1], [1]]) == 0
assert oracle_paths([[1], [2]]) is None

check_rng = random.Random(20240417)
for _ in range(250):
    small_routes = [
        [check_rng.randint(0, 4) for _ in range(check_rng.randint(1, 5))]
        for _ in range(check_rng.randint(1, 5))
    ]
    assert oracle_simulate(small_routes) == oracle_paths(small_routes), small_routes


def format_case(routes):
    lines = [str(len(routes))]
    for route in routes:
        lines.append(str(len(route)) + ' ' + ' '.join(str(station) for station in route))
    return '\n'.join(lines) + '\n'


def emit(name, case_list):
    input_text = '\n'.join(format_case(routes) for routes in case_list) + '0\n'
    output_lines = []
    for routes in case_list:
        answer = oracle_paths(routes)
        output_lines.append('NEVER' if answer is None else str(answer))
    with open('in/' + name + '.txt', 'w') as handle:
        handle.write(input_text)
    with open('out/' + name + '.out', 'w') as handle:
        handle.write('\n'.join(output_lines) + '\n')


sample_cases = [
    [[1, 2, 3], [2, 3, 1], [2, 3, 4, 5]],
    [[1, 2], [5, 8]],
]
emit('1_sample', sample_cases)

edge_cases = [
    [[9]],
    [[1, 2], [1, 2]],
    [[1, 2], [2, 1]],
    [[1, 2], [3, 4]],
    [[1], [2]],
    [[1], [1]],
    [[1, 2, 3], [2, 3, 1], [2, 3, 4, 5]],
    [[1, 2, 3, 4], [3, 4, 1, 2], [2, 5, 8], [5, 8]],
    [[1], [1, 2, 3], [3, 2, 1], [2, 3, 4, 5]],
]
emit('2_edges', edge_cases)

wide_cases = [[list(range(49)) for _ in range(49)]]
wide_cases.append([[(bus_index + offset) % 49 for offset in range(49)]
                   for bus_index in range(49)])
wide_rng = random.Random(555)
wide_cases.append([
    [wide_rng.randint(0, 48) for _ in range(49)]
    for _ in range(16)
])
emit('3_wide', wide_cases)

random_rng = random.Random(777001)
random_cases = []
for _ in range(140):
    bus_count = random_rng.randint(2, 12)
    route_length = random_rng.randint(1, 9)
    random_cases.append([
        [random_rng.randint(0, 7) for _ in range(route_length)]
        for _ in range(bus_count)
    ])
emit('4_random', random_cases)

io_case = sample_cases[0]
io_text = (format_case(io_case) + '\n') * 60000 + '0\n'
with open('in/5_io.txt', 'w') as handle:
    handle.write(io_text)
with open('out/5_io.out', 'w') as handle:
    handle.write('12\n' * 60000)
