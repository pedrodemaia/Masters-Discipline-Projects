#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Aug 20 16:46:52 2019

@author: pedro

https://medium.com/@robertopreste/from-xml-to-pandas-dataframes-9292980b1c1c

https://stackabuse.com/reading-and-writing-xml-files-in-python/
"""

import xml.etree.ElementTree as et
import pandas as pd
import numpy as np
import BasicTypes as bt

class Instance:    
    def __init__(self, file=None, numberVehicles=None, source='', 
                 numCustomers=1000):
        basepath = '../../Datasets/'
        
        if source == 'Solomon':
            basepath = basepath+'Solomon/'
            
            # load data from file
            data = pd.read_csv(basepath+file+'.csv')
            generalData = pd.read_csv(basepath+'GeneralData.csv', sep=',')
            
            # load depot information
            depot = bt.Depot(str(1), (data.loc[0].xPos, data.loc[0].yPos))
            
            # load vehicle information
            if numberVehicles == None:
                numberVehicles = generalData[generalData.Problem == file].NV.item()
            capacity = generalData[generalData.Problem == file].Capacity.item()
            totalTime = data.loc[0]['Due Date']
            
            vehicles = []
            for i in range(numberVehicles):
                vehicles.append(bt.Vehicle(i+1, depot, capacity, totalTime))
                
            # load customers information
            numCustomers = min(len(data), numCustomers+1)
            customers = []
            for i in range(1,numCustomers):
                xpos = data.loc[i]['xPos']
                ypos = data.loc[i]['yPos']
                demandVol = data.loc[i]['Demand']
                startTime = data.loc[i]['Ready Time']
                endTime = data.loc[i]['Due Date']
                serviceTime = data.loc[i]['Service Time']
                
                customer = bt.Customer(str(i), (xpos, ypos), 
                                       (startTime, endTime), serviceTime)
                
                demand = bt.Demand(i, demandVol)
                customer.Demands.append(demand)
                customers.append(customer)
                
        elif source == 'Mendoza':   
            basepath = basepath+'Mendoza/'
            dataset = et.parse(basepath+file)
            root = dataset.getroot()
            
            nodes = root.find('network').find('nodes')
            
            depotId = []
            customerIds = []
            positions = {}
            
            for node in nodes:
                elemId = node.attrib['id']
                
                if int(node.attrib['type']):
                    customerIds.append(elemId)
                else:
                    depotId = elemId
                    
                cx = float(node.find('cx').text)
                cy = float(node.find('cy').text)
                
                positions[elemId] = (cx, cy)
            
            vehicleData = root.find('fleet').find('vehicle_profile')
                
            vehicleParams = {'Departure' : vehicleData.find('departure_node').text,
                        'Arrival' : vehicleData.find('arrival_node').text,
                        'Capacity' : float(vehicleData.find('capacity').text),
                        'TravelTime' : float(vehicleData.find('max_travel_time').text)}
            
            demandsData = root.find('requests')
            
            demands = {}
            
            for demand in demandsData:
                customer = demand.attrib['node']
                demValue = demand.find('uncertain_quantity').find('random_variable')
                value = float(demValue.find('parameter').text)
                
                demands[customer] = {'Value' : value}
                
            depot = bt.Depot(depotId, positions[depotId])
            
            customers = []
            demId = 1;
            for customerId in customerIds:
                customer = bt.Customer(customerId, positions[customerId])
                demand = bt.Demand(demId, demands[customerId]['Value'])
                demId += 1
                customer.Demands.append(demand)
                customers.append(customer)
            
            
            vehicles = []
            for i in range(numberVehicles):
                vehicles.append(bt.Vehicle(i+1, vehicleParams['Departure'], 
                                     vehicleParams['Capacity'],
                                     vehicleParams['TravelTime']))
        else:
            positions = [(150, 250), (151, 264), (159, 261), (130, 254), 
                         (128, 252), (163, 247), (146, 246), (161, 242),
                         (142, 239), (163, 236), (148, 232)]
            demands = [0, 1.1, 0.7, 0.8, 0.4, 2.1, 0.4, 0.8, 0.1, 0.5, 0.6]
            numberVehicles = 4
            capacity = 3
            totalTime = 1e4
            serviceTime = 0
            
            depot = bt.Depot('1', positions[0])
            
            vehicles = []
            for i in range(numberVehicles):
                vehicles.append(bt.Vehicle(i+1, depot, capacity, totalTime))
                
            customers = []
            for i in range(1, len(positions)):
                customer = bt.Customer(str(i), positions[i], 
                                       (0, totalTime), serviceTime)
                
                demand = bt.Demand(i, demands[i])
                customer.Demands.append(demand)
                customers.append(customer)
            
        # save information    
        self.Depot = depot
        self.Customers = customers
        self.Vehicles = vehicles