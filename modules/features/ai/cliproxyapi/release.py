#!/usr/bin/env python3
# Copyright (c) 2026 rice-cliproxyapi.
"""Dynamic release installer, updater, and execution wrapper for CLIProxyAPI."""

from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.error
import urllib.request
from collections.abc import Sequence
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import Generator, Literal

REPOSITORY: str = "router-for-me/CLIProxyAPI"
BINARY_NAME: str = "cli-proxy-api"
CHECKSUMS_FILE: str = "checksums.txt"
GITHUB_BASE: str = "https://github.com"
COMPONENT_PATTERN: str = r"^[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)*$"
DEFAULT_TIMEOUT_SEC: float = 60.0
LOCK_FILE_NAME: str = ".install.lock"
RECEIPT_FILE_NAME: str = "receipt.json"
CURRENT_LINK_NAME: str = "current"
VERSIONS_DIR_NAME: str = "versions"
EXECUTABLE_MODE: int = 0o755


class ReleaseError(Exception):
    """Base error for release installation and execution operations."""


@dataclass(frozen=True, slots=True)
class TargetPlatform:
    os: Literal["linux", "darwin"]
    arch: Literal["amd64", "arm64"]

    @property
    def key(self) -> str:
        return f"{self.os}-{self.arch}"

    @property
    def asset_name_template(self) -> str:
        arch_tag = "aarch64" if self.arch == "arm64" else "amd64"
        return f"CLIProxyAPI_{{version}}_{self.os}_{arch_tag}.tar.gz"


def normalize_platform(value: str | None) -> TargetPlatform:
    if value is not None and value.strip():
        val = value.strip().lower().replace("_", "-")
        parts = val.split("-")
        if len(parts) == 2:
            os_part, arch_part = parts
            if os_part in ("linux", "darwin"):
                if arch_part in ("amd64", "x86_64", "x64"):
                    return TargetPlatform(os=os_part, arch="amd64")
                if arch_part in ("arm64", "aarch64"):
                    return TargetPlatform(os=os_part, arch="arm64")
        raise ReleaseError(f"unsupported target platform: {value!r}")

    system = platform.system().lower()
    if system not in ("linux", "darwin"):
        raise ReleaseError(f"unsupported host operating system: {system!r}")
    target_os: Literal["linux", "darwin"] = "linux" if system == "linux" else "darwin"

    machine = platform.machine().lower()
    if machine in ("x86_64", "amd64", "x64"):
        return TargetPlatform(os=target_os, arch="amd64")
    if machine in ("arm64", "aarch64"):
        return TargetPlatform(os=target_os, arch="arm64")
    raise ReleaseError(f"unsupported host architecture: {machine!r}")


def validate_version_string(version: str) -> str:
    cleaned = version.strip().removeprefix("v")
    if (
        not cleaned
        or cleaned in (".", "..")
        or "/" in cleaned
        or "\\" in cleaned
        or re.fullmatch(COMPONENT_PATTERN, cleaned) is None
    ):
        raise ReleaseError(f"invalid version string: {version!r}")
    return cleaned


@contextmanager
def file_lock(lock_path: Path) -> Generator[None, None, None]:
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    with lock_path.open("a+", encoding="utf-8") as lock_file:
        try:
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
            yield
        finally:
            try:
                fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)
            except OSError:
                pass


class NoRedirectHandler(urllib.request.HTTPRedirectHandler):
    def redirect_request(
        self,
        req: urllib.request.Request,
        fp: object,
        code: int,
        msg: str,
        headers: object,
        newurl: str,
    ) -> None:
        return None


def resolve_latest_version(repository: str, timeout_sec: float) -> str:
    url = f"{GITHUB_BASE}/{repository}/releases/latest"
    opener = urllib.request.build_opener(NoRedirectHandler)
    req = urllib.request.Request(url, headers={"User-Agent": "rice-cliproxyapi/1.0"})
    try:
        with opener.open(req, timeout=timeout_sec) as resp:
            loc = resp.headers.get("Location")
    except urllib.error.HTTPError as err:
        if err.code in (301, 302, 303, 307, 308):
            loc = err.headers.get("Location")
        else:
            raise ReleaseError(
                f"latest release lookup failed with HTTP {err.code}: {err.reason}"
            ) from err
    except (urllib.error.URLError, OSError) as err:
        raise ReleaseError(f"latest release lookup failed: {err}") from err

    if not loc:
        raise ReleaseError(f"latest release lookup failed: missing Location header in redirect from {url}")

    tag = loc.rstrip("/").rsplit("/", maxsplit=1)[-1]
    return validate_version_string(tag)


