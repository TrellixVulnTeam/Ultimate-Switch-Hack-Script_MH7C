# -*- coding: utf-8 -*-


"""
Description: File format determination library
Author: Mykyta Paliienko
License: MIT
"""


import os
import json
import sys


with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "data.json")) as data_file:
    data = json.loads(data_file.read())


class Info:
    """
    Generates object with given arguments

    Takes:
        type_ (list) -> list of file types
        extension (list) -> list of file extensions
        mime (list) -> list of file MIME types

    Returns:
        (<class 'fleep.Info'>) -> Class instance
    """

    def __init__(self, type_, extension, mime):
        self.type = type_
        self.extension = extension
        self.mime = mime

    def type_matches(self, type_):
        """ Checks if file type matches with given type """
        return type_ in self.type

    def extension_matches(self, extension):
        """ Checks if file extension matches with given extension """
        return extension in self.extension

    def mime_matches(self, mime):
        """ Checks if file MIME type matches with given MIME type """
        return mime in self.mime

    def __str__(self):
        return "type: {}, extension: {}, mime: {}".format(self.type, self.mime, self.extension)

def get(obj):
    """
    Determines file format and picks suitable file types, extensions and MIME types

    Takes:
        obj (bytes) -> byte sequence (128 bytes are enough)

    Returns:
        (<class 'fleep.Info'>) -> Class instance
    """

    if not isinstance(obj, bytes):
        raise TypeError("object type must be bytes")

    info = {
        "type": dict(),
        "extension": dict(),
        "mime": dict()
    }

    if sys.version_info[0] < 3:
        obj = bytearray(obj)

    stream = ' '.join(('{:02X}'.format(byte) for byte in obj))

    for element in data:
        for signature in element["signature"]:
            offset = element["offset"] * 2 + element["offset"]
            if signature == stream[offset:len(signature) + offset]:
                for key in ["type", "extension", "mime"]:
                    info[key][element[key]] = len(signature)

    for key in ["type", "extension", "mime"]:
        info[key] = sorted(info[key], key=info[key].get, reverse=True)

    return Info(info["type"], info["extension"], info["mime"])


def supported_types():
    """ Returns a list of supported file types """
    return sorted(set([x["type"] for x in data]))


def supported_extensions():
    """ Returns a list of supported file extensions """
    return sorted(set([x["extension"] for x in data]))


def supported_mimes():
    """ Returns a list of supported file MIME types """
    return sorted(set([x["mime"] for x in data]))
