import os
import random
from bisect import bisect_left, bisect_right

MAX_TIME = 1000000000
MAX_CRIME_TIME = 100000000
MAX_PEOPLE = 5000


def candidate_moments(crime_start, crime_end, intervals):
    marks = set([crime_start, crime_end])
    for arrival, departure in intervals:
        marks.add(arrival)
        marks.add(departure)
    ordered = sorted(marks)
    moments = [value for value in ordered if crime_start <= value <= crime_end]
    for left, right in zip(ordered, ordered[1:]):
        middle = (left + right) / 2.0
        if crime_start <= middle <= crime_end:
            moments.append(middle)
    return moments


def oracle_bruteforce(crime_start, crime_end, intervals):
    counts = []
    for moment in candidate_moments(crime_start, crime_end, intervals):
        total = 0
        for arrival, departure in intervals:
            if arrival <= moment <= departure:
                total = total + 1
        counts.append(total)
    return min(counts), max(counts)


def oracle_binarysearch(crime_start, crime_end, intervals):
    arrivals = sorted(arrival for arrival, _ in intervals)
    departures = sorted(departure for _, departure in intervals)
    counts = []
    for moment in candidate_moments(crime_start, crime_end, intervals):
        counts.append(bisect_right(arrivals, moment) - bisect_left(departures, moment))
    return min(counts), max(counts)


assert oracle_bruteforce(5, 10, [(1, 8), (5, 8), (7, 10), (8, 9)]) == (1, 4)
assert oracle_bruteforce(5, 20, [(5, 20), (5, 10), (11, 20)]) == (1, 2)
assert oracle_bruteforce(5, 10, [(5, 7), (8, 10)]) == (0, 1)
assert oracle_bruteforce(1, 2, [(1, 1), (2, 2)]) == (0, 1)

check_rng = random.Random(707)
for _ in range(200):
    crime_start = check_rng.randint(0, 20)
    crime_end = crime_start + check_rng.randint(0, 20)
    intervals = []
    for _ in range(check_rng.randint(1, 12)):
        arrival = check_rng.randint(0, 25)
        intervals.append((arrival, arrival + check_rng.randint(0, 8)))
    assert oracle_bruteforce(crime_start, crime_end, intervals) == oracle_binarysearch(crime_start, crime_end, intervals)


def pad(intervals, crime_end):
    padded = list(intervals)
    while len(padded) < 3:
        padded.append((MAX_TIME, MAX_TIME))
    return padded


def emit(name, cases):
    body = []
    input_lines = []
    for crime_start, crime_end, intervals in cases:
        intervals = pad(intervals, crime_end)
        answer = oracle_binarysearch(crime_start, crime_end, intervals)
        if len(intervals) <= 60:
            assert answer == oracle_bruteforce(crime_start, crime_end, intervals)
        body.append(f"{answer[0]} {answer[1]}\n")
        input_lines.append(f"{crime_start} {crime_end}\n")
        input_lines.append(f"{len(intervals)}\n")
        for arrival, departure in intervals:
            input_lines.append(f"{arrival} {departure}\n")
    with open(f"in/{name}.txt", "w") as stream:
        stream.write("".join(input_lines))
    with open(f"out/{name}.out", "w") as stream:
        stream.write("".join(body))


os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

emit("1_sample", [(5, 10, [(1, 8), (5, 8), (7, 10), (8, 9)])])

emit("2_edges", [
    (0, 0, [(0, 0)]),
    (7, 7, [(7, 7), (7, 7), (1, 6)]),
    (5, 10, [(5, 10)]),
    (5, 10, [(1, 4), (11, 20)]),
    (1, 10, [(1, 5), (5, 10)]),
    (5, 10, [(5, 7), (8, 10)]),
    (5, 20, [(5, 20), (5, 10), (11, 20)]),
    (0, MAX_CRIME_TIME, [(0, MAX_TIME)]),
    (MAX_CRIME_TIME, MAX_CRIME_TIME, [(999999999, MAX_TIME), (MAX_CRIME_TIME, MAX_CRIME_TIME)]),
    (0, MAX_CRIME_TIME, [(0, 0), (1, 1), (MAX_CRIME_TIME, MAX_CRIME_TIME)]),
    (3, 6, [(0, 3), (3, 6), (6, 9)]),
    (10, 10, [(1, 9), (11, 20), (10, 10)]),
])

wide_rng = random.Random(31337)
wide_cases = []
for crime_start, crime_end in [
    (0, MAX_CRIME_TIME),
    (MAX_CRIME_TIME, MAX_CRIME_TIME),
    (MAX_CRIME_TIME - 1, MAX_CRIME_TIME),
    (0, 1),
    (50000000, 50000100),
]:
    intervals = []
    for _ in range(MAX_PEOPLE):
        arrival = wide_rng.randint(max(0, crime_start - 5000), min(MAX_TIME, crime_end + 5000))
        departure = min(MAX_TIME, arrival + wide_rng.randint(0, 300000000))
        intervals.append((arrival, departure))
    wide_cases.append((crime_start, crime_end, intervals))
emit("3_wide", wide_cases)

random_rng = random.Random(20261123)
random_cases = []
for _ in range(10):
    crime_start = random_rng.randint(0, MAX_CRIME_TIME)
    crime_end = crime_start + random_rng.randint(0, MAX_CRIME_TIME - crime_start)
    intervals = []
    for _ in range(MAX_PEOPLE):
        arrival = random_rng.randint(max(0, crime_start - 5000), min(MAX_TIME, crime_end + 5000))
        departure = min(MAX_TIME, arrival + random_rng.randint(0, 200000000))
        intervals.append((arrival, departure))
    random_cases.append((crime_start, crime_end, intervals))
emit("4_random", random_cases)

io_cases = []
for case_index in range(10):
    crime_start = 0
    crime_end = 100000000 if case_index % 2 == 0 else 99999999
    intervals = [(case_index, MAX_TIME) for _ in range(MAX_PEOPLE)]
    io_cases.append((crime_start, crime_end, intervals))
emit("5_io", io_cases)

print("generated five test pairs")
