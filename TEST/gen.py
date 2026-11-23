import os

STOP = "42"


def write(name, lines):
    with open(f"in/{name}.txt", "w") as f:
        f.write("".join(x + "\n" for x in lines))
    keep = []
    for x in lines:
        if x == STOP:
            break
        keep.append(x + "\n")
    with open(f"out/{name}.out", "w") as f:
        f.write("".join(keep))


os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

write("1_sample", ["1", "2", "88", "42", "99"])
write("2_edges", ["42"])
write("3_wide", ["a" * 900, "42", "more"])
write("4_lines", [str(i) for i in range(1, 20001)] + ["42"] + ["tail"] * 5000)
write("5_io", [("n" * 40) for _ in range(200000)] + ["42"] + ["x"] * 1000)

print("generated TEST cases")
