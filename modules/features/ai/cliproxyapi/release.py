#!/usr/bin/env python3
# Copyright (c) 2026 rice-cliproxyapi.
"""Dynamic release installer, updater, and execution wrapper for CLIProxyAPI."""

from __future__ import annotations

import argparse
import contextlib
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
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import IO, TYPE_CHECKING, Literal, cast, override

if TYPE_CHECKING:
    from collections.abc import Generator, Sequence
    from http.client import HTTPMessage, HTTPResponse

type Json = dict[str, Json] | list[Json] | str | float | bool | None

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
PLATFORM_PARTS: int = 2
OS_NAMES: dict[str, Literal["linux", "darwin"]] = {"linux": "linux", "darwin": "darwin"}
ARCH_ALIASES: dict[str, Literal["amd64", "arm64"]] = {
    "amd64": "amd64",
    "x86_64": "amd64",
    "x64": "amd64",
    "arm64": "arm64",
    "aarch64": "arm64",
}
CHECKSUM_FIELDS: int = 2
SHA256_HEX_LEN: int = 64


class Args(argparse.Namespace):
    """Parsed command line with typed defaults."""

    def __init__(self) -> None:
        """Initialise every option with its default value."""
        super().__init__()
        self.subcommand: str = ""
        self.state: str = ""
        self.version: str = "latest"
        self.platform: str | None = None
        self.timeout: float = DEFAULT_TIMEOUT_SEC
        self.restart: str | None = None
        self.user: bool = False
        self.json: bool = False
        self.config: str = ""


class ReleaseError(Exception):
    """Base error for release installation and execution operations."""


@dataclass(frozen=True, slots=True)
class TargetPlatform:
    """Operating system and CPU architecture a release asset is built for."""

    os: Literal["linux", "darwin"]
    arch: Literal["amd64", "arm64"]

    @property
    def key(self) -> str:
        """Directory name identifying this platform."""
        return f"{self.os}-{self.arch}"

    @property
    def asset_name_template(self) -> str:
        """Release asset file name with a literal ``{version}`` placeholder."""
        arch_tag = "aarch64" if self.arch == "arm64" else "amd64"
        return f"CLIProxyAPI_{{version}}_{self.os}_{arch_tag}.tar.gz"


def normalize_platform(value: str | None) -> TargetPlatform:
    """Resolve an explicit ``os-arch`` string, or the host when none is given.

    Args:
        value: Requested platform such as ``linux-amd64``, or ``None``/blank.

    Returns:
        The matching target platform.

    Raises:
        ReleaseError: If the platform, host OS, or host architecture is unsupported.
    """
    if value is not None and value.strip():
        parts = value.strip().lower().replace("_", "-").split("-")
        if len(parts) == PLATFORM_PARTS:
            target_os = OS_NAMES.get(parts[0])
            arch = ARCH_ALIASES.get(parts[1])
            if target_os is not None and arch is not None:
                return TargetPlatform(os=target_os, arch=arch)
        msg = f"unsupported target platform: {value!r}"
        raise ReleaseError(msg)

    system = platform.system().lower()
    host_os = OS_NAMES.get(system)
    if host_os is None:
        msg = f"unsupported host operating system: {system!r}"
        raise ReleaseError(msg)

    machine = platform.machine().lower()
    host_arch = ARCH_ALIASES.get(machine)
    if host_arch is None:
        msg = f"unsupported host architecture: {machine!r}"
        raise ReleaseError(msg)
    return TargetPlatform(os=host_os, arch=host_arch)


def validate_version_string(version: str) -> str:
    """Strip a leading ``v`` and reject anything that is not a safe path component.

    Args:
        version: Release tag or bare version.

    Returns:
        The cleaned version string.

    Raises:
        ReleaseError: If the version is empty or could escape its directory.
    """
    cleaned = version.strip().removeprefix("v")
    if (
        not cleaned
        or cleaned in {".", ".."}
        or "/" in cleaned
        or "\\" in cleaned
        or re.fullmatch(COMPONENT_PATTERN, cleaned) is None
    ):
        msg = f"invalid version string: {version!r}"
        raise ReleaseError(msg)
    return cleaned


