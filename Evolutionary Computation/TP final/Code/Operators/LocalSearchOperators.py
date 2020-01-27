# -*- coding: utf-8 -*-
'''
Estruturas de vizinhança inter-rota: Shift(1,0), Shift(2,0), Swap(1,1), 
Swap(2,1), Swap(2,2), Crossover

Estruturas de vizinhança intra-rota: or-opt, or-opt2, or-opt3, 2-opt, swap, 
reverse

Permutação: Multi-swap, multi-shift, ejection-chain, or-opt
'''

import numpy as np

class LocalSearchOperators:  
    def __init__(self, vrp):
        self.VRP = vrp
        
    ######################################
    # Intra-Route Neighbourhood Structures
    ######################################
    
    # Remove one node from the route and reinsert in the best position
    def OrOpt(self, route, node = None):
        route = np.copy(route)
        if len(route) < 2:
            return route
        
        if node == None:
            node = np.random.choice(route)
        r2 = route[route != node]
        
        depot = self.VRP.Instance.Depot
        
        insertionCost = np.zeros(len(r2)+1)
        insertionCost[0] = self.VRP.getTravelTime(depot,node) + \
                self.VRP.getTravelTime(node,r2[0]) - self.VRP.getTravelTime(depot,r2[0])
        insertionCost[1:len(r2)] = [self.VRP.getTravelTime(r2[i],node) + \
                self.VRP.getTravelTime(node,r2[i+1]) - \
                self.VRP.getTravelTime(r2[i],r2[i+1]) for i in range(len(r2)-1)]
        insertionCost[-1] = self.VRP.getTravelTime(r2[-1],node) + \
                self.VRP.getTravelTime(node,depot) - self.VRP.getTravelTime(r2[-1],depot)
                
        minCostPos = np.argmin(insertionCost)
        return np.insert(r2, minCostPos, node)
    
    # Remove 2 consecutive nodes from the route and reinsert in the best position
    def OrOpt2(self, route, startNode = None):
        route = np.copy(route)
        
        if len(route) < 3:
            return route
                
        if startNode == None:
            startNode = np.random.choice(route[:-1])
        startIndex = np.where(route == startNode)[0][0]
        endNode = route[startIndex+1]
        internalCost = self.VRP.getTravelTime(startNode, endNode)
        
        r2 = np.concatenate((route[:startIndex], route[startIndex+2:]))
        
        depot = self.VRP.Instance.Depot
        
        insertionCost = np.zeros(len(r2)+1)
        insertionCost[0] = self.VRP.getTravelTime(depot,startNode) + internalCost + \
                self.VRP.getTravelTime(endNode,r2[0]) - self.VRP.getTravelTime(depot,r2[0])
        insertionCost[1:len(r2)] = [self.VRP.getTravelTime(r2[i],startNode) + \
                internalCost + self.VRP.getTravelTime(endNode,r2[i+1]) - \
                self.VRP.getTravelTime(r2[i],r2[i+1]) for i in range(len(r2)-1)]
        insertionCost[-1] = self.VRP.getTravelTime(r2[-1],startNode) + internalCost \
                + self.VRP.getTravelTime(endNode,depot) - \
                self.VRP.getTravelTime(r2[-1],depot)
                
        minCostPos = np.argmin(insertionCost)
        return np.insert(r2, minCostPos, [startNode, endNode])
    
    # Remove 3 consecutive nodes from the route and reinsert in the best position
    def OrOpt3(self, route, startNode = None):        
        route = np.copy(route)
        
        if len(route) < 4:
            return route
        
        if startNode == None:
            startNode = np.random.choice(route[:-2])
        startIndex = np.where(route == startNode)[0][0]
        middleNode = route[startIndex+1]
        endNode = route[startIndex+2]
        internalCost = self.VRP.getTravelTime(startNode, middleNode) + \
                    self.VRP.getTravelTime(middleNode, endNode)
        
        r2 = np.concatenate((route[:startIndex], route[startIndex+3:]))
        
        depot = self.VRP.Instance.Depot
        
        insertionCost = np.zeros(len(r2)+1)
        insertionCost[0] = self.VRP.getTravelTime(depot,startNode) + internalCost + \
                self.VRP.getTravelTime(endNode,r2[0]) - self.VRP.getTravelTime(depot,r2[0])
        insertionCost[1:len(r2)] = [self.VRP.getTravelTime(r2[i],startNode) + \
                internalCost + self.VRP.getTravelTime(endNode,r2[i+1]) - \
                self.VRP.getTravelTime(r2[i],r2[i+1]) for i in range(len(r2)-1)]
        insertionCost[-1] = self.VRP.getTravelTime(r2[-1],startNode) + internalCost \
                + self.VRP.getTravelTime(endNode,depot) - \
                self.VRP.getTravelTime(r2[-1],depot)
                
        minCostPos = np.argmin(insertionCost)
        return np.insert(r2, minCostPos, [startNode, middleNode, endNode])
    
    # reverse the route order between two nodes
    def TwoOpt(self, route, nodeA = None, nodeB = None):
        route = np.copy(route)
        
        if len(route) < 3:
            return route
        
        if nodeA == None:
            nodeA = np.random.choice(route[:-2])
        idA = np.where(route == nodeA)[0][0]
        if nodeB == None:
            nodeB = np.random.choice(route[idA+1:])
        idB = np.where(route == nodeB)[0][0]
        
        route[idA:idB] = route[idB-1:idA-1 if idA > 0 else None:-1]
        return route
    
    # swap two nodes positions in a single route
    def IntraSwap(self, route, nodeA = None, nodeB = None):
        route = np.copy(route)
        
        if len(route) < 3:
            return route
        
        if nodeA == None:
            nodeA = np.random.choice(route)
        idA = np.where(route == nodeA)[0][0]
        if nodeB == None:
            nodeB = np.random.choice(route[route != nodeA])
        idB = np.where(route == nodeB)[0][0]
        
        route[[idA,idB]] = [nodeB, nodeA]
        return route
    
    # revert the route order
    def Reverse(self, route):
        return np.copy(route[-1::-1])
    
    ######################################
    # Inter-Route Neighbourhood Structures
    ######################################
    
    # transfer one node from a route to another and place on best position
    def ShiftOneZero(self, route1, route2, node = None):
        route1 = np.copy(route1)
        route2 = np.copy(route2)
        
        if len(route1) < 1:
            return (route1, route2)
        
        if node == None:
            node = np.random.choice(route1)
        
        route1 = route1[route1 != node]
        route2 = self.OrOpt(np.append(route2, node), node)
        return (route1, route2)
    
    # transfer two consecutive nodes from a route to another
    def ShiftTwoZero(self, route1, route2, startNode = None):
        if len(route1) < 2:
            return (route1, route2)
        
        route1 = np.copy(route1)
        route2 = np.copy(route2)
        
        if len(route1) < 2:
            return (route1, route2)
        
        if startNode == None:
            startNode = np.random.choice(route1[:-1])
        startIndex = np.where(route1 == startNode)[0][0]
        endNode = route1[startIndex+1]
        
        route1 = route1[np.logical_and(route1 != startNode, route1 != endNode)]
        route2 = self.OrOpt2(np.append(route2,[startNode, endNode]), startNode)
        return (route1, route2)
    
    # swap one node between two routes
    def SwapOneOne(self, route1, route2, node1 = None, node2 = None):
        route1 = np.copy(route1)
        route2 = np.copy(route2)
        
        if len(route1) < 1 or len(route2) < 1:
            return (route1, route2)
        
        if node1 == None:
            node1 = np.random.choice(route1)
        if node2 == None:
            node2 = np.random.choice(route2)
        
        route1 = self.OrOpt(np.append(route1[route1 != node1], node2), node2)
        route2 = self.OrOpt(np.append(route2[route2 != node2], node1), node1)
        return (route1, route2)
    
    # swap two consecutive nodes from a route and one from another
    def SwapTwoOne(self, route1, route2, startNode1 = None, node2 = None):
        route1 = np.copy(route1)
        route2 = np.copy(route2)
        
        if len(route1) < 2 or len(route2) < 1:
            return (route1, route2)
        
        if startNode1 == None:
            startNode1 = np.random.choice(route1[:-1])
        id1 = np.where(route1 == startNode1)[0][0]
        endNode1 = route1[id1+1]
        if node2 == None:
            node2 = np.random.choice(route2)
        
        route1 = self.OrOpt(np.append(route1[np.logical_and(
                route1 != startNode1, route1 != endNode1)], node2), node2)
        route2 = self.OrOpt2(np.append(route2[route2 != node2], 
                                       [startNode1, endNode1]), startNode1)
        
        return (route1, route2)
    
    # swap two consecutive nodes between two routes
    def SwapTwoTwo(self, route1, route2, startNode1 = None, startNode2 = None):
        route1 = np.copy(route1)
        route2 = np.copy(route2)
        
        if len(route1) < 2 or len(route2) < 2:
            return (route1, route2)
        
        if startNode1 == None:
            startNode1 = np.random.choice(route1[:-1])
        id1 = np.where(route1 == startNode1)[0][0]
        endNode1 = route1[id1+1]
        if startNode2 == None:
            startNode2 = np.random.choice(route2[:-1])
        id2 = np.where(route2 == startNode2)[0][0]
        endNode2 = route2[id2+1]
        
        route1 = self.OrOpt2(np.append(route1[np.logical_and(
                route1 != startNode1, route1 != endNode1)], 
                [startNode2, endNode2]), startNode2)
        route2 = self.OrOpt2(np.append(route2[np.logical_and(
                route2 != startNode2, route2 != endNode2)], 
                [startNode1, endNode1]), startNode1)
        
        return (route1, route2)
    
    # cut two nodes on random position and swap the sub-routes
    def Crossover(self, route1, route2):
        route1 = np.copy(route1)
        route2 = np.copy(route2)
                
        if len(route1) < 2 or len(route2) < 2:
            return (route1, route2)
        
        c1 = np.random.randint(len(route1)-1)
        c2 = np.random.randint(len(route2)-1)
        
        r1 = np.append(route1[:c1], route2[c2:])
        r2 = np.append(route2[:c2], route1[c1:])
        
        return (r1, r2)
    
    ######################################
    # Perturbation Structures
    ######################################
    
    # executes n Swap 1-1
    def MultiSwap(self, routes, n=2):
        r = []
        for route in routes:
            r.append(np.copy(route))
        
        if len(r) < 2:
            return r
        
        for i in range(n):
            (id1, id2) = np.random.permutation(len(r))[:2]
            r1 = r[id1]
            r2 = r[id2]
            (r[id1], r[id2]) = self.SwapOneOne(r1, r2)
        
        return r
    
    # executes n Shift 1-1
    def MultiShift(self, routes, n=2):
        r = []
        for route in routes:
            r.append(np.copy(route))
        
        if len(r) < 2:
            return r
        
        for i in range(n):
            (id1, id2) = np.random.permutation(len(r))[:2]
            r1 = r[id1]
            r2 = r[id2]
            (r[id1], r[id2]) = self.ShiftOneZero(r1, r2)
        
        return r
    
    # transfer one node from route i to route i+1
    def EjectionChain(self, routes):
        validRoutes = []
        allr = []
        r = []
        for route in routes:
            isValid = len(route) > 0
            validRoutes.append(isValid)
            allr.append(np.copy(route))
            if isValid:
                r.append(np.copy(route))
        
        if len(r) < 2:
            return allr
        
        movedNodes = [np.random.choice(r[i]) for i in range(len(r))]
        for i in range(len(r)-1):
            r[i+1] = self.OrOpt(np.append(r[i+1][r[i+1] != movedNodes[i+1]], 
             movedNodes[i]), movedNodes[i])
        r[0] = self.OrOpt(np.append(r[0][r[0] != movedNodes[0]], 
             movedNodes[-1]), movedNodes[-1])
        
        count = 0
        for i in range(len(validRoutes)):
            if validRoutes[i]:
                allr[i] = r[count]
                count += 1
        return allr
    
    # transfer all customers from a route to the other routes
    def EmptyRoute(self, routes, rid=-1):
        r = []
        for route in routes:
            r.append(np.copy(route))
        
        if len(r) < 2:
            return r
        
        receiveRoutes = np.array(range(len(r)))
        if rid == -1:
            rid = np.random.choice(receiveRoutes)
            
        receiveRoutes = receiveRoutes[receiveRoutes != rid]
        
        for node in r[rid]:
            insertRoute = np.random.choice(receiveRoutes)
            r[insertRoute] = self.OrOpt(r[insertRoute], node)
            
        return [r[i] for i in receiveRoutes]