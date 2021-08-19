#!/usr/bin/env python3
#
# The script processes a component XML spec generated by Mucbinsplit and sets
# the hash of writable memory regions to 'none'. This is necessary in the case
# of SL so the init/reload code does not perform hash validation for the .data
# section since it will change on repeated execution of the load operation.
#
# Note that this script is preferred to changing Mucbinsplit because SL is very
# much an edge case.

import os
import sys
from lxml import etree

NO_HASH = "none"

if len(sys.argv) != 3:
    print(sys.argv[0] + ' <XML spec> <Output file>')
    sys.exit(1)

if not os.path.isfile(sys.argv[1]):
    sys.exit("Error: XML spec not found")

parser = etree.XMLParser(remove_blank_text=True)
doc = etree.parse(sys.argv[1], parser).getroot()
hash_nodes = doc.xpath('/component/provides/memory[@writable="true"]/hash')

if len(hash_nodes) == 0:
    print("No writable memory region found")
else:
    for node in hash_nodes:
        print("Clearing hash for writable memory region '"
              + node.getparent().get('logical') + "'")
        node.attrib['value'] = NO_HASH

    with open(sys.argv[2], 'wb') as f:
        print("Writing adjusted XML spec to '" + sys.argv[2] + "'")
        f.write(etree.tostring(doc, pretty_print=True))
