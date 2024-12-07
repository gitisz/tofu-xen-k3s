#!/usr/bin/env python3
import sys
import json

def calculate_next_ip(start_ip, increment):
    # Split IP into octets
    octets = list(map(int, start_ip.split('.')))

    # Add increment to last octet
    octets[3] += increment

    # Handle carrying over to other octets
    for i in range(3, 0, -1):
        if octets[i] > 255:
            octets[i-1] += octets[i] // 256
            octets[i] = octets[i] % 256

    # Return formatted IP
    return '.'.join(map(str, octets))

if __name__ == "__main__":
    try:
        # Read JSON input from stdin
        query = json.load(sys.stdin)
        start_ip = query["start_ip"]
        increment = int(query["increment"])

        # Calculate the next IP
        next_ip = calculate_next_ip(start_ip, increment)

        # Return result as JSON
        print(json.dumps({"next_ip": next_ip}))
    except Exception as e:
        sys.stderr.write(f"Error: {e}\n")
        sys.exit(1)