@contextmanager
def file_lock(lock_path: Path) -> Generator[None]:
    """Hold an exclusive advisory lock on ``lock_path`` for the block.

    Args:
        lock_path: Lock file, created together with its parent directory.

    Yields:
        Nothing; the lock is held until the block exits.
    """
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    with lock_path.open("a+", encoding="utf-8") as lock_file:
        try:
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
            yield
        finally:
            with contextlib.suppress(OSError):
                fcntl.flock(lock_file.fileno(), fcntl.LOCK_UN)


class NoRedirectHandler(urllib.request.HTTPRedirectHandler):
    """Redirect handler that surfaces redirects as HTTP errors."""

    @override
    def redirect_request(
        self,
        req: urllib.request.Request,
        fp: IO[bytes],
        code: int,
        msg: str,
        headers: HTTPMessage,
        newurl: str,
    ) -> urllib.request.Request | None:
        """Refuse to follow the redirect.

        Returns:
            Always ``None``.
        """
        return None


def build_request(url: str) -> urllib.request.Request:
    """Build a GET request carrying the project user agent.

    Args:
        url: Absolute URL under the GitHub base.

    Returns:
        The prepared request.
    """
    return urllib.request.Request(  # noqa: S310 - URL built from fixed GitHub base
        url, headers={"User-Agent": "rice-cliproxyapi/1.0"}
    )


def open_url(url: str, timeout_sec: float) -> HTTPResponse:
    """Open ``url`` and return the response object.

    Args:
        url: Absolute URL under the GitHub base.
        timeout_sec: Socket timeout in seconds.

    Returns:
        The open HTTP response.
    """
    return cast(
        "HTTPResponse",
        urllib.request.urlopen(  # noqa: S310 - URL built from fixed GitHub base
            build_request(url), timeout=timeout_sec
        ),
    )


def resolve_latest_version(repository: str, timeout_sec: float) -> str:
    """Find the latest release version from the ``/releases/latest`` redirect.

    Args:
        repository: ``owner/name`` GitHub repository.
        timeout_sec: Socket timeout in seconds.

    Returns:
        The validated version of the latest release.

    Raises:
        ReleaseError: If the lookup fails or the redirect is missing.
    """
    url = f"{GITHUB_BASE}/{repository}/releases/latest"
    opener = urllib.request.build_opener(NoRedirectHandler)
    loc: str | None
    try:
        response = cast(
            "HTTPResponse", opener.open(build_request(url), timeout=timeout_sec)
        )
        with response as resp:
            loc = resp.headers.get("Location")
    except urllib.error.HTTPError as err:
        if err.code not in {301, 302, 303, 307, 308}:
            msg = f"latest release lookup failed with HTTP {err.code}: {err.reason}"
            raise ReleaseError(msg) from err
        loc = err.headers.get("Location")
    except (urllib.error.URLError, OSError) as err:
        msg = f"latest release lookup failed: {err}"
        raise ReleaseError(msg) from err

    if not loc:
        msg = (
            "latest release lookup failed: "
            f"missing Location header in redirect from {url}"
        )
        raise ReleaseError(msg)

    tag = loc.rstrip("/").rsplit("/", maxsplit=1)[-1]
    return validate_version_string(tag)


def download_file(url: str, dest_path: Path, timeout_sec: float) -> None:
    """Download ``url`` into ``dest_path``.

    Args:
        url: Absolute URL under the GitHub base.
        dest_path: File to write.
        timeout_sec: Socket timeout in seconds.

    Raises:
        ReleaseError: If the request or the write fails.
    """
    try:
        with open_url(url, timeout_sec) as resp, dest_path.open("wb") as out:
            shutil.copyfileobj(resp, out)
    except urllib.error.HTTPError as err:
        msg = f"download failed for {url} with HTTP {err.code}: {err.reason}"
        raise ReleaseError(msg) from err
    except (urllib.error.URLError, OSError) as err:
        msg = f"download failed for {url}: {err}"
        raise ReleaseError(msg) from err