def download_file(url: str, dest_path: Path, timeout_sec: float) -> None:
    req = urllib.request.Request(url, headers={"User-Agent": "rice-cliproxyapi/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=timeout_sec) as resp:
            with dest_path.open("wb") as out:
                shutil.copyfileobj(resp, out)
    except urllib.error.HTTPError as err:
        raise ReleaseError(f"download failed for {url} with HTTP {err.code}: {err.reason}") from err
    except (urllib.error.URLError, OSError) as err:
        raise ReleaseError(f"download failed for {url}: {err}") from err


def fetch_checksums(url: str, timeout_sec: float) -> dict[str, str]:
    req = urllib.request.Request(url, headers={"User-Agent": "rice-cliproxyapi/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=timeout_sec) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as err:
        raise ReleaseError(f"checksums download failed from {url} with HTTP {err.code}: {err.reason}") from err
    except (urllib.error.URLError, OSError) as err:
        raise ReleaseError(f"checksums download failed from {url}: {err}") from err

    entries: dict[str, str] = {}
    for line in raw.splitlines():
        parts = line.split()
        if len(parts) == 2:
            digest, filename = parts
            digest_norm = digest.lower()
            if len(digest_norm) == 64 and all(c in "0123456789abcdef" for c in digest_norm):
                entries[filename] = digest_norm
    return entries


def verify_file_sha256(path: Path, expected_sha256: str) -> None:
    hasher = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    actual = hasher.hexdigest().lower()
    if actual != expected_sha256.lower():
        raise ReleaseError(
            f"checksum mismatch for {path.name}: expected {expected_sha256}, got {actual}"
        )


def extract_single_binary(archive_path: Path, dest_dir: Path, binary_name: str) -> Path:
    dest_binary = dest_dir / binary_name
    try:
        with tarfile.open(archive_path, mode="r:*") as tar:
            try:
                member = tar.getmember(binary_name)
            except KeyError as err:
                raise ReleaseError(f"archive {archive_path.name} missing required binary {binary_name}") from err

            if not member.isfile():
                raise ReleaseError(f"archive member {binary_name} is not a regular file")

            tar.extract(member, path=dest_dir, filter="data")
    except (OSError, tarfile.TarError) as err:
        raise ReleaseError(f"failed to extract archive {archive_path.name}: {err}") from err

    if not dest_binary.is_file():
        raise ReleaseError(f"extracted binary not found at expected path: {dest_binary}")

    dest_binary.chmod(EXECUTABLE_MODE)
    return dest_binary


def read_receipt(receipt_path: Path) -> dict[str, str] | None:
    if not receipt_path.is_file():
        return None
    try:
        data = json.loads(receipt_path.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            return {str(k): str(v) for k, v in data.items()}
    except (OSError, json.JSONDecodeError):
        return None
    return None


def write_receipt(receipt_path: Path, payload: dict[str, str]) -> None:
    receipt_path.write_text(f"{json.dumps(payload, indent=2)}\n", encoding="utf-8")


def get_current_info(state_dir: Path) -> tuple[str | None, Path | None]:
    current_link = state_dir / CURRENT_LINK_NAME
    if not current_link.is_symlink() and not current_link.exists():
        return None, None
    try:
        target = current_link.resolve()
        if target.is_dir():
            receipt = read_receipt(target / RECEIPT_FILE_NAME)
            if receipt and "version" in receipt:
                return receipt["version"], target
            return target.parent.name, target
    except OSError:
        pass
    return None, None


def update_current_symlink(state_dir: Path, target_dir: Path) -> None:
    current_link = state_dir / CURRENT_LINK_NAME
    temp_link = state_dir / f".current.{os.getpid()}.tmp"
    if temp_link.is_symlink() or temp_link.exists():
        temp_link.unlink()

    try:
        rel_target = target_dir.relative_to(state_dir)
        link_target = rel_target
    except ValueError:
        link_target = target_dir

    temp_link.symlink_to(link_target)
    temp_link.replace(current_link)


def restart_systemd_unit(unit_name: str, *, user: bool = False) -> None:
    cmd = ["systemctl"]
    if user:
        cmd.append("--user")
    cmd.extend(["restart", unit_name])
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=False)
        if res.returncode != 0:
            stderr = res.stderr.strip() or res.stdout.strip()
            raise ReleaseError(f"failed to restart unit {unit_name}: {stderr}")
        scope_desc = "user" if user else "system"
        print(f"restarted systemd {scope_desc} unit: {unit_name}")
    except OSError as err:
        raise ReleaseError(f"failed to execute systemctl: {err}") from err


@dataclass(frozen=True, slots=True)
class InstallResult:
    status: Literal["installed", "unchanged"]
    previous_version: str | None
    current_version: str
    target_dir: Path
    executable: Path
    changed: bool


def install_release(
    state_dir: Path,
    version_arg: str,
    target_plat: TargetPlatform,
    timeout_sec: float,
) -> InstallResult:
    state_dir.mkdir(parents=True, exist_ok=True)
    prev_version, prev_target = get_current_info(state_dir)

    if version_arg.strip().lower() == "latest":
        resolved_version = resolve_latest_version(REPOSITORY, timeout_sec)
    else:
        resolved_version = validate_version_string(version_arg)

    version_install_dir = (
        state_dir / VERSIONS_DIR_NAME / resolved_version / target_plat.key
    )
    dest_executable = version_install_dir / BINARY_NAME
    dest_receipt = version_install_dir / RECEIPT_FILE_NAME

    if version_install_dir.exists():
        is_valid_cached = (
            dest_executable.is_file()
            and os.access(dest_executable, os.X_OK)
            and (read_receipt(dest_receipt) or {}).get("version") == resolved_version
        )
        if is_valid_cached:
            current_link = state_dir / CURRENT_LINK_NAME
            if not current_link.is_symlink() or current_link.resolve() != version_install_dir.resolve():
                update_current_symlink(state_dir, version_install_dir)
                changed = prev_version != resolved_version
                return InstallResult(
                    status="installed" if changed else "unchanged",
                    previous_version=prev_version,
                    current_version=resolved_version,
                    target_dir=version_install_dir,
                    executable=dest_executable,
                    changed=changed,
                )
            return InstallResult(
                status="unchanged",
                previous_version=prev_version,
                current_version=resolved_version,
                target_dir=version_install_dir,
                executable=dest_executable,
                changed=False,
            )
        raise ReleaseError(
            f"cached install directory {version_install_dir} exists but is invalid; "
            "refusing to overwrite without manual cleanup"
        )

    checksums_url = f"{GITHUB_BASE}/{REPOSITORY}/releases/download/v{resolved_version}/{CHECKSUMS_FILE}"
    checksums = fetch_checksums(checksums_url, timeout_sec)

    asset_filename = target_plat.asset_name_template.replace("{version}", resolved_version)
    expected_sha256 = checksums.get(asset_filename)
    if not expected_sha256:
        raise ReleaseError(
            f"checksums.txt for {resolved_version} does not contain asset {asset_filename}"
        )

    version_install_dir.parent.mkdir(parents=True, exist_ok=True)
    stage_dir = Path(tempfile.mkdtemp(prefix=".stage.", dir=str(version_install_dir.parent)))
    try:
        archive_path = stage_dir / asset_filename
        download_url = f"{GITHUB_BASE}/{REPOSITORY}/releases/download/v{resolved_version}/{asset_filename}"
        download_file(download_url, archive_path, timeout_sec)
        verify_file_sha256(archive_path, expected_sha256)

        extract_single_binary(archive_path, stage_dir, BINARY_NAME)
        archive_path.unlink(missing_ok=True)

        receipt_payload = {
            "repository": REPOSITORY,
            "version": resolved_version,
            "platform": target_plat.key,
            "asset": asset_filename,
            "sha256": expected_sha256,
        }
        write_receipt(stage_dir / RECEIPT_FILE_NAME, receipt_payload)
        stage_dir.replace(version_install_dir)
    except Exception:
        shutil.rmtree(stage_dir, ignore_errors=True)
        raise

    update_current_symlink(state_dir, version_install_dir)

    changed = prev_version != resolved_version
    return InstallResult(
        status="installed",
        previous_version=prev_version,
        current_version=resolved_version,
        target_dir=version_install_dir,
        executable=version_install_dir / BINARY_NAME,
        changed=changed,
    )


# --- CLI dispatch ---


def handle_install_or_update(args: argparse.Namespace) -> int:
    state_dir = Path(args.state).expanduser().resolve()
    target_plat = normalize_platform(args.platform)
    lock_path = state_dir / LOCK_FILE_NAME

    with file_lock(lock_path):
        result = install_release(
            state_dir=state_dir,
            version_arg=getattr(args, "version", "latest") or "latest",
            target_plat=target_plat,
            timeout_sec=args.timeout,
        )

    if args.json:
        out = {
            "status": result.status,
            "changed": result.changed,
            "previous_version": result.previous_version,
            "current_version": result.current_version,
            "executable": str(result.executable),
        }
        print(json.dumps(out, indent=2))
    else:
        print(
            f"cli-proxy-api: {result.status} (version: {result.current_version}, "
            f"previous: {result.previous_version or 'none'}, executable: {result.executable})"
        )

    if args.restart and result.changed:
        restart_systemd_unit(args.restart, user=getattr(args, "user", False))

    return 0


def handle_run(args: argparse.Namespace, extra_args: Sequence[str]) -> int:
    state_dir = Path(args.state).expanduser().resolve()
    current_bin = state_dir / CURRENT_LINK_NAME / BINARY_NAME
    if not current_bin.is_file() or not os.access(current_bin, os.X_OK):
        print(
            f"error: CLIProxyAPI binary not found or not executable at {current_bin}.\n"
            f"Run 'release.py install --state {state_dir}' first.",
            file=sys.stderr,
        )
        return 127

    config_path = Path(args.config).expanduser().resolve()
    if not config_path.is_file():
        print(f"error: CLIProxyAPI config file not found: {config_path}", file=sys.stderr)
        return 1

    if extra_args and extra_args[0] == "--":
        extra_args = extra_args[1:]
    cmd = [str(current_bin), "--config", str(config_path), *extra_args]
    os.execv(str(current_bin), cmd)
    return 0


def handle_status(args: argparse.Namespace) -> int:
    state_dir = Path(args.state).expanduser().resolve()
    current_ver, current_target = get_current_info(state_dir)
    receipt_data = read_receipt(current_target / RECEIPT_FILE_NAME) if current_target else None

    if args.json:
        out = {
            "installed": current_ver is not None,
            "version": current_ver,
            "target": str(current_target) if current_target else None,
            "receipt": receipt_data,
        }
        print(json.dumps(out, indent=2))
    else:
        if current_ver:
            print(f"CLIProxyAPI: installed at version {current_ver} ({current_target})")
        else:
            print(f"CLIProxyAPI: not installed in {state_dir}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Dynamic release installer and wrapper for CLIProxyAPI."
    )
    subparsers = parser.add_subparsers(dest="subcommand", required=True)

    for cmd_name in ("install", "update"):
        sub = subparsers.add_parser(cmd_name, help=f"{cmd_name.capitalize()} release.")
        sub.add_argument("--state", required=True, help="State directory root")
        sub.add_argument("--version", default="latest", help="Release tag or 'latest'")
        sub.add_argument("--platform", default=None, help="Target platform (e.g. linux-amd64)")
        sub.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT_SEC, help="Timeout in seconds")
        sub.add_argument("--restart", default=None, help="Systemd unit to restart on change")
        sub.add_argument("--user", action="store_true", help="Target systemd user manager instead of system")
        sub.add_argument("--json", action="store_true", help="Output JSON")

    p_run = subparsers.add_parser("run", help="Exec installed binary with config.")
    p_run.add_argument("--state", required=True, help="State directory root")
    p_run.add_argument("--config", required=True, help="Path to config.yaml")

    p_status = subparsers.add_parser("status", help="Show installed release status.")
    p_status.add_argument("--state", required=True, help="State directory root")
    p_status.add_argument("--json", action="store_true", help="Output JSON")

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args_list = list(sys.argv[1:] if argv is None else argv)
    if "run" in args_list:
        parser = build_parser()
        try:
            known_args, extra_args = parser.parse_known_args(args_list)
            if known_args.subcommand == "run":
                return handle_run(known_args, extra_args)
        except Exception as err:
            print(f"error: {err}", file=sys.stderr)
            return 2

    parser = build_parser()
    try:
        parsed_args = parser.parse_args(args_list)
    except SystemExit as exc:
        return exc.code if isinstance(exc.code, int) else 0

    try:
        if parsed_args.subcommand in ("install", "update"):
            return handle_install_or_update(parsed_args)
        if parsed_args.subcommand == "status":
            return handle_status(parsed_args)
        parser.print_help(sys.stderr)
        return 2
    except ReleaseError as err:
        print(f"error: {err}", file=sys.stderr)
        return 1
    except Exception as err:
        print(f"unexpected error: {err}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
