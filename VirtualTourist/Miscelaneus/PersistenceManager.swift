//
//  PersistenceManager.swift
//  VirtualTourist
//
//  Created by Daniela Velasquez on 2/22/16.
//  Copyright © 2016 Mahisoft. All rights reserved.
//

import UIKit
import CoreData
import MapKit


class PersistenceManager: NSObject {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    let managedContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    class var instance: PersistenceManager {
        
        struct Static {
            static var instance: PersistenceManager?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = PersistenceManager()
        }
        
        return Static.instance!
    }
    
    required override init(){
        
    }
    
 
    func saveCurrentZoom(zoom:Double){
        NSUserDefaults.standardUserDefaults().setDouble(zoom, forKey: "userZoom")
    }
    
    func getCurrentZoom()-> Double{

        let zoom = NSUserDefaults.standardUserDefaults().doubleForKey("userZoom")
    
        return zoom
    }
    
    func saveCurrentLocation(lat:Double, lon:Double){
        NSUserDefaults.standardUserDefaults().setDouble(lat, forKey: "userLat")
        NSUserDefaults.standardUserDefaults().setDouble(lon, forKey: "userLon")
    }
    
    func getCurrentLocation()-> CLLocationCoordinate2D{
        
        let lat = NSUserDefaults.standardUserDefaults().doubleForKey("userLat")
        let lon = NSUserDefaults.standardUserDefaults().doubleForKey("userLon")
        
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        return coord
    }
    
    func getLocationPins() -> [Pin]{
        
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            
            let results = try managedContext.executeFetchRequest(fetchRequest)
            
            return results as! [Pin]
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return [Pin]()
        }
        
    }
    

    func getPin(id: Int) -> Pin{
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", NSNumber(integer: id))
        
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            
            guard results.count != 0 else{
                return Pin()
            }
            
            return results[0] as! Pin
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return Pin()
        }
    
    }
    
    //MARK: Save Methods
    
    func savePin(lat: NSNumber, lon: NSNumber) -> Pin?{
        
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext:managedContext)
        
        let pin = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        
        let pins = getLocationPins()
        
        pin.setValue(pins.count, forKey: "identifier")
        pin.setValue(lat, forKey: "lat")
        pin.setValue(lon, forKey: "lon")
        
        do {
            try managedContext.save()
            return getPin(pins.count)
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
            return nil
        }
    }
    
    
    func savePhoto(pin: Pin, imagePath: String, name: String){
        let photo = Photo(name: name , imageUrl: imagePath, context: managedContext)
        photo.pin = pin
    }
    
    
    //MARK:
    func saveContext() {
        
        if managedContext.hasChanges {
            do {
                try managedContext.save()
            } catch {
                print("saveContext() error: \(error)")
                abort()
            }
        }
        
    }
}
