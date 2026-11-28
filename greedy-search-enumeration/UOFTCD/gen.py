#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def replay(moments, movie_length, hand_threshold, leave_threshold):
    timeline = []
    fright = 0
    for moment_time, force in moments:
        fright = max(0, fright + force)
        timeline.append((moment_time, fright))
    held = 0
    for index, (moment_time, fright) in enumerate(timeline):
        if fright >= leave_threshold:
            break
        end_time = timeline[index + 1][0] if index + 1 < len(timeline) else movie_length
        if fright >= hand_threshold:
            held += end_time - moment_time
    return held


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    movie_count = tokens[position]
    position += 1
    answers = []
    for _ in range(movie_count):
        movie_length = tokens[position]
        moment_count = tokens[position + 1]
        hand_threshold = tokens[position + 2]
        leave_threshold = tokens[position + 3]
        position += 4
        moments = []
        for _ in range(moment_count):
            moments.append((tokens[position], tokens[position + 1]))
            position += 2
        best = replay(moments, movie_length, hand_threshold, leave_threshold)
        for skip in range(moment_count):
            changed = moments[:skip] + moments[skip + 1:]
            candidate = replay(changed, movie_length, hand_threshold, leave_threshold)
            if candidate < best:
                best = candidate
        answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE = """2
90 5 5 50
12 8
14 -4
40 6
45 11
73 -50
105 3 5 20
33 15
39 -1
52 5
"""
SAMPLE_OUT = """30
19
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n100 0 5 10\n") == "0\n"
assert oracle("1\n100 1 5 10\n10 20\n") == "0\n"
assert oracle("1\n100 2 5 10\n10 5\n20 5\n") == "10\n"
assert oracle("1\n100 3 1 10\n1 1\n2 9\n3 -1\n") == "1\n"


def write_movies(name, movies):
    lines = [str(len(movies))]
    for movie_length, hand_threshold, leave_threshold, moments in movies:
        lines.append(f"{movie_length} {len(moments)} {hand_threshold} {leave_threshold}")
        for moment_time, force in moments:
            lines.append(f"{moment_time} {force}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_movies("2_edges", [
        (100, 5, 10, []),
        (100, 5, 10, [(10, 20)]),
        (100, 5, 10, [(10, 5)]),
        (100, 5, 10, [(10, 5), (20, 5)]),
        (1000000000, 1, 1000000000, [(1, -100), (2, 0)]),
    ])
    rng = random.Random(20261126)
    wide = []
    for _ in range(100):
        movie_length = rng.randint(100, 1000000000)
        hand_threshold = rng.randint(1, 1000)
        leave_threshold = hand_threshold + rng.randint(1, 10000)
        moments = []
        current_time = 0
        for _ in range(100):
            current_time += rng.randint(1, max(2, movie_length // 200))
            if current_time > movie_length:
                break
            moments.append((current_time, rng.randint(-1000000, 1000000)))
        wide.append((movie_length, hand_threshold, leave_threshold, moments))
    write_movies("3_wide", wide)
    random_movies = []
    for _ in range(50):
        moment_count = rng.randint(1, 100)
        movie_length = rng.randint(50, 10000)
        hand_threshold = rng.randint(1, 50)
        leave_threshold = hand_threshold + rng.randint(1, 200)
        moments = []
        current_time = 0
        for _ in range(moment_count):
            current_time += rng.randint(1, max(2, movie_length // (moment_count + 1)))
            moments.append((current_time, rng.randint(-100, 100)))
        random_movies.append((movie_length, hand_threshold, leave_threshold, moments))
    write_movies("4_random", random_movies)
    io_movies = []
    for _ in range(100):
        movie_length = 1000000000
        moments = [(index * 10 + 1, rng.randint(-1000000, 1000000)) for index in range(100)]
        io_movies.append((movie_length, 5, 50, moments))
    write_movies("5_io", io_movies)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_movies("1_sample", [
    (90, 5, 50, [(12, 8), (14, -4), (40, 6), (45, 11), (73, -50)]),
    (105, 5, 20, [(33, 15), (39, -1), (52, 5)]),
])
build()
