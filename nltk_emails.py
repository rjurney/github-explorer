#!/usr/bin/env python

#
# derived from example at http://www.harshj.com/2010/04/25/writing-and-reading-avro-data-files-using-python/
#
from avro import schema, datafile, io
import pprint
import sys
import json
from nltk.tokenize import SpaceTokenizer
from nltk.tag import UnigramTagger
import nltk.data
from nltk.tokenize.punkt import PunktSentenceTokenizer, PunktWordTokenizer
from nltk.chunk import RegexpParser
from nltk.tag.simplify import simplify_wsj_tag

def process(sentence):
  for (w1,t1),(w2,t2),(w3,t3) in nltk.trigrams(sentence):
    if t1.startswith('V') and t2 == 'TO' and t3.startswith('V'):
      print w1, w2, w3

# Setup sentence detector
sent_detector = nltk.data.load('tokenizers/punkt/english.pickle')

field_id = None
# Optional key to print
if (len(sys.argv) > 2):
  field_id = sys.argv[2]

# Test reading avros
rec_reader = io.DatumReader()

# Create a 'data file' (avro file) reader
df_reader = datafile.DataFileReader(
  open(sys.argv[1]),
  rec_reader
)

# Read all records stored inside
pp = pprint.PrettyPrinter()
i = 0
for record in df_reader:
  #if i > 20:
  #  break
  i += 1
  
  sentences = PunktSentenceTokenizer().tokenize(record['body'])
  for sentence in sentences:
    words = PunktWordTokenizer().tokenize(sentence)
    tagged_sent = nltk.pos_tag(words)
    #simplified = [(word, simplify_wsj_tag(tag)) for word, tag in tagged_sent]
    #process(tagged_sent)
    grammer = r"""
NP: {<.*>+}
    }<VBD|IN>+{
"""
    cp = nltk.RegexpParser(grammer)
    tree = cp.parse(tagged_sent)
    for subtree in tree.subtrees():
      if subtree.node == 'NP':
        print subtree.leaves()
        print ' '.join([a[0] for a in subtree.leaves()])

obj = json.loads(df_reader.meta['avro.schema'])
print "\nAvro Schema: " + json.dumps(obj)