#!/usr/bin/env python3
import random
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = (
    "2\n"
    "4\n"
    "MeksisPrepaid 1 30.00 SR\n"
    "JatiRice 1 32.00 ZR\n"
    "RybenaJuice 2 18.00 SR\n"
    "PeanutButter 5 4.50 SR\n"
    "3\n"
    "GardenihaBread 3 2.40 ZR\n"
    "WaterSpinach 5 1.10 ZR\n"
    "iPong6 1 2779.00 SR\n"
)
SAMPLE_OUTPUT = (
    "Case #1:\n"
    "Total Amount Include GST: 125.81\n"
    "Total Amount GST Paid: 5.31\n"
    "Case #2:\n"
    "Total Amount Include GST: 2958.44\n"
    "Total Amount GST Paid: 166.74\n"
)

CENT = Decimal("0.01")
STANDARD_RATE = Decimal("1.06")


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    result = []
    for case_number in range(1, case_count + 1):
        item_count = int(tokens[cursor])
        cursor += 1
        amount_with_gst = Decimal("0")
        amount_of_gst = Decimal("0")
        for _ in range(item_count):
            item_name = tokens[cursor]
            cursor += 1
            quantity = int(tokens[cursor])
            cursor += 1
            price = Decimal(tokens[cursor])
            cursor += 1
            rate = tokens[cursor]
            cursor += 1
            subtotal = price * quantity
            if rate == "SR":
                included = (subtotal * STANDARD_RATE).quantize(
                    CENT, rounding=ROUND_HALF_UP)
                tax = included - subtotal
            else:
                included = subtotal
                tax = Decimal("0")
            amount_with_gst += included
            amount_of_gst += tax
        result.append(
            f"Case #{case_number}:\n"
            f"Total Amount Include GST: {amount_with_gst:.2f}\n"
            f"Total Amount GST Paid: {amount_of_gst:.2f}")
    return "\n".join(result) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n1\nItem 1 10.00 SR\n") == (
    "Case #1:\nTotal Amount Include GST: 10.60\n"
    "Total Amount GST Paid: 0.60\n")
assert oracle("1\n1\nItem 1 10.00 ZR\n") == (
    "Case #1:\nTotal Amount Include GST: 10.00\n"
    "Total Amount GST Paid: 0.00\n")
assert oracle("1\n2\nA 3 4.50 SR\nB 1 2.00 ZR\n") == (
    "Case #1:\nTotal Amount Include GST: 16.31\n"
    "Total Amount GST Paid: 0.81\n")
assert oracle("1\n1\nItem 1 1.01 SR\n") == (
    "Case #1:\nTotal Amount Include GST: 1.07\n"
    "Total Amount GST Paid: 0.06\n")


def write(name, cases):
    lines = [str(len(cases))]
    for items in cases:
        lines.append(str(len(items)))
        lines.extend(f"{item_name} {quantity} {price} {rate}"
                     for item_name, quantity, price, rate in items)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", [
    [("MeksisPrepaid", 1, "30.00", "SR"), ("JatiRice", 1, "32.00", "ZR"),
     ("RybenaJuice", 2, "18.00", "SR"), ("PeanutButter", 5, "4.50", "SR")],
    [("GardenihaBread", 3, "2.40", "ZR"),
     ("WaterSpinach", 5, "1.10", "ZR"), ("iPong6", 1, "2779.00", "SR")],
])
write("2_edges", [
    [("Solo", 1, "0.01", "SR")],
    [("Zero", 999, "0.00", "ZR")],
    [("Huge", 100000, "999999.99", "SR")],
    [("Mixed", 3, "3.33", "SR"), ("Plain", 7, "7.77", "ZR")],
])
random.seed(2026)
write("3_wide", [
    [(f"Item{item_index}", random.randint(1, 1000),
      f"{random.randint(0, 999999)}.{random.randint(0, 99):02d}",
      random.choice(["SR", "ZR"])) for item_index in range(200)]
    for _ in range(20)
])
write("4_random", [
    [(f"Product{item_index}", random.randint(1, 50),
      f"{random.randint(1, 5000)}.{random.randint(0, 99):02d}",
      random.choice(["SR", "ZR"])) for item_index in range(random.randint(1, 12))]
    for _ in range(100)
])
write("5_io", [
    [(f"Good{item_index}", random.randint(1, 100),
      f"{random.randint(1, 100000)}.{random.randint(0, 99):02d}",
      random.choice(["SR", "ZR"])) for item_index in range(20000)]
])
