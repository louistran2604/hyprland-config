#!/usr/bin/python3
"""Waybar peripheral batteries; Bluetooth via BlueZ, R1 via passive HID reads."""

import html
import json
import os
from pathlib import Path
import select
import sys
import time

import dbus


def bluetooth_rows():
    try:
        manager = dbus.Interface(
            dbus.SystemBus().get_object('org.bluez', '/'),
            'org.freedesktop.DBus.ObjectManager',
        )
        objects = manager.GetManagedObjects(timeout=3)
    except dbus.DBusException:
        return [('Bluetooth', None, 'service unavailable')]
    rows = []
    for interfaces in objects.values():
        device = interfaces.get('org.bluez.Device1', {})
        if not device.get('Connected', False):
            continue
        battery = interfaces.get('org.bluez.Battery1', {}).get('Percentage')
        status = 'Bluetooth' if battery is not None else 'battery unavailable'
        if battery is None and device.get('Icon') == 'input-gaming':
            address = str(device.get('Address', '')).lower()
            try:
                battery = int((Path('/sys/class/power_supply') /
                               f'ps-controller-battery-{address}' / 'capacity').read_text())
            except (OSError, ValueError):
                continue
            if not 0 <= battery <= 100:
                continue
            status = 'kernel battery'
        rows.append((str(device.get('Alias', 'Bluetooth device')),
                     int(battery) if battery is not None else None,
                     status))
    return sorted(rows)


def render(rows):
    text = []
    tooltip = []
    low = False
    for name, percentage, status in rows:
        value = f'{percentage}%' if percentage is not None else '?'
        icon = {'Attack Shark R1': '󰍽',
                'SOUL ULTRA WIRELESS 2': '',
                'Wireless Controller': ''}.get(name)
        label = (f'<span foreground="#ffffff">{icon}</span>' if icon
                 else html.escape(name[:12]))
        text.append(f'{label} {value}')
        tooltip.append(f'{name}: {value} — {status}')
        low |= percentage is not None and percentage <= 20
    return {'text': ' | '.join(text) or 'No devices',
            'tooltip': html.escape('\n'.join(tooltip)),
            'class': 'low' if low else 'normal'}


def parse_r1(report):
    # R1's interrupt report: ID, model, ready, state, charge in tenths.
    # https://github.com/jlucaso1/attack-shark-r1/blob/main/src/protocol.rs
    if (len(report) < 5 or report[:3] != b'\x03\x10\x40'
            or report[3] not in (1, 2, 3, 128) or report[4] > 10):
        return None
    return report[4] * 10


def mouse_nodes():
    nodes = []
    for node in Path('/sys/class/hidraw').glob('*'):
        try:
            info = (node / 'device/uevent').read_text()
            # Only the receiver's status interface, never keyboard/mouse input.
            if ('HID_ID=0003:00001D57:0000FA60' in info
                    and 'HID_PHYS=' in info and '/input2\n' in info):
                nodes.append(Path('/dev') / node.name)
        except OSError:
            continue
    return nodes


def mouse_row(percentage, updated, now, status):
    if percentage is not None and now - updated <= 30:
        return ('Attack Shark R1', percentage, '2.4 GHz receiver')
    return ('Attack Shark R1', None, status if percentage is None else
            f'stale; last report {percentage}% — mouse may be asleep or off')


def main():
    handles = {}
    percentage, updated = None, 0
    while True:
        nodes = mouse_nodes()
        status = 'receiver disconnected'
        for node in list(handles):
            if node not in nodes:
                os.close(handles.pop(node))
                percentage = None
        for node in nodes:
            if node not in handles:
                try:
                    handles[node] = os.open(node, os.O_RDONLY | os.O_NONBLOCK)
                except PermissionError:
                    status = 'battery unavailable; receiver read permission required'
                except OSError:
                    status = 'receiver unavailable'
        if handles:
            status = 'awaiting battery report; move mouse to wake it'
        rows = bluetooth_rows()
        # Avoid duplicating R1 if it is connected using Bluetooth instead.
        if not any('r1' in row[0].lower() for row in rows):
            rows.append(mouse_row(percentage, updated, time.monotonic(), status))
        print(json.dumps(render(rows)), flush=True)
        if '--once' in sys.argv:
            return
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            ready, _, _ = select.select(list(handles.values()), [], [],
                                        max(0, deadline - time.monotonic()))
            for fd in ready:
                try:
                    report = os.read(fd, 64)
                    if not report:
                        raise OSError('receiver disconnected')
                except BlockingIOError:
                    continue
                except OSError:
                    node = next(node for node, value in handles.items() if value == fd)
                    os.close(handles.pop(node))
                    percentage = None
                    continue
                value = parse_r1(report)
                if value is not None:
                    percentage, updated = value, time.monotonic()


if __name__ == '__main__':
    main()
