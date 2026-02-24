# collect_md_sh.py
# Searches all folders/subfolders for .md and .sh files and consolidates their content into a single .txt file

import os
import sys
import time

script_dir = os.path.dirname(os.path.abspath(__file__))
output_file = os.path.join(script_dir, "collected_files.txt")

print()
print("  Scanning C:\\ for .md and .sh files...")
print("  Please wait, this may take a while...")
print()

# Collect all .md and .sh files
files = []
for root, dirs, filenames in os.walk("C:\\"):
    for name in filenames:
        if name.lower().endswith((".md", ".sh")):
            full_path = os.path.join(root, name)
            if os.path.abspath(full_path) != os.path.abspath(output_file):
                files.append(full_path)

total_files = len(files)
errors = 0
start_time = time.time()

print(f"  Found {total_files} files. Processing...")
print()

with open(output_file, "w", encoding="utf-8") as out:
    for current, file_path in enumerate(files, 1):
        percent = round((current / total_files) * 100) if total_files else 0
        name = os.path.basename(file_path)

        # Progress bar
        bar_length = 30
        filled = round(bar_length * current / total_files) if total_files else 0
        empty = bar_length - filled
        bar = "[" + "█" * filled + "░" * empty + "]"

        print(f"\r  {bar} {percent}% ({current}/{total_files}) Processing: {name:<60}", end="", flush=True)

        separator = "=" * 80
        out.write(f"{separator}\nFILE: {name}\nPATH: {file_path}\n{separator}\n")

        try:
            with open(file_path, "r", encoding="utf-8", errors="replace") as f:
                content = f.read()
            out.write(content)
        except Exception as e:
            errors += 1
            out.write(f"[ERROR: Could not read file - {e}]")

        out.write("\n\n")

elapsed = time.time() - start_time
minutes, seconds = divmod(int(elapsed), 60)

print()
print()
print("  ============================================")
print("  COMPLETED")
print("  ============================================")
print(f"    Files processed : {total_files}")
print(f"    Errors          : {errors}")
print(f"    Time elapsed    : {minutes:02d}:{seconds:02d}")
print(f"    Output saved to : {output_file}")
print("  ============================================")
print()

input("  Press Enter to exit")