def fetch_checksums(url: str, timeout_sec: float) -> dict[str, str]:
    """Download and parse a ``sha256sum``-style checksums file.

    Args:
        url: Absolute URL of the checksums file.
        timeout_sec: Socket timeout in seconds.

    Returns:
        Mapping of file name to lowercase SHA-256 hex digest.

    Raises:
        ReleaseError: If the download fails.
    """
    try:
        with open_url(url, timeout_sec) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as err:
        msg = f"checksums download failed from {url} with HTTP {err.code}: {err.reason}"
        raise ReleaseError(msg) from err
    except (urllib.error.URLError, OSError) as err:
        msg = f"checksums download failed from {url}: {err}"
        raise ReleaseError(msg) from err

    entries: dict[str, str] = {}
    for line in raw.splitlines():
        parts = line.split()
        if len(parts) == CHECKSUM_FIELDS:
            digest, filename = parts
            digest_norm = digest.lower()
            if len(digest_norm) == SHA256_HEX_LEN and all(
                c in "0123456789abcdef" for c in digest_norm
            ):
                entries[filename] = digest_norm
    return entries


def verify_file_sha256(path: Path, expected_sha256: str) -> None:
    """Check that ``path`` hashes to ``expected_sha256``.

    Args:
        path: File to hash.
        expected_sha256: Expected SHA-256 hex digest.

    Raises:
        ReleaseError: If the digests differ.
    """
    hasher = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    actual = hasher.hexdigest().lower()
    if actual != expected_sha256.lower():
        msg = (
            f"checksum mismatch for {path.name}: "
            f"expected {expected_sha256}, got {actual}"
        )
        raise ReleaseError(msg)


def extract_member(archive_path: Path, dest_dir: Path, binary_name: str) -> None:
    """Extract one regular-file member from a tar archive.

    Args:
        archive_path: Tar archive to read.
        dest_dir: Directory to extract into.
        binary_name: Archive member to extract.

    Raises:
        ReleaseError: If the member is missing or not a regular file.
    """
    with tarfile.open(archive_path, mode="r:*") as tar:
        try:
            member = tar.getmember(binary_name)
        except KeyError as err:
            msg = f"archive {archive_path.name} missing required binary {binary_name}"
            raise ReleaseError(msg) from err

        if not member.isfile():
            msg = f"archive member {binary_name} is not a regular file"
            raise ReleaseError(msg)

        tar.extract(member, path=dest_dir, filter="data")


def extract_single_binary(archive_path: Path, dest_dir: Path, binary_name: str) -> Path:
    """Extract exactly ``binary_name`` from a tar archive and make it executable.

    Args:
        archive_path: Tar archive to read.
        dest_dir: Directory to extract into.
        binary_name: Archive member to extract.

    Returns:
        Path of the extracted executable.

    Raises:
        ReleaseError: If the member is missing, not a regular file, or unreadable.
    """
    try:
        extract_member(archive_path, dest_dir, binary_name)
    except (OSError, tarfile.TarError) as err:
        msg = f"failed to extract archive {archive_path.name}: {err}"
        raise ReleaseError(msg) from err

    dest_binary = dest_dir / binary_name
    dest_binary.chmod(EXECUTABLE_MODE)
    return dest_binary


def read_receipt(receipt_path: Path) -> dict[str, str] | None:
    """Read an install receipt.

    Args:
        receipt_path: Receipt file.

    Returns:
        The receipt as strings, or ``None`` if absent, unreadable, or not an object.
    """
    if not receipt_path.is_file():
        return None
    try:
        data = cast("Json", json.loads(receipt_path.read_text(encoding="utf-8")))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return None
    if isinstance(data, dict):
        return {str(k): str(v) for k, v in data.items()}
    return None


def write_receipt(receipt_path: Path, payload: dict[str, str]) -> None:
    """Write an install receipt as indented JSON.

    Args:
        receipt_path: Receipt file to write.
        payload: Receipt fields.
    """
    _ = receipt_path.write_text(f"{json.dumps(payload, indent=2)}\n", encoding="utf-8")


def get_current_info(state_dir: Path) -> tuple[str | None, Path | None]:
    """Describe the release the ``current`` link points to.

    Args:
        state_dir: State directory root.

    Returns:
        The installed version and its directory, or ``(None, None)``.
    """
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
    """Atomically point ``current`` at ``target_dir`` with a relative link.

    Args:
        state_dir: State directory root containing ``current``.
        target_dir: Release directory below ``state_dir``.
    """
    current_link = state_dir / CURRENT_LINK_NAME
    temp_link = state_dir / f".current.{os.getpid()}.tmp"
    if temp_link.is_symlink() or temp_link.exists():
        temp_link.unlink()

    temp_link.symlink_to(target_dir.relative_to(state_dir))
    _ = temp_link.replace(current_link)


