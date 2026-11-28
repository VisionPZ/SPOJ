#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.split("\n")
    cursor = 0
    while cursor < len(lines) and lines[cursor] == "":
        cursor += 1
    source = lines[cursor]
    cursor += 1
    spell_count = int(lines[cursor].strip())
    cursor += 1
    spells = [lines[cursor + index].strip() for index in range(spell_count)]
    survivor = ""
    for letter in source:
        survivor += letter
        while True:
            match = None
            for index, spell in enumerate(spells):
                if survivor.endswith(spell):
                    if match is None or index < match[0]:
                        match = (index, len(spell))
            if match is None:
                break
            survivor = survivor[:-match[1]]
    return survivor + "\n"


SAMPLE = """KUKUKAKIKUKAKEKKUKAKAKKUKAKUKAKU
2
KEK
UK
"""
SAMPLE_OUT = "KAKIKAKAKAKKAKAKU\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("HEATHLEDGER\n2\nHEATH\nLEDGER\n") == "\n"
assert oracle("KAPKAPPAPAK\n1\nKAPPA\n") == "K\n"
assert oracle("CABAI\n3\nABA\nAB\nB\n") == "CAI\n"
assert oracle("AAAA\n2\nAA\nA\n") == "\n"
assert oracle("ABC\n1\nZZZ\n") == "ABC\n"


def write(name, source, spells):
    text = source + "\n" + str(len(spells)) + "\n" + "".join(spell + "\n" for spell in spells)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "ABCDEF", ["ZZ", "QQ", "DEF"])
    write("3_wide", "ABABABABABABABABABAB" * 40, ["AB", "BA", "ABA", "BAB", "AAB"])
    rng = random.Random(20261126)
    alphabet = "ABCDE"
    source = "".join(rng.choice(alphabet) for _ in range(600))
    spells = ["".join(rng.choice(alphabet) for _ in range(rng.randrange(1, 6)))
              for _ in range(30)]
    write("4_random", source, spells)
    alphabet = "ABCDEFGH"
    source = "".join(rng.choice(alphabet) for _ in range(20000))
    spells = ["".join(rng.choice(alphabet) for _ in range(rng.randrange(1, 5)))
              for _ in range(10)]
    write("5_io", source, spells)
    big_source = "".join(rng.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ") for _ in range(100000))
    big_spells = ["".join(rng.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ") for _ in range(rng.randrange(1, 101)))
                  for _ in range(100)]
    Path("/tmp/BLHETA_big.txt").write_text(
        big_source + "\n" + str(len(big_spells)) + "\n" +
        "".join(spell + "\n" for spell in big_spells))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "KUKUKAKIKUKAKEKKUKAKAKKUKAKUKAKU", ["KEK", "UK"])
build()
