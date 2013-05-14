import sys
from math import sqrt

@outputSchema("distance:double")
def distance(user_pairs):
  _sum = 0
  for users in user_pairs:
    _sum += users[3]
  distance = 1/(1+sqrt(_sum))
  return distance