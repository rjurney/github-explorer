import sys
from math import *

# Derived from example in Programming Collective Intelligence
@outputSchema("pearson:double")
def pearsons(ratings_tuples_1, ratings_tuples_2):
  
  # Convert to an array of numbers
  ratings1 = [r[0] for r in ratings_tuples_1]
  ratings2 = [r[0] for r in ratings_tuples_2]
  
  # Find number of elements
  n = len(ratings1)
  
  # No ratings in common, return 0 (shouldn't happen)
  #if n == 0: return 0
  
  # Sum the ratings
  sum_1 = sum(ratings1)
  sum_2 = sum(ratings2)
  
  # Sum the squares
  sum_squares_1 = sum([pow(it, 2) for it in ratings1])
  sum_squares_2 = sum([pow(it, 2) for it in ratings2])
  
  # Sum the products
  sum_product = 0
  for idx, rating1 in enumerate(ratings1):
    rating2 = ratings2[idx]
    sum_product += rating1 * rating2
  
  # Calculate the Pearson score
  numerator = sum_product - (sum_1 * sum_2/n)
  denominator = sqrt((sum_squares_1 - pow(sum_1, 2)/n) * (sum_squares_2 - pow(sum_2, 2)/n))
  if denominator == 0: return 0.0
  pearson = numerator/denominator
  return pearson

# Cosine similarity
@outputSchema("similarity:double")
def cosine_similarity(ratings_tuples_1, ratings_tuples_2):
  
