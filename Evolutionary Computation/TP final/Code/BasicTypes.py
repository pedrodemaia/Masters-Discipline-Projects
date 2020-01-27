# -*- coding: utf-8 -*-
"""
Created on Thu Sep 12 19:00:48 2019

@author: pedro
"""

class Depot:
    def __init__(self, name, pos):
        self.Name = name # depot name
        self.Position = pos # geographic position
        self.ServiceTime = 0 # service time
        
    def __repr__(self):
        return 'Depot_' + self.Name
    
    def __str__(self):
        return 'Depot_' + self.Name
    
    def __hash__(self):
        return hash(self.Name)
        
class Customer:
    def __init__(self, name, pos, timeWindow = (0, 1e6), serviceTime = 0):
        self.Name = name # customer name
        self.Position = pos # geographic position
        self.Demands = [] # list of demands
        self.ServiceTime = serviceTime # service time
        self.TimeWindow = timeWindow # attendance window

    def __repr__(self):
        return 'Customer_' + self.Name
    
    def __str__(self):
        return 'Customer_' + self.Name
    
    def __hash__(self):
        return hash(self.Name)

class Demand:    
    def __init__(self, demId, value):
        self.Id = demId # demand ID
        self.Value = value # demand volume
        
    def __repr__(self):
        return 'Value_' + str(self.Value)
    
    def __hash__(self):
        return hash(self.Id)
        
class Vehicle:
    def __init__(self, id, depot, capacity, workHours):
        self.Id = id # vechile ID
        self.Depot = depot # base depot
        self.Capacity = capacity # vehicle capacity
        self.MaxTime = workHours # maximum work hours
        
    def __repr__(self):
        return 'Vehicle' + str(self.Id) + '-Base' + self.Depot.Name + \
    '-Capacity' + str(self.Capacity)
    
    def __hash__(self):
        return hash(self.Id)