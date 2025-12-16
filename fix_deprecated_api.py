#!/usr/bin/env python3
"""
Script to replace deprecated Flutter .withOpacity() with .withValues()
"""
import os
import re
import sys

def replace_with_opacity(file_path):
    """Replace .withOpacity() with .withValues() in a Dart file"""
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        original_content = content
        
        # Pattern to match: Colors.color.withOpacity(0.5) -> Colors.color.withValues(alpha: 0.5)
        # Also matches: someColor.withOpacity(0.3)
        pattern = r'(\w+(?:\.\w+)*?)\.withOpacity\((\d+\.?\d*)\)'
        replacement = r'\1.withValues(alpha: \2)'
        
        content = re.sub(pattern, replacement, content)
        
        if content != original_content:
            with open(file_path, 'w') as f:
                f.write(content)
            return True
        return False
    except Exception as e:
        print(f"Error processing {file_path}: {e}", file=sys.stderr)
        return False

def process_directory(directory):
    """Process all .dart files in a directory recursively"""
    files_modified = 0
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                if replace_with_opacity(file_path):
                    print(f"Updated: {file_path}")
                    files_modified += 1
    
    return files_modified

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 fix_deprecated_api.py <directory>")
        sys.exit(1)
    
    directory = sys.argv[1]
    
    if not os.path.isdir(directory):
        print(f"Error: {directory} is not a valid directory")
        sys.exit(1)
    
    print(f"Processing directory: {directory}")
    count = process_directory(directory)
    print(f"\nTotal files modified: {count}")
