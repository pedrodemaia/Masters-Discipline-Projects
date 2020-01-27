#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Nov  6 14:18:11 2019

@author: pedro
"""

import numpy as np

# Tournament Selection
def tournament(x, fx):
    # choose 2 random solutions
    (id1, id2) = np.random.permutation(len(x))[:2]
    
    # calculate candidate fitness
    f1 = fx[id1]
    f2 = fx[id2]
        
    # return solution with best fitness
    if f1 > f2:
        return (x[id1], f1)
    if f1 < f2:
        return (x[id2], f2)
        
    # return random solutions if fitness are the same
    if np.random.randint(2):
        return (x[id1], f1)
    return (x[id2], f2)
    
# Roulette Selection
def roulette(x, fx):
    totalFitness = sum(fx) 
    randomNumber = np.random.rand()
    lowerBound = 0
    # return solution chosen randomly with proportional chance
    for i in range(len(fx)):
        lowerBound += fx[i]/totalFitness
        if randomNumber < lowerBound:
            return (x[i], fx[i])
   
# uniformly choose a random selection method     
def randomSelectionMethod(x, fx):
    methods = [tournament, roulette]
    m = np.random.choice(methods)
    return m(x, fx)