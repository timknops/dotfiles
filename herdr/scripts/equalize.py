#!/usr/bin/env python3
# Keep the panes in a row (or column) equally sized. herdr's own split only
# halves the focused pane, and a closed pane hands all its space to one
# neighbour, so 3 columns become 50/25/25 and closing one of 4 gives 50/25/25.
#
#   equalize.py split right|down   split the focused pane, then even out its row
#   equalize.py watch              even out a row whenever a pane leaves it
import fcntl
import json
import os
import socket
import sys
import time

SOCKET = os.environ.get("HERDR_SOCKET_PATH", os.path.expanduser("~/.config/herdr/herdr.sock"))
AXES = {
    "right": ("x", "width", "right", "left"),
    "down": ("y", "height", "down", "up"),
}


class HerdrError(Exception):
    pass


def herdr(method, **params):
    with socket.socket(socket.AF_UNIX) as conn:
        conn.connect(SOCKET)
        conn.sendall((json.dumps({"id": method, "method": method, "params": params}) + "\n").encode())
        response = json.loads(conn.makefile().readline())
    if "error" in response:
        raise HerdrError(f"{method}: {response['error']}")
    return response["result"]


def contains(outer, inner):
    return (
        outer != inner
        and outer["x"] <= inner["x"]
        and outer["y"] <= inner["y"]
        and inner["x"] + inner["width"] <= outer["x"] + outer["width"]
        and inner["y"] + inner["height"] <= outer["y"] + outer["height"]
    )


def build_tree(layout):
    nodes = {p["pane_id"]: {"rect": p["rect"]} for p in layout["panes"]}
    nodes.update({s["id"]: {**s, "children": [None, None]} for s in layout["splits"]})
    parents = {}
    for node_id, node in nodes.items():
        enclosing = [s for s in layout["splits"] if contains(s["rect"], node["rect"])]
        if not enclosing:
            continue
        parent = min(enclosing, key=lambda s: s["rect"]["width"] * s["rect"]["height"])
        pos = AXES[parent["direction"]][0]
        side = 0 if node["rect"][pos] == parent["rect"][pos] else 1
        nodes[parent["id"]]["children"][side] = node_id
        parents[node_id] = parent["id"]
    return nodes, parents


def leaves(nodes, node_id):
    if "children" not in nodes[node_id]:
        return [node_id]
    return [leaf for child in nodes[node_id]["children"] for leaf in leaves(nodes, child)]


def chain_top(nodes, parents, split_id):
    direction = nodes[split_id]["direction"]
    while split_id in parents and nodes[parents[split_id]]["direction"] == direction:
        split_id = parents[split_id]
    return split_id


def equalize(nodes, top):
    direction = nodes[top]["direction"]
    pos, size, grow, shrink = AXES[direction]

    def in_chain(node_id):
        return nodes[node_id].get("direction") == direction

    def units(node_id):
        if not in_chain(node_id):
            return 1
        return sum(units(child) for child in nodes[node_id]["children"])

    def span(node_id):
        rect = nodes[node_id]["rect"]
        return rect[pos], rect[pos] + rect[size]

    resized = False
    pending = [top]
    while pending:
        split_id = pending.pop()
        first, second = nodes[split_id]["children"]
        pending += [child for child in (first, second) if in_chain(child)]

        delta = units(first) / units(split_id) - nodes[split_id]["ratio"]
        if abs(delta) < 0.005:
            continue
        # herdr moves the divider on the side of the pane that faces the
        # resize direction, so resize through a pane touching this divider.
        if delta > 0:
            pane = max(leaves(nodes, first), key=lambda leaf: span(leaf)[1])
            herdr("pane.resize", pane_id=pane, direction=grow, amount=delta)
        else:
            pane = min(leaves(nodes, second), key=lambda leaf: span(leaf)[0])
            herdr("pane.resize", pane_id=pane, direction=shrink, amount=-delta)
        resized = True
    return resized


def split(direction):
    target = herdr("pane.current")["pane"]
    new_pane = herdr(
        "pane.split",
        target_pane_id=target["pane_id"],
        direction=direction,
        cwd=target["foreground_cwd"] or target["cwd"],
        focus=True,
    )["pane"]["pane_id"]
    nodes, parents = build_tree(herdr("pane.layout", pane_id=new_pane)["layout"])
    # Resizing focuses the resized pane.
    if equalize(nodes, chain_top(nodes, parents, parents[new_pane])):
        herdr("pane.focus", pane_id=new_pane)


def watch():
    lock = open(f"{SOCKET}.equalize.lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        return

    # A closed pane is already gone from the layout by the time its event
    # arrives, so keep each tab's last layout to know which row it was in.
    trees = {}

    def remember(pane_id):
        layout = herdr("pane.layout", pane_id=pane_id)["layout"]
        trees[layout["tab_id"]] = build_tree(layout)
        return layout

    def remember_all():
        trees.clear()
        for pane in herdr("pane.list")["panes"]:
            if pane["tab_id"] not in trees:
                remember(pane["pane_id"])

    def on_close(pane_id):
        tab = next((tab for tab, (nodes, _) in trees.items() if pane_id in nodes), None)
        if tab is None:
            return
        nodes, parents = trees.pop(tab)
        if pane_id not in parents:
            return
        top = chain_top(nodes, parents, parents[pane_id])
        survivors = set(leaves(nodes, top)) - {pane_id}
        survivor = next(iter(survivors))

        for _ in range(20):
            layout = remember(survivor)
            if all(p["pane_id"] != pane_id for p in layout["panes"]):
                break
            time.sleep(0.05)
        else:
            return

        nodes, parents = trees[tab]
        row = survivor
        while row in parents and not survivors <= set(leaves(nodes, row)):
            row = parents[row]
        if set(leaves(nodes, row)) != survivors or nodes[row].get("direction") != nodes[top]["direction"]:
            return

        current = herdr("pane.current")["pane"]
        # Resizing focuses the resized pane, and focusing a pane in another
        # tab would switch to that tab.
        if equalize(nodes, row) and current["tab_id"] == tab:
            herdr("pane.focus", pane_id=current["pane_id"])

    remember_all()
    subscriptions = [{"type": t} for t in ("pane.created", "pane.focused", "pane.moved", "pane.exited", "pane.closed")]
    with socket.socket(socket.AF_UNIX) as conn:
        conn.connect(SOCKET)
        conn.sendall((json.dumps({"id": "watch", "method": "events.subscribe", "params": {"subscriptions": subscriptions}}) + "\n").encode())
        for line in conn.makefile():
            message = json.loads(line)
            event, data = message.get("event"), message.get("data", {})
            try:
                if event in ("pane_exited", "pane_closed"):
                    on_close(data["pane_id"])
                elif event == "pane_moved":
                    remember_all()
                elif event:
                    remember(data.get("pane_id") or data["pane"]["pane_id"])
            except (HerdrError, KeyError, StopIteration):
                pass


if sys.argv[1] == "split":
    split(sys.argv[2])
elif sys.argv[1] == "watch":
    watch()
