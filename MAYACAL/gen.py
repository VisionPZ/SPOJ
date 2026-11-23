#!/usr/bin/env python3
import random

TZ_NAMES = ["Imix", "Ik", "Akbal", "Kan", "Chikchan", "Kimi", "Manik", "Lamat", "Muluk", "Ok", "Chuen", "Eb", "Ben", "Ix", "Men", "Kib", "Kaban", "Etznab", "Kawak", "Ajaw"]
HAAB_NAMES = ["Pohp", "Wo", "Sip", "Zotz", "Sek", "Xul", "Yaxkin", "Mol", "Chen", "Yax", "Sak", "Keh", "Mak", "Kankin", "Muan", "Pax", "Kayab", "Kumku", "Wayeb"]
MONTH_LENGTHS = [20] * 18 + [5]
DAYS_PER_KATUN = 7200
DAYS_PER_TUN = 360
DAYS_PER_WINAL = 20
DAYS_PER_BAKTUN = 144000
CALENDAR_ROUND = 18980
RANGE_START = 8 * DAYS_PER_BAKTUN
RANGE_LENGTH = 2 * DAYS_PER_BAKTUN
RANGE_END = RANGE_START + RANGE_LENGTH - 1
REFERENCE_KEY = (9, 19, 3, 2)


def advance(state):
    tz_num, tz_name, h_num, h_month = state
    tz_num = tz_num % 13 + 1
    tz_name = (tz_name + 1) % 20
    h_num += 1
    if h_num > MONTH_LENGTHS[h_month]:
        h_num = 1
        h_month = (h_month + 1) % 19
    return (tz_num, tz_name, h_num, h_month)


def build_calendar():
    occurrences = {}
    state = REFERENCE_KEY
    for step in range(RANGE_LENGTH):
        occurrences.setdefault(state, []).append(RANGE_START + step)
        state = advance(state)
    return occurrences, state


def long_count(day):
    baktun, rest = divmod(day, DAYS_PER_BAKTUN)
    katun, rest = divmod(rest, DAYS_PER_KATUN)
    tun, rest = divmod(rest, DAYS_PER_TUN)
    winal, kin = divmod(rest, DAYS_PER_WINAL)
    return "%d.%d.%d.%d.%d" % (baktun, katun, tun, winal, kin)


def key_to_query(key):
    tz_num, tz_name, h_num, h_month = key
    return [str(tz_num), TZ_NAMES[tz_name], str(h_num), HAAB_NAMES[h_month]]


def parse_query(parts):
    if len(parts) != 4:
        return None
    try:
        tz_num = int(parts[0])
    except ValueError:
        return None
    try:
        h_num = int(parts[2])
    except ValueError:
        return None
    if parts[1] not in TZ_NAMES or parts[3] not in HAAB_NAMES:
        return None
    tz_name = TZ_NAMES.index(parts[1])
    h_month = HAAB_NAMES.index(parts[3])
    if not (1 <= tz_num <= 13):
        return None
    if not (1 <= h_num <= MONTH_LENGTHS[h_month]):
        return None
    return (tz_num, tz_name, h_num, h_month)


def expected_output(queries, occurrences):
    lines = []
    for parts in queries:
        key = parse_query(parts)
        days = occurrences.get(key, []) if key is not None else []
        lines.append(str(len(days)))
        lines.extend(long_count(day) for day in days)
    return "\n".join(lines) + "\n"


def render_input(queries):
    return str(len(queries)) + "\n" + "".join(" ".join(parts) + "\n" for parts in queries)


OCCURRENCES, STATE_AFTER_RANGE = build_calendar()

SAMPLE_QUERIES = [["3", "Lamat", "6", "Pax"], ["1", "Ajaw", "9", "Chen"]]
SAMPLE_OUTPUT = "\n".join([
    "15", "8.0.17.17.8", "8.3.10.12.8", "8.6.3.7.8", "8.8.16.2.8",
    "8.11.8.15.8", "8.14.1.10.8", "8.16.14.5.8", "8.19.7.0.8",
    "9.1.19.13.8", "9.4.12.8.8", "9.7.5.3.8", "9.9.17.16.8",
    "9.12.10.11.8", "9.15.3.6.8", "9.17.16.1.8", "0",
]) + "\n"

