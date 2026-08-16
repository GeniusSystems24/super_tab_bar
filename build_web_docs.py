from __future__ import annotations

from pathlib import Path
import os
import re
import shutil
import subprocess
import sys


ROOT_DIR = Path(__file__).resolve().parent
PUBSPEC_FILE = ROOT_DIR / "pubspec.yaml"
EXAMPLE_DIR = ROOT_DIR / "example"
BUILD_WEB_DIR = EXAMPLE_DIR / "build" / "web"
DOCS_DIR = ROOT_DIR / "docs"


def error(message: str, code: int = 1) -> None:
    print(f"\nERROR: {message}")
    sys.exit(code)


def get_package_name() -> str:
    if not PUBSPEC_FILE.exists():
        error(f"pubspec.yaml not found:\n{PUBSPEC_FILE}")

    content = PUBSPEC_FILE.read_text(encoding="utf-8")

    match = re.search(
        r"(?m)^\s*name\s*:\s*['\"]?([A-Za-z0-9_]+)['\"]?\s*(?:#.*)?$",
        content,
    )

    if not match:
        error("Could not read package name from pubspec.yaml.")

    return match.group(1)


def get_flutter_path() -> Path:
    # 1) Explicit path has highest priority.
    custom = os.environ.get("FLUTTER_BIN", "").strip().strip('"')

    if custom:
        flutter_path = Path(custom)

        print(f"FLUTTER_BIN  : {flutter_path}")

        if not flutter_path.is_file():
            error(
                "FLUTTER_BIN is set, but the file does not exist:\n"
                f"{flutter_path}"
            )

        return flutter_path.resolve()

    # 2) Otherwise search Windows/PATH.
    names = ["flutter.bat", "flutter.cmd", "flutter"] if os.name == "nt" else ["flutter"]

    for name in names:
        found = shutil.which(name)
        if found:
            return Path(found).resolve()

    error(
        "Flutter was not found.\n\n"
        "Set FLUTTER_BIN explicitly in PowerShell, for example:\n"
        r'$env:FLUTTER_BIN="G:\Libraries\flutter\bin\flutter.bat"' + "\n"
        "py build_web_docs.py"
    )


def build_web(flutter_path: Path, package_name: str) -> None:
    if not EXAMPLE_DIR.is_dir():
        error(f"example directory not found:\n{EXAMPLE_DIR}")

    if not (EXAMPLE_DIR / "pubspec.yaml").is_file():
        error(f"example/pubspec.yaml not found:\n{EXAMPLE_DIR / 'pubspec.yaml'}")

    base_href = f"/{package_name}/"

    args = [
        "build",
        "web",
        "--release",
        "--base-href",
        base_href,
    ]

    print("=" * 72)
    print(f"Package name : {package_name}")
    print(f"Base href    : {base_href}")
    print(f"Flutter      : {flutter_path}")
    print(f"Working dir  : {EXAMPLE_DIR}")
    print("=" * 72)

    print("\nRunning:")
    print(f'"{flutter_path}" ' + " ".join(args))
    print()

    try:
        if os.name == "nt":
            # Reliable way to execute flutter.bat on Windows.
            command = subprocess.list2cmdline([str(flutter_path), *args])

            subprocess.run(
                ["cmd.exe", "/d", "/s", "/c", command],
                cwd=str(EXAMPLE_DIR),
                check=True,
            )
        else:
            subprocess.run(
                [str(flutter_path), *args],
                cwd=str(EXAMPLE_DIR),
                check=True,
            )

    except subprocess.CalledProcessError as exc:
        error(
            f"Flutter build failed with exit code {exc.returncode}.",
            exc.returncode,
        )


def copy_build_to_docs() -> None:
    if not BUILD_WEB_DIR.is_dir():
        error(f"Build output not found:\n{BUILD_WEB_DIR}")

    print("\nCopying build output to docs...")

    if DOCS_DIR.exists():
        shutil.rmtree(DOCS_DIR)

    shutil.copytree(BUILD_WEB_DIR, DOCS_DIR)

    print(f"Source : {BUILD_WEB_DIR}")
    print(f"Target : {DOCS_DIR}")


def main() -> None:
    package_name = get_package_name()
    flutter_path = get_flutter_path()

    build_web(flutter_path, package_name)
    copy_build_to_docs()

    print("\n" + "=" * 72)
    print("SUCCESS")
    print("=" * 72)
    print(f"Package   : {package_name}")
    print(f"Base href : /{package_name}/")
    print(f"Docs      : {DOCS_DIR}")


if __name__ == "__main__":
    main()
