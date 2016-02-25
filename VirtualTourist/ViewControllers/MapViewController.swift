//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Daniela Velasquez on 2/13/16.
//  Copyright © 2016 Mahisoft. All rights reserved.
//

import UIKit
import MapKit
import CoreData


//TODO: Adding loader when the pin is adding



class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager:CLLocationManager!
    var updating:Bool?
    var newPin:PinLocation?
    var dragEnded = false
    
    let regionRadius: CLLocationDistance = 1
    
    //MARK: Life Cycle Methods
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        loadPreviousLocation()
        
        //Init locationManager
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: "addAnnotation:"))
        
        
        //UITapGestureRecognizer UI
        loadPins()
        
        centerMapOnLocation()
    }
    
    override func viewWillAppear(animated: Bool) {
        
    }
    
    
    //MARK: IBAction Methods
    
    
    
    
    //MARK: Other Methods
    
    func centerMapOnLocation() {
        
        let zoom = PersistenceManager.instance.getCurrentZoom()
        let coord = PersistenceManager.instance.getCurrentLocation()
        
        
        if coord.latitude != 0 && coord.longitude != 0{
            let storedCamera = MKMapCamera(lookingAtCenterCoordinate: coord, fromEyeCoordinate: coord, eyeAltitude: CLLocationDistance(zoom))
            
            mapView.setCamera(storedCamera, animated: false)
        }
    }
    
    
    func loadPreviousLocation(){
        //TODO:
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if(segue.identifier == "showPhotoCollection"){
         
            let destination = (segue.destinationViewController as! ShowPhotoCollectionController)
            
            destination.pinLocation = newPin
            
        }
    }
    
    func addNewPin(pin: PinAnnotation){
        
        let newP = PersistenceManager.instance.savePin(pin.coordinate.latitude, lon: pin.coordinate.longitude)
        
        if newP != nil{
            
            loadPins()
            
            newPin = PinLocation(latitude: Double(newP!.lat!), longitude: Double(newP!.lon!), id: Int(newP!.identifier!))
            
            performSegueWithIdentifier("showPhotoCollection", sender: self)
        }else{
            showAlert("Could not save pin", viewController: self)
        }
     
    }
    
    
    /**
     * Tap Gesture Recognizer action.
     * Adding a pinAnnotation in the map and save info in persistence.
     * @param: gestureRecognizer (TapGestureRecognizer)
     */
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
    
        let touchPoint = gestureRecognizer.locationInView(mapView)
        let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = PinAnnotation(id: nil, coordinate: newCoordinates)
        
        if gestureRecognizer.state == .Ended{
            
            //TODO: Show loader
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoordinates.latitude,
                longitude: newCoordinates.longitude),
                completionHandler: {(placemarks, error) -> Void in
                    
                    //TODO: Hide loader
                    if error != nil {
                        showAlert("Reverse geocoder failed with error" + error!.localizedDescription, viewController: self)
                        return
                    }
                    
                    self.mapView.addAnnotation(annotation)
                    
                    self.addNewPin(annotation)
                    
            })
        }
    }
    
    /**
     * Load persistence pins.
     */
    func loadPins(){
        
        let pins = PersistenceManager.instance.getLocationPins()
        
        guard pins.count > 0 else{
            showAlert(Messages.mNoPins, viewController: self)
            return
        }
   
        for sLocation in pins{
            
            let lat = sLocation.valueForKey("lat") as! NSNumber
            let lon = sLocation.valueForKey("lon") as! NSNumber
            let id = sLocation.valueForKey("identifier") as! NSNumber
            
            
            let annotation = PinAnnotation(id: id.integerValue,
                coordinate:  CLLocationCoordinate2D(latitude: lat.doubleValue, longitude: lon.doubleValue))
            
            //Add pin annotation in the map
            mapView.addAnnotation(annotation)
        }
    }
    
    func updatePin(pin: PinAnnotation) {
        /*if !pin.photos.isEmpty {
            for photo in pin.photos {
                photo.pin = nil
            }
        }
        if !pin.places.isEmpty {
            for place in pin.places {
                place.pin = nil
            }
        }
        CoreDataStackManager.sharedInstance.saveContext()
        getFlickrPhotoProperties(pin)*/
    }
    
    
}


extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? PinAnnotation {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? MKPinAnnotationView {
                    dequeuedView.annotation = annotation
                    view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.animatesDrop = true
                view.draggable = true
            
                view.setSelected(true, animated: false)
            }
            return view
        }
        
        return nil
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView){
        
        mapView.deselectAnnotation(view.annotation, animated: false)
        view.setSelected(true, animated: false)
        
        let pin = view.annotation as! PinAnnotation
        
        //Update Pin
        if dragEnded == true {
            updatePin(pin)
            dragEnded = false
            return
        }
        
        let newP = PersistenceManager.instance.getPin(pin.id!)
        newPin = PinLocation(latitude: Double(newP.lat!), longitude: Double(newP.lon!), id: Int(newP.identifier!))
        performSegueWithIdentifier("showPhotoCollection", sender: self)
        
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
       PersistenceManager.instance.saveCurrentLocation(mapView.centerCoordinate.latitude, lon: mapView.centerCoordinate.longitude)
        
       PersistenceManager.instance.saveCurrentZoom(mapView.camera.altitude)
        
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        if newState == MKAnnotationViewDragState.Ending {
            dragEnded = true
        }
    }
}

extension MapViewController: CLLocationManagerDelegate{
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let coord = PersistenceManager.instance.getCurrentLocation()
        
        
        if coord.latitude == 0 && coord.longitude == 0{
        
            let userLocation:CLLocation = locations[0]
            //Set initial location
            let initialLocation = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
            
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate,
                regionRadius * 2.0, regionRadius * 2.0)
            
            mapView.setRegion(coordinateRegion, animated: true)

        }

    }
    
}