assert len(OCCURRENCES) == CALENDAR_ROUND
assert RANGE_LENGTH == 288000 and RANGE_END == 1439999
assert OCCURRENCES[REFERENCE_KEY] == list(range(RANGE_START, RANGE_START + 16 * CALENDAR_ROUND, CALENDAR_ROUND))
assert expected_output(SAMPLE_QUERIES, OCCURRENCES) == SAMPLE_OUTPUT
assert long_count(RANGE_END) == "9.19.19.17.19"
assert len(parse_query(["1", "Ajaw", "9", "Chen"])) == 4
assert parse_query(["1", "Ajaw", "9", "Chen"]) not in OCCURRENCES
assert parse_query(["1", "Imix", "6", "Wayeb"]) is None
assert parse_query(["14", "Imix", "1", "Pohp"]) is None
assert parse_query(["1", "Nope", "1", "Pohp"]) is None

cycle_state = REFERENCE_KEY
for _ in range(CALENDAR_ROUND):
    cycle_state = advance(cycle_state)
assert cycle_state == REFERENCE_KEY

full_keys = sorted(OCCURRENCES, key=lambda key: OCCURRENCES[key][0])
sixteen_keys = [key for key in full_keys if len(OCCURRENCES[key]) == 16]
wayeb_keys = [key for key in full_keys if key[3] == 18]
illegal_keys = []
for tz_num in range(1, 14):
    for tz_name in range(20):
        for h_num in range(1, 6):
            candidate = (tz_num, tz_name, h_num, 18)
            if candidate not in OCCURRENCES:
                illegal_keys.append(candidate)
assert len(sixteen_keys) > 100 and len(wayeb_keys) > 100 and len(illegal_keys) > 10


def write_case(name, queries):
    with open("in/" + name + ".txt", "w") as input_file:
        input_file.write(render_input(queries))
    with open("out/" + name + ".out", "w") as output_file:
        output_file.write(expected_output(queries, OCCURRENCES))


def main():
    with open("in/1_sample.txt", "w") as input_file:
        input_file.write(render_input(SAMPLE_QUERIES))
    with open("out/1_sample.out", "w") as output_file:
        output_file.write(SAMPLE_OUTPUT)

    last_key = None
    for key, days in OCCURRENCES.items():
        if days[-1] == RANGE_END:
            last_key = key
            break
    assert last_key is not None
    edges = [REFERENCE_KEY, last_key, full_keys[-1],
             (1, 19, 9, 2), wayeb_keys[0], wayeb_keys[-1], illegal_keys[0],
             (0, 0, 1, 0), (14, 0, 1, 0), (1, 0, 0, 0), (1, 0, 21, 0),
             (1, 0, 6, 18)]
    write_case("2_edges", [key_to_query(key) for key in edges])

    rng = random.Random(20261124)
    wide = [full_keys[0], full_keys[-1], sixteen_keys[0], sixteen_keys[-1],
            wayeb_keys[0], wayeb_keys[-1], illegal_keys[0]]
    wide += [rng.choice(full_keys) for _ in range(23)]
    write_case("3_wide", [key_to_query(key) for key in wide])

    random_queries = []
    for _ in range(30):
        if rng.random() < 0.6:
            random_queries.append(key_to_query(rng.choice(full_keys)))
        else:
            random_queries.append([str(rng.randint(0, 15)),
                                   rng.choice(TZ_NAMES + ["Bogus"]),
                                   str(rng.randint(0, 22)),
                                   rng.choice(HAAB_NAMES + ["Bogus"])])
    write_case("4_random", random_queries)

    io_keys = [sixteen_keys[index * len(sixteen_keys) // 30] for index in range(30)]
    assert all(len(OCCURRENCES[key]) == 16 for key in io_keys)
    write_case("5_io", [key_to_query(key) for key in io_keys])

    stress_queries = [key_to_query(io_keys[index % len(io_keys)]) for index in range(200000)]
    with open("/tmp/MAYACAL_big.txt", "w") as stress_file:
        stress_file.write(render_input(stress_queries))

    print("generated five cases and stress file")


if __name__ == "__main__":
    main()
