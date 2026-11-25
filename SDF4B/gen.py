#!/usr/bin/env python3
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def clock_text(minutes):
    return f"{minutes // 60:02d}:{minutes % 60:02d}"


def oracle(text):
    tokens = [int(value) for value in re.findall(r"\d+", text)]
    room_count = tokens[0]
    event_count = tokens[1]
    position = 2
    events = []
    for _ in range(event_count):
        start_hour = tokens[position]
        start_minute = tokens[position + 1]
        end_hour = tokens[position + 2]
        end_minute = tokens[position + 3]
        participants = tokens[position + 4]
        position += 5
        start = start_hour * 60 + start_minute
        finish = end_hour * 60 + end_minute + 30 + participants
        events.append((start, finish))
    best = (-1, 10 ** 9)
    for mask in range(1 << event_count):
        chosen = [events[index] for index in range(event_count) if mask >> index & 1]
        if not chosen:
            continue
        points = []
        for start, finish in chosen:
            points.append((start, 1))
            points.append((finish, -1))
        points.sort(key=lambda item: (item[0], item[1]))
        active = 0
        needed = 0
        for _, change in points:
            active += change
            needed = max(needed, active)
        if needed <= room_count:
            candidate = (len(chosen), needed)
            if candidate > best:
                best = candidate
    if best[0] < 0:
        best = (0, 0)
    return f"Jumlah kegiatan/acara: {best[0]}\nJumlah ruang: {best[1]}\n"


SAMPLE = """3 3
06:00 - 08:30 20
07:00 - 09:00 10
09:40 - 11:00 5
"""
SAMPLE_OUT = """Jumlah kegiatan/acara: 3
Jumlah ruang: 2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 2\n19:00 - 21:00 15\n19:45 - 20:00 100\n") == "Jumlah kegiatan/acara: 1\nJumlah ruang: 1\n"
assert oracle("2 2\n06:00 - 08:00 10\n09:00 - 11:00 20\n") == "Jumlah kegiatan/acara: 2\nJumlah ruang: 1\n"
assert oracle("1 3\n10:00 - 11:00 10\n10:30 - 11:30 10\n12:00 - 13:00 10\n") == "Jumlah kegiatan/acara: 2\nJumlah ruang: 1\n"


def write_cases(name, room_count, events):
    text = f"{room_count} {len(events)}\n"
    for start, finish, participants in events:
        text += f"{clock_text(start)} - {clock_text(finish)} {participants}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_cases("2_edges", 1, [(120, 240, 5), (180, 300, 5)])
    rng = random.Random(20261126)
    wide = []
    for _ in range(12):
        start = rng.randint(0, 1000)
        finish = min(start + rng.randint(30, 300), 1380)
        wide.append((start, finish, rng.randint(1, 100)))
    write_cases("3_wide", 100000, wide)
    random_events = []
    for _ in range(12):
        start = rng.randint(0, 1100)
        finish = min(start + rng.randint(30, 180), 1380)
        random_events.append((start, finish, rng.randint(1, 100)))
    write_cases("4_random", 3, random_events)
    write_cases("5_io", 1, [(600 + index * 30, 750 + index * 30, rng.randint(1, 100)) for index in range(12)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
