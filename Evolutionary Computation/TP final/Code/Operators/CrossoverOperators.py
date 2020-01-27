#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Nov  6 14:30:49 2019

@author: pedro
"""

import numpy as np

class CrossOverOperators:    
    def __init__(self, vrp, ls):
        self.VRP = vrp
        self.LS = ls
    
    # Best Cost Route Crossover (BCRC) function
    def BCRC(self, x1, x2):
        n = len(x1)
        
        sep1 = np.sort(np.random.permutation(range(1,n-1))[:2])
        sub1 = [x1[:sep1[0]], x1[sep1[0]:sep1[1]], x1[sep1[1]:]]
        
        sep2 = np.sort(np.random.permutation(range(1,n-1))[:2])
        sub2 = [x2[:sep2[0]], x2[sep2[0]:sep2[1]], x2[sep2[1]:]]
        
        remove1 = np.random.choice(sub1)
        remove2 = np.random.choice(sub2)
        
        c1 = x1[[node not in remove2 for node in x1]]
        c2 = x2[[node not in remove1 for node in x2]]
        
        for node in remove2:
            c1 = self.LS.OrOpt(c1,node)
        for node in remove1:
            c2 = self.LS.OrOpt(c2,node)
            
        return c1, c2

    #Partially Mapped Crossover (PMX) function
    def PMX(self, x1, x2):
        N = len(x1)
        # cut points
        c1 = np.random.randint(0,N-2)
        c2 = np.random.randint(c1+1,N)
        
        # middle part
        mid1 = x1[c1:c2]
        mid2 = x2[c1:c2]
        
        # offspring creation
        child1 = np.concatenate((x1[:c1], mid2, x1[c2:]))
        child2 = np.concatenate((x2[:c1], mid1, x2[c2:]))
        
        # correct repetitions before first cut point
        for pos in range(c1):
            # correction in offspring 1
            temp = child1[pos]
            id = mid2 == temp
            while any(id):
                temp = mid1[id][0]
                id = mid2 == temp
            child1[pos] = temp
    
            # correction in offspring 2
            temp = child2[pos]
            id = mid1 == temp
            while any(id):
                temp = mid2[id][0]
                id = mid1 == temp
            child2[pos] = temp
    
        # correct repetitions after last cut point
        for pos in range(c2,N):
            # correction in offspring 1
            temp = child1[pos]
            id = mid2 == temp
            while any(id):
                temp = mid1[id][0]
                id = mid2 == temp
            child1[pos] = temp
    
            # correction in offspring 2
            temp = child2[pos]
            id = mid1 == temp
            while any(id):
                temp = mid2[id][0]
                id = mid1 == temp
            child2[pos] = temp
            
        return child1, child2