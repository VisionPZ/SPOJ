#!/usr/bin/env python3
import sys


def main():
    raw_tokens = sys.stdin.buffer.read().decode("utf-8", "ignore").split()
    values = [int(token) for token in raw_tokens[:6]]
    while len(values) < 6:
        values.append(0)
    total_cost = sum(values)
    sys.stdout.write(str(total_cost / 6.0) + "\n")


main()
