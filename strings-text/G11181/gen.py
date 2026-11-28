#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_IN = (
    "los pollitos dicen,\n"
    "pio, PIO,pIo,\n"
    "cuando tienen hambre.\n"
    "cuando tiEnen frio,\n"
    "La gallina busca,\n"
    "el maiz y el trigo,\n"
    "les da la comida,\n"
    "y les presta abrigo\n"
)
SAMPLE_OUT = (
    "abrigo\nbusca\ncomida\ncuando\nda\ndicen\nel\nfrio\ngallina\nhambre\n"
    "la\nles\nlos\nmaiz\npio\npollitos\npresta\ntienen\ntrigo\ny\n"
)


def words_in(text):
    out = []
    cur = []
    for ch in text:
        if ("a" <= ch <= "z") or ("A" <= ch <= "Z"):
            cur.append(ch.lower())
        else:
            if cur:
                out.append("".join(cur))
                cur = []
    if cur:
        out.append("".join(cur))
    return out


def oracle(text):
    return "".join(w + "\n" for w in sorted(set(words_in(text))))


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def trace_example():
    text = SAMPLE_IN
    found = words_in(text)
    print("raw word tokens:", len(found))
    print("distinct:", len(set(found)))
    print("first five sorted:", sorted(set(found))[:5])
    print("duplicates removed:", sorted(w for w in found if found.count(w) > 1))


assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("Aa AA a b\n") == "a\naa\nb\n"
assert oracle("z,y,x\n") == "x\ny\nz\n"
assert oracle("\n\n") == ""
assert oracle("hello\n") == "hello\n"


def build():
    write("2_edges", "a\nB\n#\n")
    write("3_punct", "ab-cd,ef;gh.ij\nAB CD EF\n")
    rng = random.Random(11181)
    alphabet = "abcdefghijklmnopqrstuvwxyz"
    lines = []
    for _ in range(5000):
        words = []
        width = 0
        while width < 195:
            w = "".join((rng.choice(alphabet).upper() if rng.random() < 0.3 else rng.choice(alphabet)) for _ in range(rng.randint(1, 12)))
            words.append(w)
            width += len(w) + 1
        lines.append(" ".join(words) + rng.choice(["", ",", ".", ";"]))
    write("4_random", "\n".join(lines) + "\n")
    write("5_io", "\n".join("word" * 40 for _ in range(5000)) + "\n")


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", SAMPLE_IN)
        build()
