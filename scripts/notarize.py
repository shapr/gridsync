#!/usr/bin/env python3
# This script assumes/requires credentials stored in a keychain profile.
# To store credentials in a keychain profile programmatically:
# xcrun notarytool store-credentials <PROFILE-NAME> [--apple-id <APPLE-ID>] [--team-id <TEAM-ID>] [--password <APP-SPECIFIC-PASSWORD>]
# Sources/references:
# https://developer.apple.com/documentation/xcode/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow
# https://stackoverflow.com/questions/56890749/macos-notarize-in-script/56890758#56890758
import hashlib
import json
import os
import sys
from configparser import RawConfigParser
from pathlib import Path
from secrets import compare_digest
from subprocess import CalledProcessError, SubprocessError, run
from time import sleep
from typing import Optional


def sha256sum(filepath):
    hasher = hashlib.sha256()
    with open(filepath, "rb") as f:
        for block in iter(lambda: f.read(4096), b""):
            hasher.update(block)
    return hasher.hexdigest()


def make_zipfile(src_path: str, dst_path: str) -> None:
    run(["ditto", "-c", "-k", "--keepParent", src_path, dst_path])


def staple(path: str) -> None:
    run(["xcrun", "stapler", "staple", path], check=True)


def store_credentials(
    apple_id: str, password: str, team_id: str, keychain_profile: str
) -> None:
    run(
        [
            "xcrun",
            "notarytool",
            "store-credentials",
            "--apple-id",
            apple_id,
            "--password",
            password,
            "--team-id",
            team_id,
            keychain_profile,
        ]
    )


def notarytool(
    subcommand: str, args: list[str], keychain_profile: str
) -> dict[str, str]:
    proc = run(
        [
            "xcrun",
            "notarytool",
            subcommand,
            f"--keychain-profile={keychain_profile}",
            "--output-format=json",
        ]
        + args,
        capture_output=True,
        text=True,
    )
    if proc.returncode:
        raise SubprocessError(proc.stderr.strip())
    if proc.stdout:
        result = json.loads(proc.stdout.strip())
    else:
        return {}
    message = result.get("message")
    if message:
        print("###", message)
    return result


def submit(filepath: str, keychain_profile: str) -> str:  # submission-id
    result = notarytool("submit", [filepath], keychain_profile)
    return result["id"]


def wait(submission_id: str, keychain_profile: str) -> str:
    result = notarytool("wait", [submission_id], keychain_profile)
    return result["status"]


def log(submission_id: str, keychain_profile: str) -> dict[str, str]:
    result = notarytool("log", [submission_id], keychain_profile)
    return result


def main(path: str, keychain_profile: str) -> None:
    if not path.lower().endswith(".dmg") and not path.lower().endswith(".zip"):
        print("Creating ZIP archive...")
        submission_path = path + ".zip"
        make_zipfile(path, submission_path)
    else:
        submission_path = path
    submitted_hash = sha256sum(submission_path)
    print(f"Uploading {submission_path} ({submitted_hash})...")
    submission_id = submit(submission_path, keychain_profile)
    print("Waiting for result...")
    status = wait(submission_id, keychain_profile)
    result = log(submission_id, keychain_profile)
    print(json.dumps(result, sort_keys=True, indent=2))
    if status != "Accepted":
        sys.exit(f'ERROR: Notarization failed; status: "{status}"')
    notarized_hash = result["sha256"]
    if not compare_digest(submitted_hash, notarized_hash):
        sys.exit(
            "ERROR: SHA-256 hash mismatch\n"
            f"Submitted: {submitted_hash}\n"
            f"Notarized: {submitted_hash}"
        )
    staple(path)
    print("Success!")


if __name__ == "__main__":
    path = sys.argv[1]
    try:
        main(path, "gridsync")
    except Exception as e:
        sys.exit(str(e))
