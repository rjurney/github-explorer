import sys
from math import sqrt

@outputSchema("bag:{t:(user1:chararray, user2:chararray, difference:double)}")
def differences(ratings):
  out_bag = []
  for rating in ratings:
    square_diff = 0
    for rating2 in ratings:
      if rating == rating2:
        pass
      else:
        square_diff += pow(rating[2]-rating2[2],2)
        out_bag.append((rating[0], rating2[0], square_diff))
  return out_bag

@outputSchema("t:(user1:chararray, user2:chararray, distance:double)")
def distance(user_pairs):
  sys.stderr.write("In Data: " + str(user_pairs))
  _sum = 0
  user1 = ''
  user2 = ''
  for user_pair in user_pairs:
    user1 = user_pair[0]
    user2 = user_pair[1]
    _sum += user_pair[2]
  distance = 1/(1+sqrt(_sum))
  return (user1, user2, distance)