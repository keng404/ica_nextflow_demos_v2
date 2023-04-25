#!/usr/bin/env python
from __future__ import print_function
from collections import OrderedDict
import re

regexes = {
    'nf-core/deepvariant': ['v_nf_deepvariant.txt', r"(\S+)"],
    'Nextflow': ['v_nextflow.txt', r"(\S+)"],
    'DeepVariant': ['v_deepvariant.txt', r"deepvariant-(\S+)-"],
    'Python': ['v_python.txt', r"Python (\S+)"],
    'Pip': ['v_pip.txt', r"pip (\S+)"],
    'Samtools': ['v_samtools.txt', r"samtools (\S+)"],
    'Htslib': ['v_samtools.txt', r"Using htslib (\S+)"],
    'Lbzip2': ['v_lbzip2.txt', r"lbzip2 version (\S+)"],
    'Bzip2': ['v_bzip2.txt', r"bzip2, Version (\S+)"],
}
results = OrderedDict()
results['nf-core/deepvariant'] = '<span style="color:#999999;\">N/A</span>'
results['Nextflow'] = '<span style="color:#999999;\">N/A</span>'
results['DeepVariant'] = '<span style="color:#999999;\">N/A</span>'
results['Python'] = '<span style="color:#999999;\">N/A</span>'
results['Pip'] = '<span style="color:#999999;\">N/A</span>'
results['Samtools'] = '<span style="color:#999999;\">N/A</span>'
results['Htslib'] = '<span style="color:#999999;\">N/A</span>'
results['Lbzip2'] = '<span style="color:#999999;\">N/A</span>'
results['Bzip2'] = '<span style="color:#999999;\">N/A</span>'

# Search each file using its regex
for k, v in regexes.items():
    with open(v[0]) as x:
        versions = x.read()
        match = re.search(v[1], versions)
        if match:
            results[k] = "v{}".format(match.group(1))

# Dump to YAML
print ('''
id: 'nf-core/deepvariant-software-versions'
section_name: 'nf-core/deepvariant Software Versions'
section_href: 'https://github.com/nf-core/deepvariant'
plot_type: 'html'
description: 'are collected at run time from the software output.'
data: |
    <dl class="dl-horizontal">
''')
for k,v in results.items():
    print("        <dt>{}</dt><dd>{}</dd>".format(k,v))
print ("    </dl>")
