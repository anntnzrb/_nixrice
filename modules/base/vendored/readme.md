# Upstream source cache

Every home importing the base modules creates `~/src/vendored` and schedules its updater every eight hours and at login or startup. Agents populate the directory with normal Git clones, conventionally under `<host>/<namespace>/<repo>`.

`vendored-update ~/src/vendored` discovers Git checkouts at any depth and refreshes them in place from each origin's current default branch. It discards local changes, ignored files, nested untracked repositories, branches, tags, stashes, and history. This directory holds disposable references. Concurrent reads can cross revisions during an update.

Each checkout keeps a detached HEAD, one shallow commit, and the complete current source tree. Blobs contain source files: `blob:none` does not avoid fetching those needed for a full checkout. The updater verifies the current tree's objects before converting partial clones into ordinary shallow clones, then removes unreachable objects and repacks with default compression and normal delta settings, reusing existing compressed objects. Existing sparse checkouts expand to the full tree. Submodules are not fetched, and Git LFS files remain pointers.

Two workers consume a rolling queue, with one Git packing thread each and separate temporary files. Each repository has a five-minute timeout followed by a 30-second forced-termination grace period. The sweep has no fixed overall deadline. A shared process lock prevents overlapping updates. A failed fetch leaves that checkout's files unchanged, other repositories continue, and any failure or timeout makes the job exit nonzero. An interruption after fetching may leave a checkout partly refreshed; the next sweep retries it. Missing roots are created and empty caches succeed. Git authentication must work without a prompt.

Inspect Linux logs with `journalctl --user -u vendored-update.service`. Darwin logs live at `~/Library/Logs/vendored-update.log`. Removing the feature removes its command and scheduled job, leaving the cached repositories in place.
