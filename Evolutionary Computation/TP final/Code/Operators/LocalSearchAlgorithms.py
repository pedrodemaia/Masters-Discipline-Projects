# -*- coding: utf-8 -*-
'''
Estruturas de vizinhança inter-rota: Shift(1,0), Shift(2,0), Swap(1,1), 
Swap(2,1), Swap(2,2), Crossover

Estruturas de vizinhança intra-rota: or-opt, or-opt2, or-opt3, 2-opt, swap, 
reverse

Permutação: Multi-swap, multi-shift, ejection-chain, or-opt
'''

import numpy as np

class LocalSearchAlgorithms:
 
    def __init__(self, vrp, ls):
        self.VRP = vrp
        self.LS = ls
        
    ######################################
    # Intra-Route Neighbourhood Structures
    ######################################
    
    def GenericIntraRouteBestImprovement(self, method, route):
        n = len(route)
        
        timeStar = 1e8
        routeStar = route
             
        timeBest = self.VRP.getRouteTime(route)
        routeBest = route
             
        improved = True
        while improved:
            improved = False
            for i in range(n-1):
                for j in range(i+1,n):
                    routeAux = method(route, route[i], route[j])
                    timeAux = self.VRP.getRouteTime(routeAux)
                    if timeAux < timeStar:
                        timeStar = timeAux
                        routeStar = np.copy(routeAux)
                    if timeAux < timeBest:
                        improved = True
                        routeBest = np.copy(routeAux)
                        timeBest = timeAux
            route = np.copy(routeBest)
        return routeStar
    
    def GenericOrOptBestImprovement(self, method, route, ni):
        n = len(route)
        
        timeStar = 1e8
        routeStar = route
             
        timeBest = self.VRP.getRouteTime(route)
        routeBest = route
             
        improved = True
        while improved:
            improved = False
            for i in range(n-ni):
                routeAux = method(route, route[i])
                timeAux = self.VRP.getRouteTime(routeAux)
                if timeAux < timeStar:
                    timeStar = timeAux
                    routeStar = np.copy(routeAux)
                if timeAux < timeBest:
                    improved = True
                    routeBest = np.copy(routeAux)
                    timeBest = timeAux
            route = np.copy(routeBest)
        return routeStar
    
    def TwoOptBestImprovement(self, route):
        return self.GenericIntraRouteBestImprovement(self.LS.TwoOpt, route)
    
    def IntraSwapBestImprovement(self, route):
        return self.GenericIntraRouteBestImprovement(self.LS.IntraSwap, route)
    
    def OrOptBestImprovement(self, route):
        return self.GenericOrOptBestImprovement(self.LS.OrOpt, route, 1)
    
    def OrOpt2BestImprovement(self, route):
        return self.GenericOrOptBestImprovement(self.LS.OrOpt2, route, 2)
    
    def OrOpt3BestImprovement(self, route):
        return self.GenericOrOptBestImprovement(self.LS.OrOpt3, route, 3)
    
    
    ######################################
    # Inter-Route Neighbourhood Structures
    ######################################
    
    def GenericShiftBestImprovement(self, method, route1, route2, ni):
        routeStar = (route1, route2)                
        timeStar = 1e8
        routeStar = (route1, route2)
                     
        timeBest = self.VRP.getRouteTime(route1) + self.VRP.getRouteTime(route2)
        routeBest = (route1, route2)
                     
        improved = True
        while improved:
            improved = False
            i = 0
            while i < len(route1)-ni:
                routeAux1, routeAux2 = method(route1, route2, route1[i])
                timeAux = self.VRP.getRouteTime(routeAux1) + \
                    self.VRP.getRouteTime(routeAux2)
                if timeAux < timeStar:
                    timeStar = timeAux
                    routeStar = (np.copy(routeAux1), np.copy(routeAux2))
                if timeAux < timeBest:
                    improved = True
                    routeBest = (np.copy(routeAux1), np.copy(routeAux2))
                    timeBest = timeAux
                route1, route2 = routeBest
                i += 1
        return routeStar
    
    def GenericSwapBestImprovement(self, method, route1, route2, ni1, ni2):
        routeStar = (route1, route2)                
        timeStar = 1e8
        routeStar = (route1, route2)
                     
        timeBest = self.VRP.getRouteTime(route1) + self.VRP.getRouteTime(route2)
        routeBest = (route1, route2)
                     
        improved = True
        while improved:
            improved = False
            i = 0
            while i < len(route1)-ni1:
                j = 0
                while j < len(route2)-ni2:
                    routeAux1, routeAux2 = method(route1, route2, 
                                                         route1[i], route2[j])
                    timeAux = self.VRP.getRouteTime(routeAux1) + \
                              self.VRP.getRouteTime(routeAux2)
                    if timeAux < timeStar:
                        timeStar = timeAux
                        routeStar = (np.copy(routeAux1), np.copy(routeAux2))
                    if timeAux < timeBest:
                        improved = True
                        routeBest = (np.copy(routeAux1), np.copy(routeAux2))
                        timeBest = timeAux
                    route1, route2 = routeBest
                    i += 1
                    j += 1
        return routeStar
    
    def ShiftOneZeroBestImprovement(self, route1, route2):
        return self.GenericShiftBestImprovement(self.LS.ShiftOneZero, 
                                               route1, route2, 1)
        
    def ShiftTwoZeroBestImprovement(self, route1, route2):
        return self.GenericShiftBestImprovement(self.LS.ShiftTwoZero, 
                                               route1, route2, 2)
    
    def SwapOneOneBestImprovement(self, route1, route2):
        return self.GenericSwapBestImprovement(self.LS.SwapOneOne, 
                                               route1, route2, 1, 1)
        
    def SwapTwoOneBestImprovement(self, route1, route2):
        return self.GenericSwapBestImprovement(self.LS.SwapTwoOne, 
                                               route1, route2, 2, 1)
        
    def SwapTwoTwoBestImprovement(self, route1, route2):
        return self.GenericSwapBestImprovement(self.LS.SwapTwoTwo, 
                                               route1, route2, 2, 2)
    

    ######################################
    # Intra Route searches for all routes
    ######################################
    def CompleteIntraRouteSearch(self, routes, method = None):
        if method is None:
            method = self.TwoOptBestImprovement
        return [method(route) for route in routes]
    
    def TwoOptCompleteSearch(self, routes):
        return self.CompleteIntraRouteSearch(routes, self.TwoOptBestImprovement)
    
    def IntraSwapCompleteSearch(self, routes):
        return self.CompleteIntraRouteSearch(routes, self.IntraSwapBestImprovement)
    
    def OrOptCompleteSearch(self, routes):
        return self.CompleteIntraRouteSearch(routes, self.OrOptBestImprovement)
    
    def OrOpt2CompleteSearch(self, routes):
        return self.CompleteIntraRouteSearch(routes, self.OrOpt2BestImprovement)
    
    def OrOpt3CompleteSearch(self, routes):
        return self.CompleteIntraRouteSearch(routes, self.OrOpt3BestImprovement)
        

    
    ######################################
    # Random Searches
    ######################################
    
    def RandomPerturbation(self, routes):
        functions = [self.LS.MultiShift, self.LS.MultiSwap, self.LS.EmptyRoute,
                     #self.LS.EjectionChain
                     ]
        f = np.random.choice(functions)
        
        return f(routes)
    
    def RandomIntraRouteSearch(self, route):
        intraRouteMethods = [self.TwoOptBestImprovement, 
                             self.IntraSwapBestImprovement,
                             self.OrOptBestImprovement,
                             self.OrOpt2BestImprovement,
                             self.OrOpt3BestImprovement]
        
        method = np.random.choice(intraRouteMethods)
        return method(route)
    
    def RandomInterRouteSearch(self, route1, route2):
        interRouteMethods = [self.ShiftOneZeroBestImprovement,
                             self.ShiftTwoZeroBestImprovement,
                             self.SwapOneOneBestImprovement, 
                             self.SwapTwoOneBestImprovement, 
                             self.SwapTwoTwoBestImprovement]
        
        method = np.random.choice(interRouteMethods)
        return method(route1, route2)
    
    #Apply random InterRoute search followed by IntraRoute search
    def RandomSearch(self, routes, numRepetitions = 1):
        for rep in range(numRepetitions):
            id1, id2 = np.random.permutation(range(len(routes)))[:2]
            route1 = routes[id1]
            route2 = routes[id2]
            
            # performs inter route local search on solution
            ir1, ir2 = self.RandomInterRouteSearch(route1, route2)
            
            # performs intra route local search on every route of solution
            r1 = self.RandomIntraRouteSearch(ir1)
            r2 = self.RandomIntraRouteSearch(ir2)
            
            routes[id1] = r1
            routes[id2] = r2
            
        return routes