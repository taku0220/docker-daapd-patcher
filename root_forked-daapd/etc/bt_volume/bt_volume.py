#!/usr/bin/env python3

import dbus
import dbus.mainloop.glib
from gi.repository import GLib
from logging import basicConfig, getLogger, StreamHandler, DEBUG
import os
import requests
import signal

# config
from bt_volume_conf import *


def make_request(url, headers="", s_code=None, stream=False):
    logger.debug(f"Sending PUT {url} with headers: [{headers}]")

    try:
        res = requests.put(
            url, headers=headers, stream=stream, data=None, timeout=30
        )
    except requests.exceptions.RequestException as err:
        logger.error(err)
        return False

    logger.debug(f"res status code: {res.status_code}")
    if s_code is None:
        return res
    elif res.status_code != s_code:
        logger.error(f"request fail -status code:[{res.status_code} ]")
        return False
    else:
        logger.info(f"Got {res.status_code} response from {url}")
        return True

def property_changed(interface, changed, invalidated, path):
    iface = interface[interface.rfind(".") + 1:]
    for name, value in changed.items():
        val = str(value)
        logger.info(
            "{%s.PropertyChanged} [%s] %s = %s" % (iface, path, name,val)
            )

        if "/org/bluealsa" not in path:
            continue
        bt_addr_in = False
        for bt_addr in bt_addrs:
            if bt_addr in path:
                bt_addr_in = True
        if not bt_addr_in:
            continue

        if name != "Volume":
            continue
        if int(val) == volume_center:
            continue

        if int(val) > volume_center:
            logger.info(f"【 VolumeUp   】: debug val= {val}")
            ret_url = f"{fd_volume_url}+{volume_step}"
            make_request(ret_url)
            
        elif int(val) < volume_center:
            logger.info(f"【 VolumeDown 】: debug val= {val}")
            ret_url = f"{fd_volume_url}-{volume_step}"
            make_request(ret_url)
            
        else:
            continue

        bt_obj = bus.get_object("org.bluealsa", path)
        bt_mgr = dbus.Interface(bt_obj, 'org.freedesktop.DBus.Properties')
        bt_set_volume = bt_mgr.Set(
            f"org.bluealsa.{iface}", 'Volume', dbus.UInt16(volume_center)
            )

def sigint_handler(sig, frame):
    if sig == signal.SIGINT:
        mainloop.quit()
    else:
        raise ValueError("Undefined handler for '{}'".format(sig))


if __name__ == '__main__':
    log_format = "%(asctime)s : %(levelname)s | %(message)s"
    basicConfig(level=log_level, format=log_format)
    logger = getLogger(__name__)

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    signal.signal(signal.SIGINT, sigint_handler)
    bt_addrs = []
    for ret in bt_config_addrs:
        bt_addrs.append(ret.replace(':', '_'))
    fd_volume_url = "http://localhost:3689/api/player/volume?step="

    bus = dbus.SystemBus()

    bus.add_signal_receiver(
        property_changed, bus_name="org.bluez",
        dbus_interface="org.freedesktop.DBus.Properties",
        signal_name="PropertiesChanged", path_keyword="path"
        )

    bus.add_signal_receiver(
        property_changed, bus_name="org.bluealsa",
        dbus_interface="org.freedesktop.DBus.Properties",
        signal_name="PropertiesChanged", path_keyword="path"
        )

    mainloop = GLib.MainLoop.new(None, False)
    try:
        mainloop.run()
    finally:
        mainloop.quit()
        logger.info ("monitor-bluetooth quit\n")
        os.system('stty sane')
