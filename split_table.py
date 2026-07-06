import os
import re

file_path = "Vayl/Features/Onboarding/Canvas/TableSurfaceView.swift"
with open(file_path, "r") as f:
    content = f.read()

# We want to split the file by MARKs.
# A MARK looks like `// MARK: — Pure Math Helpers`
marks = re.split(r'// MARK: — (.*)', content)

# marks[0] is the header
header = marks[0]

sections = {}
for i in range(1, len(marks), 2):
    sections[marks[i].strip()] = marks[i+1]

out_dir = "Vayl/Features/Onboarding/Canvas/TableSurface"
os.makedirs(out_dir, exist_ok=True)

def write_file(filename, content):
    with open(os.path.join(out_dir, filename), "w") as f:
        f.write("//\n//  " + filename + "\n//  Vayl\n//\nimport SwiftUI\n\n" + content.strip() + "\n")

# Math
write_file("TableSurfaceMath.swift", sections["Pure Math Helpers"])

# TableSurfaceView - we will overwrite the original file with just the struct
main_content = header + "// MARK: — TableSurfaceView\n" + sections["TableSurfaceView"].strip() + "\n\n// MARK: — Preview\n" + sections["Preview"].strip() + "\n"
with open(file_path, "w") as f:
    f.write(main_content)

# Layers
write_file("TableSurface+Atmosphere.swift", sections["Layer 0: Upper Void Atmosphere"])
write_file("TableSurface+Felt.swift", sections["Layer 1: Felt Fill"])
write_file("TableSurface+Vignette.swift", sections["Layer 2: Vignette"])
write_file("TableSurface+TopoLines.swift", sections["Layer 3: Topo Lines"] + "\n\n// MARK: - Dissolution SDF Helpers\n\n" + sections["Dissolution SDF Helpers"])
write_file("TableSurface+Compass.swift", sections["Layer 4: Compass Star"])
write_file("TableSurface+AmberPool.swift", sections["Layer 5: Amber Overhead Pool"])
write_file("TableSurface+SpectrumRim.swift", sections["Layer 6: Spectrum Rim"])

print("Done splitting TableSurfaceView.swift")
