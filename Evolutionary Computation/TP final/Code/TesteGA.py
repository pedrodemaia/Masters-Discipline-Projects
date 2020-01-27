# -*- coding: utf-8 -*-
"""
Created on Tue Nov 19 16:45:58 2019

@author: pedro
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import time
import VRP
import Instance
import Operators.LocalSearchOperators as LSO
import Operators.LocalSearchAlgorithms as LSA
import Operators.CrossoverOperators as co
import Operators.SelectionOperators as so
import Algorithms.GeneticAlgorithm as GA

numVehicles = [
               3, 3, 3, 3, 3, 3, 3, 3, 3, # C100
               2, 2, 2, 2, 2, 2, 2, 2, # C200
               4, 3, 3, 3, 4, 3, 3, 3, # RC100
               3, 3, 3, 3, 3, 3, 3, 2, # RC200
               8, 7, 5, 4, 6, 3, 4, 4, 5, 4, 5, 4, # R100
               4, 4, 3, 2, 3, 3, 3, 1, 2, 3, 2 # R200
               ]
numVehicles = 5
numCustomers = 50
instanceName = [
        'C101', #'C102', 'C103', 'C104', 'C105', 'C106', 'C107', 'C108', 'C109', 
        'C201', #'C202', 'C203', 'C204', 'C205', 'C206', 'C207', 'C208',
        'RC101', #'RC102', 'RC103', 'RC104', 'RC105', 'RC106', 'RC107', 'RC108', 
        'RC201', #'RC202', 'RC203', 'RC204', 'RC205', 'RC206', 'RC207', 'RC208',
        'R101', #'R102', 'R103', 'R104', 'R105', 'R106', 'R107', 'R108', 
        #    'R109', 'R110', 'R111', 'R112',
        'R201', #'R202', 'R203', 'R204', 'R205', 'R206', 'R207', 'R208',
        #    'R209', 'R210', 'R211'
            ]

numRep = 10
fxs = np.zeros([len(instanceName), numRep])
distances = np.zeros([len(instanceName), numRep])
times = np.zeros([len(instanceName), numRep])
for prob in range(len(instanceName)):
    for rep in range(numRep):
        instance = Instance.Instance(instanceName[prob], numVehicles, 
                                     'Solomon', numCustomers)
        
        vrp = VRP.VRP(instance)
        lso = LSO.LocalSearchOperators(vrp)
        lsa = LSA.LocalSearchAlgorithms(vrp, lso)
        coo = co.CrossOverOperators(vrp, lso)
        
        
        ga = GA.GeneticAlgorithm(vrp, vrp.createRandomSolution, 
                                 so.randomSelectionMethod, coo.BCRC, 
                                 lsa.RandomPerturbation, lsa.RandomIntraRouteSearch)
        ga.CapacityViolationWeight = 1e3
        ga.TimeWindowViolationWeight = 0
        ga.TotalTimeViolationWeight = 1e2
        
        
        popSize = 100 # population size
        maxGen = 100 # number of generations
        cp = 0.8 # crossover probability
        mp = 0.3 # mutation probability
        lsn = 10 # number of generations with local search
        lsp = 0.2 # proportion of population to apply local search
        
        startTime = time.time()
        (xBest, fxBest, fxHist) = ga.Optimize(popSize, maxGen, cp, mp, lsn)
        optTime = time.time() - startTime
        optDist = vrp.getTotalTravelDistance(xBest)
        print(instanceName[prob],'Rep:', rep+1, 'Time: %.2f'%optTime, 
              'Fx: %.2f'%fxBest, 'Dist: %.2f'%optDist)
        fxs[prob][rep] = fxBest
        distances[prob][rep] = optDist
        times[prob][rep] = optTime
        
    vrp.plot(xBest)
    
dists = pd.DataFrame(distances)
dists.to_csv("D:\Dropbox\Dropbox\Mestrado\Disciplinas\Planejamento e Análise " \
             "Experimentos\Trabalhos\Projeto Final\Resultados piloto\ distancias.csv")