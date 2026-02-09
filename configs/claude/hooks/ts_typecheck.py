#!/usr/bin/env python3

import json
import sys
import subprocess
from pathlib import Path


def main():
    try:
        # Read input data from stdin
        input_data = json.load(sys.stdin)

        tool_input = input_data.get("tool_input", {})

        # Get file path from tool input
        file_path = tool_input.get("file_path")
        if not file_path:
            sys.exit(0)

        # Only check TypeScript files
        if not file_path.endswith((".ts", ".tsx")):
            sys.exit(0)

        # Check if file exists
        if not Path(file_path).exists():
            sys.exit(0)

        # Get the project root (look for tsconfig.json)
        current_path = Path(file_path).parent
        project_root = None

        while current_path != current_path.parent:
            if (current_path / "tsconfig.json").exists():
                project_root = current_path
                break
            current_path = current_path.parent

        if not project_root:
            # No tsconfig.json found, skip type checking
            sys.exit(0)

        # Run TypeScript compiler to check for type errors
        try:
            result = subprocess.run(
                ["bun", "tsc", "--noEmit", "--pretty", "false"],
                cwd=project_root,
                capture_output=True,
                text=True,
                timeout=60,
            )

            if result.returncode != 0 and result.stdout:
                # Filter errors for the specific file we're checking
                error_lines = result.stdout.strip().split("\n")
                file_errors = [
                    line
                    for line in error_lines
                    if file_path in line or line.startswith(" ")
                ]

                if file_errors:
                    # Log the error for debugging
                    log_file = Path(__file__).parent.parent / "typescript_errors.json"
                    error_output = "\n".join(file_errors)
                    error_entry = {
                        "file_path": file_path,
                        "errors": error_output,
                        "session_id": input_data.get("session_id"),
                    }

                    # Load existing errors or create new list
                    if log_file.exists():
                        with open(log_file, "r") as f:
                            errors = json.load(f)
                    else:
                        errors = []

                    errors.append(error_entry)

                    # Save errors
                    with open(log_file, "w") as f:
                        json.dump(errors, f, indent=2)

                    # Send error message to stderr for LLM to see
                    print(f"TypeScript errors found in {file_path}:", file=sys.stderr)
                    print(error_output, file=sys.stderr)

                    # Exit with code 2 to signal LLM to correct
                    sys.exit(2)

        except subprocess.TimeoutExpired:
            print("TypeScript check timed out", file=sys.stderr)
            sys.exit(0)
        except FileNotFoundError:
            # TypeScript not available, skip check
            sys.exit(0)

    except json.JSONDecodeError as e:
        print(f"Error parsing JSON input: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error in typescript hook: {e}", file=sys.stderr)
        sys.exit(1)


main()
