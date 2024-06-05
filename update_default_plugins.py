import sys
import json


def update(file_path, plugins_str):
    with open(file_path, 'r') as file:
        data = file.read()

    try:
        json_data = json.loads(data)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON file: {e}")
        sys.exit(1)

    if 'plugins' not in json_data:
        print(f"Error no plugins array:")
        sys.exit(1)

    plugins = plugins_str.split(',')
    for plugin in plugins:
        if plugin not in json_data['plugins']:
            json_data['plugins'].append(plugin)

    with open(file_path, 'w') as file:
        json.dump(json_data, file, indent=4)

    print(f"Plugins have been added to {file_path}")


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python script.py file_path plugins_str")
        sys.exit(1)

    file_path = sys.argv[1]
    plugins_str = sys.argv[2]

    update(file_path, plugins_str)
