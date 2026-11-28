#!/usr/bin/env python3
import os
import random

def subtractStrings(bigText, smallText):
    bigDigits = [int(ch) for ch in bigText][::-1]
    smallDigits = [int(ch) for ch in smallText][::-1]
    borrow = 0
    resultDigits = []
    idx = 0
    while idx < len(bigDigits):
        digit = bigDigits[idx] - borrow - (smallDigits[idx] if idx < len(smallDigits) else 0)
        borrow = 0
        if digit < 0:
            digit += 10
            borrow = 1
        resultDigits.append(digit)
        idx += 1
    while len(resultDigits) > 1 and resultDigits[-1] == 0:
        resultDigits.pop()
    return "".join(str(d) for d in resultDigits[::-1])

def stripLeadingZeros(text):
    stripped = text.lstrip("0")
    return stripped if stripped else "0"

def stepString(numberText):
    lastDigit = numberText[-1]
    truncated = stripLeadingZeros(numberText[:-1])
    return subtractStrings(truncated, lastDigit)

def divisibleByEleven(numberText):
    alternating = 0
    for position, ch in enumerate(reversed(numberText)):
        if position % 2 == 0:
            alternating += int(ch)
        else:
            alternating -= int(ch)
    return alternating % 11 == 0

def oracle(data_bytes):
    lines = data_bytes.decode("latin-1").split("\n")
    blocks = []
    for line in lines:
        numberText = line.strip()
        if not numberText:
            continue
        if numberText == "0":
            break
        current = numberText
        stepLines = [current]
        while len(current) > 2:
            current = stepString(current)
            stepLines.append(current)
        if divisibleByEleven(current):
            verdict = "El numero " + numberText + " es divisible por 11."
        else:
            verdict = "El numero " + numberText + " no es divisible por 11."
        blocks.append("\n".join(stepLines) + "\n" + verdict + "\n")
    return "\n".join(blocks) + ("\n" if blocks else "")

assert stepString("121") == "11"
assert stepString("12345678901234567900") == "1234567890123456790"
assert divisibleByEleven("11")
assert not divisibleByEleven("87")
assert not divisibleByEleven("89624556")

sample_in = "12345678901234567900\n896245630004\n0\n"
sample_out = (
    "12345678901234567900\n1234567890123456790\n123456789012345679\n"
    "12345678901234558\n1234567890123447\n123456789012337\n"
    "12345678901226\n1234567890116\n123456789005\n12345678895\n"
    "1234567884\n123456784\n12345674\n1234563\n123453\n12342\n"
    "1232\n121\n11\nEl numero 12345678901234567900 es divisible por 11.\n"
    "\n"
    "896245630004\n89624562996\n8962456293\n896245626\n89624556\n"
    "8962449\n896235\n89618\n8953\n892\n87\n"
    "El numero 896245630004 no es divisible por 11.\n"
    "\n"
)
assert oracle(sample_in.encode("latin-1")) == sample_out

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

def emit(name, text_in):
    text_out = oracle(text_in.encode("latin-1"))
    with open("in/" + name + ".txt", "wb") as f:
        f.write(text_in.encode("latin-1"))
    with open("out/" + name + ".out", "wb") as f:
        f.write(text_out.encode("latin-1"))

emit("1_sample", sample_in)
emit("2_edges", "11\n10\n100\n121\n0\n")

rng = random.Random(5)
def random_number_text(maxDigits):
    digits = rng.randint(1, maxDigits)
    return str(rng.randint(10 ** (digits - 1), 10 ** digits - 1)) + "\n"

wide_text = "".join(random_number_text(50) for _ in range(200)) + "0\n"
emit("3_wide", wide_text)
emit("4_random", "".join(random_number_text(rng.randint(1, 50)) for _ in range(500)) + "0\n")
io_text = "".join(random_number_text(50) for _ in range(2000)) + "0\n"
emit("5_io", io_text)

print("gen ok")
