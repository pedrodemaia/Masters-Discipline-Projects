# -*- coding: utf-8 -*-

import numpy as np
import math

class GeneticAlgorithm:
    def __init__(self, vrp, initialPopulationMethod, selectionMethod, 
                 crossoverMethod, mutationMethod, localSearchMethod = None):
        self.VRP = vrp
        self.InitialPopulationMethod = initialPopulationMethod
        self.SelectionMethod = selectionMethod
        self.CrossoverMethod = crossoverMethod
        self.MutationMethod = mutationMethod
        self.LocalSearchMethod = localSearchMethod
    
    def Optimize(self, popSize, maxGen, crossoverChance, mutationChance, 
                 localSearchNums = 0):
        # calculate local search generations
        localSearchGens = np.empty(0)
        if localSearchNums > 0:
            step = np.round(maxGen/localSearchNums)
            localSearchGens = np.append(np.arange(0, maxGen, step), maxGen-1)
                    
        # store best solution
        bestInd = []
        bestFx = 1e10
    
        # create initial population
        population = np.empty(popSize, dtype=object)
        Fx = np.zeros(popSize)
        for i in range(popSize):
            population[i] = self.InitialPopulationMethod()
            if len(localSearchGens) > 0:
                population[i] = [self.LocalSearchMethod(population[i][j]) \
                                      for j in range(len(population[i]))]
            Fx[i] = self.fitness(population[i])
    
            # check the best individual
            if Fx[i] < bestFx:
                bestInd = population[i]
                bestFx = Fx[i]
    
        # store best initial solution in solution history
        fxHist = np.array([bestFx])
        
        # store linearized fitness
        lFx = GeneticAlgorithm.convertFitness(Fx)
        meanlFx = np.mean(lFx)
        maxlFx = np.max(lFx)
    
        for gen in range(maxGen):
            
            #create empty offspring population
            offspring = np.empty(popSize, dtype=object)
            offspringFx = np.zeros(popSize)
            for i in range(math.floor(popSize/2)):
                # select parents
                p1, lfx1 = self.SelectionMethod(population, lFx)
                p2, lfx2 = self.SelectionMethod(population, lFx)
                
                c1, c2 = self.Crossover(p1, p2, lfx1, lfx2, meanlFx, 
                                        maxlFx, crossoverChance)
                
                c1 = self.Mutation(c1, lfx1, meanlFx, maxlFx, mutationChance)
                c2 = self.Mutation(c2, lfx2, meanlFx, maxlFx, mutationChance)
    
                # apply local search on offspring
                if gen in localSearchGens:
                    c1 = [self.LocalSearchMethod(c1[i]) for i in range(len(c1))]
                    c2 = [self.LocalSearchMethod(c2[i]) for i in range(len(c2))]
                
                # calculate offspring fitness
                offspringFx[2*i] = self.fitness(c1)
                offspringFx[2*i+1] = self.fitness(c2)
    
                # check if offspring is better than best known solution
                if offspringFx[2*i] < bestFx:
                    bestInd = c1
                    bestFx = offspringFx[2*i]
                if offspringFx[2*i+1] < bestFx:
                    bestInd = c2
                    bestFx = offspringFx[2*i+1]
    
                # add new offspring to population
                offspring[2*i] = c1
                offspring[2*i+1] = c2
    
            # replace population with offspring population
            population = offspring
            Fx = offspringFx
            
            # store linearized fitness
            lFx = GeneticAlgorithm.convertFitness(Fx)
            meanlFx = np.mean(lFx)
            maxlFx = np.max(lFx)
    
            # add best solution to solution history
            fxHist = np.append(fxHist, bestFx)
        return bestInd, bestFx, fxHist
    
    # perform dynamic chance crossover
    def Crossover(self, x1, x2, fx1, fx2, meanFx, maxFx, crossoverChance):
        pc = crossoverChance

        if (np.random.rand() < pc):
            # get route sizes
            l1 = np.cumsum([len(x1[i]) for i in range(len(x1))])[:-1]
            l2 = np.cumsum([len(x2[i]) for i in range(len(x2))])[:-1]
            
            # call crossover function
            c1a, c2a = self.CrossoverMethod(np.concatenate(x1), 
                                            np.concatenate(x2))
            
            # return original route sizes
            c1 = np.split(c1a,l1)
            c2 = np.split(c2a,l2)
        else:
            c1, c2 = x1, x2
        
        return c1, c2
    
    # perform dynamic chance mutation
    def Mutation(self, x, fx, meanFx, maxFx, mutationChance):
        pm = mutationChance

        if (np.random.rand() < pm):
            return self.MutationMethod(x)
        return x
    
    # calculate route time and infeasibility penalties
    def fitness(self, x):
        return self.VRP.getTotalCost(x)
    
    # method to linearly scale the fitness
    def convertFitness(fx):
        # converts lowest fitness into best
        fx = 1/fx
        
        # linear scale the fitness
        meanfx = np.mean(fx)
        maxfx = np.max(fx)
        K = 1.5
        a = (K-1)*meanfx/(maxfx - meanfx)
        b = (1-a)*meanfx
        fx = a*fx + b
        fx[fx<0] = 0
        return fx