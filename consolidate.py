import os

base_dir = "Vayl/Features/Onboarding/Canvas"
files_to_merge = [
    "TableSurface/TableSurface+Atmosphere.swift",
    "TableSurface/TableSurface+Felt.swift",
    "TableSurface/TableSurface+Vignette.swift",
    "TableSurface/TableSurface+TopoLines.swift",
    "TableSurface/TableSurface+Compass.swift",
    "TableSurface/TableSurface+AmberPool.swift",
    "TableSurface/TableSurface+SpectrumRim.swift"
]

main_file = os.path.join(base_dir, "TableSurfaceView.swift")

with open(main_file, "r") as f:
    main_content = f.read()

combined_content = main_content.strip() + "\n\n"

for file in files_to_merge:
    path = os.path.join(base_dir, file)
    with open(path, "r") as f:
        content = f.read()
    
    # Strip headers
    lines = content.split("\n")
    cleaned_lines = []
    skip = True
    for line in lines:
        if line.startswith("import SwiftUI"):
            skip = False
            continue
        if not skip:
            cleaned_lines.append(line)
            
    content = "\n".join(cleaned_lines).strip()
    # Change "extension" back to "private extension"
    content = content.replace("extension TableSurfaceView", "private extension TableSurfaceView")
    combined_content += content + "\n\n"

with open(main_file, "w") as f:
    f.write(combined_content)

# Delete the merged files
for file in files_to_merge:
    os.remove(os.path.join(base_dir, file))

print("Consolidation complete.")