def restart_systemd_unit(unit_name: str, *, user: bool = False) -> None:
    """Restart a systemd unit.

    Args:
        unit_name: Unit to restart.
        user: Target the user manager instead of the system manager.

    Raises:
        ReleaseError: If ``systemctl`` cannot run or fails.
    """
    cmd = ["systemctl"]
    if user:
        cmd.append("--user")
    cmd.extend(["restart", unit_name])
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=False)  # noqa: S603 - fixed systemctl argv, no shell
    except OSError as err:
        msg = f"failed to execute systemctl: {err}"
        raise ReleaseError(msg) from err
    if res.returncode != 0:
        stderr = res.stderr.strip() or res.stdout.strip()
        msg = f"failed to restart unit {unit_name}: {stderr}"
        raise ReleaseError(msg)
    scope_desc = "user" if user else "system"
    print(f"restarted systemd {scope_desc} unit: {unit_name}")


@dataclass(frozen=True, slots=True)
class InstallResult:
    """Outcome of an install or update."""

    status: Literal["installed", "unchanged"]
    previous_version: str | None
    current_version: str
    target_dir: Path
    executable: Path
    changed: bool


def reuse_cached_release(
    state_dir: Path, version_install_dir: Path, version: str, prev_version: str | None
) -> InstallResult:
    """Reuse an already installed release, repointing ``current`` if needed.

    Args:
        state_dir: State directory root.
        version_install_dir: Existing directory of the requested release.
        version: Requested version.
        prev_version: Version ``current`` pointed to before.

    Returns:
        The install result for the cached release.

    Raises:
        ReleaseError: If the cached directory is not a valid install.
    """
    dest_executable = version_install_dir / BINARY_NAME
    dest_receipt = version_install_dir / RECEIPT_FILE_NAME
    is_valid_cached = (
        dest_executable.is_file()
        and os.access(dest_executable, os.X_OK)
        and (read_receipt(dest_receipt) or {}).get("version") == version
    )
    if not is_valid_cached:
        msg = (
            f"cached install directory {version_install_dir} exists but is invalid; "
            "refusing to overwrite without manual cleanup"
        )
        raise ReleaseError(msg)

    current_link = state_dir / CURRENT_LINK_NAME
    changed = False
    if (
        not current_link.is_symlink()
        or current_link.resolve() != version_install_dir.resolve()
    ):
        update_current_symlink(state_dir, version_install_dir)
        changed = prev_version != version
    return InstallResult(
        status="installed" if changed else "unchanged",
        previous_version=prev_version,
        current_version=version,
        target_dir=version_install_dir,
        executable=dest_executable,
        changed=changed,
    )


def fetch_verified_archive(
    url: str, archive_path: Path, expected_sha256: str, timeout_sec: float
) -> None:
    """Download an archive and verify its checksum.

    Args:
        url: Absolute URL of the archive.
        archive_path: File to write.
        expected_sha256: Expected SHA-256 hex digest.
        timeout_sec: Socket timeout in seconds.
    """
    download_file(url, archive_path, timeout_sec)
    verify_file_sha256(archive_path, expected_sha256)


def stage_release(
    version_install_dir: Path,
    version: str,
    target_plat: TargetPlatform,
    timeout_sec: float,
) -> None:
    """Download, verify, and extract a release into ``version_install_dir``.

    Args:
        version_install_dir: Final directory of the release.
        version: Version to install.
        target_plat: Platform whose asset is installed.
        timeout_sec: Socket timeout in seconds.

    Raises:
        ReleaseError: If the checksums lack the asset.
    """
    release_url = f"{GITHUB_BASE}/{REPOSITORY}/releases/download/v{version}"
    checksums = fetch_checksums(f"{release_url}/{CHECKSUMS_FILE}", timeout_sec)

    asset_filename = target_plat.asset_name_template.replace("{version}", version)
    expected_sha256 = checksums.get(asset_filename)
    if not expected_sha256:
        msg = f"checksums.txt for {version} does not contain asset {asset_filename}"
        raise ReleaseError(msg)

    version_install_dir.parent.mkdir(parents=True, exist_ok=True)
    stage_dir = Path(
        tempfile.mkdtemp(prefix=".stage.", dir=str(version_install_dir.parent))
    )
    archive_path = stage_dir / asset_filename
    try:
        fetch_verified_archive(
            f"{release_url}/{asset_filename}",
            archive_path,
            expected_sha256,
            timeout_sec,
        )
        _ = extract_single_binary(archive_path, stage_dir, BINARY_NAME)
        archive_path.unlink(missing_ok=True)

        write_receipt(
            stage_dir / RECEIPT_FILE_NAME,
            {
                "repository": REPOSITORY,
                "version": version,
                "platform": target_plat.key,
                "asset": asset_filename,
                "sha256": expected_sha256,
            },
        )
        _ = stage_dir.replace(version_install_dir)
    except Exception:
        shutil.rmtree(stage_dir, ignore_errors=True)
        raise


