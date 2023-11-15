Insert maps here as folders. E.g. `maps/norden/<map files>.txt`.

You must have a file named `noder.txt` formatted: `<node_id> <node_lat> <node_lon>\n`.

A file named: `kanter.txt` formatted: `<from_node_id>\t<to_node_id>\t<drive_time>\t<length>\t<speed_limit>\n`.

The drive time is in hundreds of seconds, the length in meters and the speed limit in km/h.

Both files require the node count and the edge count to be the first line in each file respectively. The program assumes node IDs begin at 0 and are in a continuous range.

Data can be fetched from OpenStreetMaps, but I believe it might need to be preprocessed to conform to the format described above. The files were unfortunately too big to be uploaded to GitHub, but maybe I will manage to upload them with git LFS.
