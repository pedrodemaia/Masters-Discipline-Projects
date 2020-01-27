# This class defines the VRP problem

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

class VRP:
    def __init__(self, instance):
        self.Instance = instance
        self.M = len(instance.Vehicles)
        self.N = len(instance.Customers)
        self.Times = self.generateTravelTimesTable()
        self.CapacityViolationWeight = 0
        self.TotalTimeViolationWeight = 0
        self.TimeWindowViolationWeight = 0
        
    def generateTravelTimesTable(self):
        nodes = np.append(self.Instance.Depot, self.Instance.Customers)
        
        times = {}
        for origin in nodes:
             for destination in nodes:
                 if origin != destination:
                     times[(origin,destination)] = \
                         self.getTravelTime(origin, destination, useTable=False)
        
        return times
        
    def getRouteDemand(self, route):
        return sum([customer.Demands[0].Value for customer in route])    
    
    def getTravelTime(self, origin, destination, useTable = True):
        if useTable:
            return self.Times[(origin,destination)]
        return np.sqrt(np.abs(origin.Position[0] - destination.Position[0])**2 
                     + np.abs(origin.Position[1] - destination.Position[1])**2)
    
    def getRouteTime(self, route):
        if len(route) == 0:
            return 0
        
        time = self.getTravelTime(self.Instance.Depot, route[0])
        time += sum(self.getTravelTime(route[i],route[i+1]) + route[i].ServiceTime 
            for i in range(len(route)-1))
        time += self.getTravelTime(route[-1], self.Instance.Depot) + \
            route[-1].ServiceTime
        return time
    
    def getRouteDistance(self, route):
        if len(route) == 0:
            return 0
        
        dist = self.getTravelTime(self.Instance.Depot, route[0])
        dist += sum(self.getTravelTime(route[i],route[i+1]) 
            for i in range(len(route)-1))
        dist += self.getTravelTime(route[-1], self.Instance.Depot)
        return dist
    
    def getTotalTravelTime(self, x):
        return sum(self.getRouteTime(route) for route in x)
    
    def getTotalCost(self, x):
        return self.getTotalTravelTime(x) + \
        self.CapacityViolationWeight*self.getTotalCapacityViolation(x) + \
        self.TotalTimeViolationWeight*self.getTotalTimeViolation(x) + \
        self.TimeWindowViolationWeight*self.getTimeWindowViolation(x)
    
    def getTotalTravelDistance(self, x):
        return sum(self.getRouteDistance(route) for route in x)
    
    def isTravelTimeExceeded(self, route, vehicle):
        return vehicle.MaxTime < self.getRouteTime(route)
    
    def getTotalTimeViolation(self, x):
        total = 0
        for i in range(len(x)):
            route = x[i]
            vehicle = self.Instance.Vehicles[i]
            if self.isTravelTimeExceeded(route, vehicle):
                total += self.getRouteTime(route) - vehicle.MaxTime
        return total
            
    def isCapacityExceeded(self, route, vehicle):
        return vehicle.Capacity < self.getRouteDemand(route)
    
    def getTotalCapacityViolation(self, x):
        total = 0
        for i in range(len(x)):
            route = x[i]
            vehicle = self.Instance.Vehicles[i]
            if self.isCapacityExceeded(route, vehicle):
                total += self.getRouteDemand(route) - vehicle.Capacity
        return total
    
    def getTimeWindowViolation(self, x):
        total = 0
        for i in range(len(x)):
            route = np.insert(x[i], 0, self.Instance.Depot)
            time = 0
            for j in range(1,len(route)):
                # calcular o tempo que demorei pra chegar no cliente i
                time += route[j-1].ServiceTime + \
                    self.getTravelTime(route[j-1], route[j])
                
                startTime, endTime = route[j].TimeWindow
                if time < startTime:
                    total += startTime - time
                elif time > endTime:
                    total += time - endTime
        return total
             
    
    ###########################################################################
    # Initial Solutions
    ###########################################################################
    
    def createRandomSolution(self):
        order = np.random.permutation(self.Instance.Customers)
        ratio = int(np.ceil(self.N/self.M))
        return [order[i:i + ratio] for i in range(0, self.N, ratio)]
    
    def createSavingsSolution(self, alpha = 0):
        customers = self.Instance.Customers
        depot = self.Instance.Depot
        
        routes = [[c] for c in customers]
        availableCustomers = np.copy(customers)
        
        capacity = self.Instance.Vehicles[0].Capacity
        
        # compute savings
        savings = {}
        for i in range(len(customers)-1):
            ci = customers[i]
            for j in range(i+1, len(customers)):
                cj = customers[j]
                
                savings[(ci,cj)] = self.getTravelTime(depot, ci) + \
                    self.getTravelTime(depot, cj) - self.getTravelTime(ci,cj)
                    
        savings = pd.Series(savings)
        
        # order savings
        sortedSavings = savings.sort_values(ascending=False)
        
        # iterate savings
        while len(sortedSavings) > 0:
            # threshold
            tsh = (1-alpha)*sortedSavings.max() - alpha*sortedSavings.min()
            # restricted candidate list
            if tsh > 1e-10:
                rcl = sortedSavings.loc[sortedSavings >= tsh]
            else:
                rcl = sortedSavings
            
            chosen = rcl.sample()
            
            ci = chosen.index[0][0]
            cj = chosen.index[0][1]
            val = chosen[0]
            
            sortedSavings.pop(chosen.index[0])
            
            # check if customers from saving can be bonded
            if ci in availableCustomers and cj in availableCustomers:
                ri = [r for r in routes if ci in r][0]
                rj = [r for r in routes if cj in r][0]
                
                # check if customers are not in same route and 
                #if capacity reamains feasible
                if ri != rj and self.getRouteDemand(ri) + \
                    self.getRouteDemand(rj) < capacity:
                    # join routes routes and check customers availability
                    if ri[-1] == ci and rj[0] == cj:
                        newRoute = np.append(ri,rj).tolist()
                        if newRoute[0] != ci:
                            availableCustomers = \
                                availableCustomers[availableCustomers != ci]
                        if newRoute[-1] != cj:
                            availableCustomers = \
                                availableCustomers[availableCustomers != cj]
                    elif ri[0] == ci and rj[0] == cj:
                        newRoute = np.append(ri[::-1],rj).tolist()
                        availableCustomers = \
                                availableCustomers[availableCustomers != ci]
                        if newRoute[-1] != cj:
                            availableCustomers = \
                                availableCustomers[availableCustomers != cj]
                    elif ri[-1] == ci and rj[-1] == cj:
                        newRoute = np.append(ri,rj[::-1]).tolist()
                        if newRoute[0] != ci:
                            availableCustomers = \
                                availableCustomers[availableCustomers != ci]
                        availableCustomers = \
                                availableCustomers[availableCustomers != cj]
                    else:
                        newRoute = np.append(ri[::-1],rj[::-1]).tolist()
                        availableCustomers = \
                                availableCustomers[availableCustomers != ci]
                        availableCustomers = \
                                availableCustomers[availableCustomers != cj]
                    
                    routes = [r for r in routes if r != ri and r != rj]
                    routes.append(newRoute)
        return routes
                
    
    def plot(self, x):
        plt.figure()
        plt.plot(self.Instance.Depot.Position[0], 
                 self.Instance.Depot.Position[1], 'or')
        for customer in self.Instance.Customers:
            plt.plot(customer.Position[0], customer.Position[1], 'ob')
        for route in x:
            r = np.append(self.Instance.Depot, 
                          np.append(route, self.Instance.Depot))
            plt.plot([node.Position[0] for node in r], 
                     [node.Position[1] for node in r], 'b--')
        plt.show()
        
