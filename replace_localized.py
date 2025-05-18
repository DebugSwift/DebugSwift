import os
import re

def load_localizations(strings_path):
    localizations = {}
    pattern = re.compile(r'"([^"]+)"\s*=\s*"([^"]*)";')
    with open(strings_path, 'r', encoding='utf-8') as f:
        for line in f:
            match = pattern.match(line.strip())
            if match:
                key, value = match.groups()
                localizations[key] = value
    return localizations

def replace_localized_in_file(file_path, localizations):
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    def replacer(match):
        key = match.group(1)
        return f'"{localizations.get(key, key)}"'

    # Replace "key".localized() with the localized value in quotes
    new_content = re.sub(r'"([^"]+)"\.localized\(\)', replacer, content)

    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(new_content)
        print(f"Updated: {file_path}")

def process_directory(root_dir, localizations):
    for subdir, _, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.swift'):
                file_path = os.path.join(subdir, file)
                print(f"Checking: {file_path}")
                replace_localized_in_file(file_path, localizations)

if __name__ == "__main__":
    # Path to your Localizable.strings file
    strings_path = os.path.join("DebugSwift", "Resources", "en.lproj", "Localizable.strings")
    localizations = load_localizations(strings_path)
    process_directory(".", localizations) 