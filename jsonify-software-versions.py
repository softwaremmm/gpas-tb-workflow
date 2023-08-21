'''Very simple script for parsing the software versions file into JSON.
To be used by CI/CD
'''
import json
import sys

from collections import defaultdict

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Incorrect usage!")
        print("Try `python3 jsonify-software-version.py <path to software versions>")
        sys.exit(0)
    
    software_versions_path = sys.argv[1]
    with open(software_versions_path) as f:
        data = [line.replace("\n", "") for line in f]

    # Expected format. Line separated values of:
    # <container name> --> <command to get software version> --> <software version>
    data = [line.split(" --> ") for line in data]

    # This should be written as a JSON of:
    # {
    #   <container>: {
    #       <command>: <version>
    #   }
    # }
    json_data = defaultdict(dict)
    for container, software, version in data:
        json_data[container][software] = version
    
    #Actually do the writing
    with open("software-versions.json", "w") as f:
        f.write(json.dumps(json_data, indent=2))







