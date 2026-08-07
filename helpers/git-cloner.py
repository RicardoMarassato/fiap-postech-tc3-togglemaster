""" Simple script to clone all application repositories using GitHub CLI"""

import subprocess
import sys

ORGANIZATION = "FIAP-TCs"

REPOS = (
    "evaluation-service",
    "analytics-service",
    "targeting-service",
    "flag-service",
    "auth-service",
)


def clone_repositories():
    for repo in REPOS:
        repo_path = f"{ORGANIZATION}/{repo}"
        print(f"Cloning: {repo_path}")

        try:
            subprocess.run(["gh", "repo", "clone", repo_path], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error cloning {repo}: {e}", file=sys.stderr)
        except FileNotFoundError:
            print(
                "Error: 'gh' CLI not found. Make sure GitHub CLI is installed and in your PATH.",
                file=sys.stderr,
            )
            return


if __name__ == "__main__":
    clone_repositories()
