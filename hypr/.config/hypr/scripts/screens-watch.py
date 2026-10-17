#!/usr/bin/env python
"""Re-decide the screen setup the moment a monitor comes or goes.

Hyprland announces monitoradded/monitorremoved on its second socket, and that
is the only way to hear about a cable: there is no config hook for it. Without
this, plugging the external in means the workspaces stay wherever they were
until something else triggers a sync.

Python rather than socat, because socat is not installed on any of the laptops
and python is. Reconnects rather than exiting, so a Hyprland restart does not
leave a dead watcher behind.
"""
import os
import socket
import subprocess
import sys
import time

SCRIPT = os.path.expanduser("~/.config/hypr/scripts/screens.sh")
# Events that change which screens exist. "monitoraddedv2" is the modern name;
# both are accepted so this keeps working across Hyprland versions.
EVENTS = ("monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2")


def socket_path():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    run = os.environ.get("XDG_RUNTIME_DIR")
    if not sig or not run:
        return None
    return os.path.join(run, "hypr", sig, ".socket2.sock")


def main():
    path = socket_path()
    if not path:
        print("screens-watch: not inside a Hyprland session", file=sys.stderr)
        return 1

    while True:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(path)
                with s.makefile("r", encoding="utf-8", errors="replace") as f:
                    for line in f:
                        name = line.split(">>", 1)[0]
                        if name in EVENTS:
                            # A cable settles in stages: the monitor appears
                            # before its mode is set, and pinning to it a
                            # moment too early is ignored.
                            time.sleep(0.5)
                            subprocess.run([SCRIPT], check=False)
        except (FileNotFoundError, ConnectionRefusedError, OSError):
            pass
        time.sleep(2)


if __name__ == "__main__":
    sys.exit(main())