# =============================================================================
#     def createNearestNeightbourSolution(self):
#         nodesToAdd = np.array(range(1,self.N))
#         x = [0]
#         while len(nodesToAdd) > 1:
#             dists = self.C[x[-1],nodesToAdd]
#             val, pos = min((val, pos) for (pos, val) in enumerate(dists))
#             x.append(nodesToAdd[pos])
#             nodesToAdd = nodesToAdd[nodesToAdd != nodesToAdd[pos]]
#         x.append(nodesToAdd[0])
#         return np.array(x[1:])
#     
#     def createGreedySolution(self, alpha):
#         nodesToAdd = np.array(range(1,self.N))
#         x = [0]
#         while len(nodesToAdd) > 1:
#             dists = self.C[x[-1],nodesToAdd]
#             maxValue = max(dists)
#             minValue = min(dists)
#             limit = minValue + alpha*(maxValue - minValue)
#             candidateList = [(val, pos) for (pos, val) in enumerate(dists) \
#                              if val < limit]
#             pos = candidateList[np.random.randint(len(candidateList))][1]
#             x.append(nodesToAdd[pos])
#             nodesToAdd = nodesToAdd[nodesToAdd != nodesToAdd[pos]]
#         x.append(nodesToAdd[0])
#         return np.array(x[1:])
# =============================================================================
