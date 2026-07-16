import os
import glob

files = glob.glob("Vayl/Features/Onboarding/Canvas/TableSurface/*.swift")
for file in files:
    with open(file, 'r') as f:
        content = f.read()
    
    # fix private extension
    content = content.replace("private extension TableSurfaceView", "extension TableSurfaceView")
    
    # fix private func in Math
    if "TableSurfaceMath.swift" in file:
        content = content.replace("private func", "func")
    
    with open(file, 'w') as f:
        f.write(content)
