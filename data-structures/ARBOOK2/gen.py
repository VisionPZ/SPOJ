#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.split("\n")
    count = int(lines[0])
    results = []
    cursor = 1
    for _ in range(count):
        title = lines[cursor]
        author = lines[cursor + 1]
        subject = lines[cursor + 2]
        book_id = int(lines[cursor + 3])
        results.append(f"{title} : {author} : {subject} : {book_id}")
        cursor += 4
    return "\n".join(results) + "\n" if results else ""


SAMPLE = (
    "2\n"
    "thang quy nho\nnguyen nhat anh\nthanh xuan vuon truong\n2\n"
    "bo cau khong dua thu\nnguyen nhat anh\nthanh xuan vuon truong\n1\n"
)
SAMPLE_OUT = (
    "thang quy nho : nguyen nhat anh : thanh xuan vuon truong : 2\n"
    "bo cau khong dua thu : nguyen nhat anh : thanh xuan vuon truong : 1\n"
)

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\nA\nB\nC\n7\n") == "A : B : C : 7\n"
assert oracle("2\nT1\nA1\nS1\n10\nT2\nA2\nS2\n20\n") == \
    "T1 : A1 : S1 : 10\nT2 : A2 : S2 : 20\n"


def write(name, books):
    lines = [str(len(books))]
    for title, author, subject, book_id in books:
        lines.extend([title, author, subject, str(book_id)])
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [("", "", "", 42)])
    write("3_wide", [("T" * 200, "A " * 100, "S" * 200, 2147483647)])
    rng = random.Random(20261126)
    titles = ["thang quy nho", "bo cau khong dua thu", "nghin le mot dem"]
    authors = ["nguyen nhat anh", "khong tac gia", "tran thanh hung"]
    subjects = ["thanh xuan vuon truong", "co tich", "tin hoc co ban"]
    for name, count in (("4_random", 19), ("5_io", 4000)):
        books = []
        for index in range(count):
            books.append((rng.choice(titles) + " " + str(index),
                          rng.choice(authors), rng.choice(subjects),
                          rng.randint(0, 10 ** 9)))
        write(name, books)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
