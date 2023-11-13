with open("path.txt") as file:
    nodes = file.read().split("\n")

nodes_100 = nodes[::len(nodes)//100+1]

with open("100nodes.csv", "w") as file:
    file.write("\n".join(nodes_100))