def install_release(
    state_dir: Path,
    version_arg: str,
    target_plat: TargetPlatform,
    timeout_sec: float,
) -> InstallResult:
    """Install a release into ``state_dir`` and make it current.

    Args:
        state_dir: State directory root.
        version_arg: Release tag or ``latest``.
        target_plat: Platform whose asset is installed.
        timeout_sec: Socket timeout in seconds.

    Returns:
        The install result.
    """
    state_dir.mkdir(parents=True, exist_ok=True)
    prev_version, _ = get_current_info(state_dir)

    if version_arg.strip().lower() == "latest":
        resolved_version = resolve_latest_version(REPOSITORY, timeout_sec)
    else:
        resolved_version = validate_version_string(version_arg)

    version_install_dir = (
        state_dir / VERSIONS_DIR_NAME / resolved_version / target_plat.key
    )
    if version_install_dir.exists():
        return reuse_cached_release(
            state_dir, version_install_dir, resolved_version, prev_version
        )

    stage_release(version_install_dir, resolved_version, target_plat, timeout_sec)
    update_current_symlink(state_dir, version_install_dir)

    return InstallResult(
        status="installed",
        previous_version=prev_version,
        current_version=resolved_version,
        target_dir=version_install_dir,
        executable=version_install_dir / BINARY_NAME,
        changed=prev_version != resolved_version,
    )


# --- CLI dispatch ---


