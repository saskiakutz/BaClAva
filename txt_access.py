d = {}
with open("sim_params.txt") as f:
    for line in f:
        line_entry = line.rsplit("\n")
        (key, val) = line_entry[0].split("=")
        d[key] = val

d["name"] = "test"

entry_folder_name = "simulation"

d["name"] = entry_folder_name

print(d)
with open("simulation_1.txt", "w") as f:
    f.write(d)
