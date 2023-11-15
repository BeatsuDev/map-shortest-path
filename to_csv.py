with open("maps/norden/noder.txt") as file:
    nodes = file.read().split("\n")

nodes = [node.split() for node in nodes[1:]]
less_nodes = nodes[100::len(nodes)//2000 + 1]

with open("nodes.csv", "w") as file:
    file.write("id,latitude,longitude\n")
    file.write("\n".join(",".join(line) for line in less_nodes))