def handle_install_or_update(args: Args) -> int:
    """Run the ``install`` and ``update`` subcommands.

    Args:
        args: Parsed command line.

    Returns:
        The process exit code.
    """
    state_dir = Path(args.state).expanduser().resolve()
    target_plat = normalize_platform(args.platform)
    lock_path = state_dir / LOCK_FILE_NAME

    with file_lock(lock_path):
        result = install_release(
            state_dir=state_dir,
            version_arg=args.version or "latest",
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
        details = ", ".join([
            f"version: {result.current_version}",
            f"previous: {result.previous_version or 'none'}",
            f"executable: {result.executable}",
        ])
        print(f"cli-proxy-api: {result.status} ({details})")

    if args.restart and result.changed:
        restart_systemd_unit(args.restart, user=args.user)

    return 0


def handle_run(args: Args, extra_args: Sequence[str]) -> int:
    """Replace this process with the installed binary.

    Args:
        args: Parsed command line.
        extra_args: Arguments forwarded to the binary.

    Returns:
        The process exit code when the binary cannot be started.
    """
    state_dir = Path(args.state).expanduser().resolve()
    current_bin = state_dir / CURRENT_LINK_NAME / BINARY_NAME
    if not current_bin.is_file() or not os.access(current_bin, os.X_OK):
        lines = [
            f"error: CLIProxyAPI binary not found or not executable at {current_bin}.",
            f"Run 'release.py install --state {state_dir}' first.",
        ]
        print("\n".join(lines), file=sys.stderr)
        return 127

    config_path = Path(args.config).expanduser().resolve()
    if not config_path.is_file():
        print(
            f"error: CLIProxyAPI config file not found: {config_path}", file=sys.stderr
        )
        return 1

    if extra_args and extra_args[0] == "--":
        extra_args = extra_args[1:]
    cmd = [str(current_bin), "--config", str(config_path), *extra_args]
    return os.execv(str(current_bin), cmd)  # noqa: S606 - exec of the installed binary is the purpose of `run`


def handle_status(args: Args) -> int:
    """Run the ``status`` subcommand.

    Args:
        args: Parsed command line.

    Returns:
        The process exit code.
    """
    state_dir = Path(args.state).expanduser().resolve()
    current_ver, current_target = get_current_info(state_dir)
    receipt_data = (
        read_receipt(current_target / RECEIPT_FILE_NAME) if current_target else None
    )

    if args.json:
        out = {
            "installed": current_ver is not None,
            "version": current_ver,
            "target": str(current_target) if current_target else None,
            "receipt": receipt_data,
        }
        print(json.dumps(out, indent=2))
    elif current_ver:
        print(f"CLIProxyAPI: installed at version {current_ver} ({current_target})")
    else:
        print(f"CLIProxyAPI: not installed in {state_dir}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    """Build the command line parser.

    Returns:
        The parser with the install, update, run, and status subcommands.
    """
    parser = argparse.ArgumentParser(
        description="Dynamic release installer and wrapper for CLIProxyAPI."
    )
    subparsers = parser.add_subparsers(dest="subcommand", required=True)

    for cmd_name in ("install", "update"):
        sub = subparsers.add_parser(cmd_name, help=f"{cmd_name.capitalize()} release.")
        _ = sub.add_argument("--state", required=True, help="State directory root")
        _ = sub.add_argument(
            "--version", default="latest", help="Release tag or 'latest'"
        )
        _ = sub.add_argument(
            "--platform", default=None, help="Target platform (e.g. linux-amd64)"
        )
        _ = sub.add_argument(
            "--timeout",
            type=float,
            default=DEFAULT_TIMEOUT_SEC,
            help="Timeout in seconds",
        )
        _ = sub.add_argument(
            "--restart", default=None, help="Systemd unit to restart on change"
        )
        _ = sub.add_argument(
            "--user",
            action="store_true",
            help="Target systemd user manager instead of system",
        )
        _ = sub.add_argument("--json", action="store_true", help="Output JSON")

    p_run = subparsers.add_parser("run", help="Exec installed binary with config.")
    _ = p_run.add_argument("--state", required=True, help="State directory root")
    _ = p_run.add_argument("--config", required=True, help="Path to config.yaml")

    p_status = subparsers.add_parser("status", help="Show installed release status.")
    _ = p_status.add_argument("--state", required=True, help="State directory root")
    _ = p_status.add_argument("--json", action="store_true", help="Output JSON")

    return parser


def run_subcommand(args_list: list[str]) -> int | None:
    """Handle the ``run`` subcommand, which forwards unknown arguments.

    Args:
        args_list: Command line arguments without the program name.

    Returns:
        The exit code, or ``None`` if the command is not ``run``.
    """
    parser = build_parser()
    try:
        known_args, extra_args = parser.parse_known_args(args_list, namespace=Args())
        if known_args.subcommand == "run":
            return handle_run(known_args, extra_args)
    except Exception as err:  # noqa: BLE001 - CLI boundary reports any failure as exit code 2
        print(f"error: {err}", file=sys.stderr)
        return 2
    return None


def dispatch(parsed_args: Args) -> int:
    """Run the install, update, or status subcommand.

    Args:
        parsed_args: Parsed command line.

    Returns:
        The process exit code.
    """
    if parsed_args.subcommand in {"install", "update"}:
        return handle_install_or_update(parsed_args)
    return handle_status(parsed_args)


def main(argv: Sequence[str] | None = None) -> int:
    """Run the command line interface.

    Args:
        argv: Arguments without the program name; defaults to ``sys.argv``.

    Returns:
        The process exit code.
    """
    args_list = list(sys.argv[1:] if argv is None else argv)
    if "run" in args_list:
        run_result = run_subcommand(args_list)
        if run_result is not None:
            return run_result

    parser = build_parser()
    try:
        parsed_args = parser.parse_args(args_list, namespace=Args())
    except SystemExit as exc:
        return exc.code if isinstance(exc.code, int) else 0

    try:
        return dispatch(parsed_args)
    except ReleaseError as err:
        print(f"error: {err}", file=sys.stderr)
        return 1
    except Exception as err:  # noqa: BLE001 - CLI boundary reports any failure as exit code 1
        print(f"unexpected error: {err}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
