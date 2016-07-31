//
//  ViewController.swift
//  FloodWaters
//
//  Created by Matt Milner on 7/28/16.
//  Copyright © 2016 Matt Milner. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CloudKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager: CLLocationManager!
    var selectedAnnotation: MKAnnotation!
    var container: CKContainer!
    var publicDB: CKDatabase!
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.mapView.delegate = self
        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        
        self.locationManager.requestWhenInUseAuthorization()
        
        self.locationManager.startUpdatingLocation()
        
        self.mapView.showsUserLocation = true
        
        self.container = CKContainer.defaultContainer()
        self.publicDB = self.container.publicCloudDatabase
        
        populateFloodLocations()
        
        
    }
    
    private func populateFloodLocations() {
        
        let query = CKQuery(recordType: "FloodWaters", predicate: NSPredicate(format: "name = %@", "location"))
        
        self.publicDB.performQuery(query, inZoneWithID: nil) { (records: [CKRecord]?, error: NSError?) in
            
            for record in records!{
                let newLocation = record["coordinate"] as! CLLocation
                let newCoordinate = newLocation.coordinate
                
                let floodLocationAnnotation = MKPointAnnotation()
                floodLocationAnnotation.title = "High Waters Reported"
                floodLocationAnnotation.coordinate = newCoordinate
                
                self.mapView.addAnnotation(floodLocationAnnotation)
                
            }
            
            print("records fetched successfully")
        }
        
        
        
    }
    
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        
        let floodLocationAnnotation = MKPointAnnotation()
        floodLocationAnnotation.title = "High Waters Reported"
        floodLocationAnnotation.coordinate = self.mapView.userLocation.coordinate
        
        let savableAnnotation = CLLocation(coordinate: floodLocationAnnotation.coordinate, altitude:0, horizontalAccuracy: kCLLocationAccuracyBest, verticalAccuracy: kCLLocationAccuracyBest, timestamp: NSDate())
        
        let annotationRecord = CKRecord(recordType: "FloodWaters")
        annotationRecord["coordinate"] = savableAnnotation
        annotationRecord["name"] = "location"
        
        self.publicDB.saveRecord(annotationRecord) { (record: CKRecord?, error: NSError?) in }
        
        
        self.mapView.addAnnotation(floodLocationAnnotation)
   
        
    }
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        
        if let annotationView = views.first {
            
            if let annotation = annotationView.annotation {
                if annotation is MKUserLocation {
                    
                    let region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 450, 450)
                    self.mapView.setRegion(region, animated: true)
            
                }

            }
            
        }
        
        
        
        
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        self.selectedAnnotation = view.annotation
        
    
    }
    
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
      
        let currentAnnotationPicture = UIImage(named: "floodAnnotation.png")
        
        var floodAnnotationView = self.mapView.dequeueReusableAnnotationViewWithIdentifier("FloodAnnotationView")
        
        
        if floodAnnotationView == nil {
            floodAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "FloodAnnotationView")

        } else {
            floodAnnotationView?.annotation = annotation

        }
        
        floodAnnotationView?.frame = CGRectMake(0, 0, 50, 50)

        let floodImageView = UIImageView(image: currentAnnotationPicture)
        
        floodImageView.frame.size = CGSize(width: 50, height:  50)
        
      
        
        floodAnnotationView?.image = currentAnnotationPicture
        floodAnnotationView?.frame = CGRectMake(0, 0, 50, 50)
        
        
        
        
        floodAnnotationView?.userInteractionEnabled = true
        
        floodAnnotationView!.canShowCallout = true
        
        let leftCalloutView = UIView(frame: CGRectMake(0,0,30,30))
        
        let cautionImage = UIImageView(frame: CGRectMake(0, 0, 30, 30))
        cautionImage.image = UIImage(named: "floodAnnotation.png")
        
        leftCalloutView.addSubview(cautionImage)
        
        
        let rightCalloutView = UIView(frame: CGRectMake(0,0,80,80))
        rightCalloutView.backgroundColor = UIColor.redColor()
        
        let deleteButton = UIButton(frame: CGRectMake(0,-15,80,80))
        deleteButton.titleLabel?.textColor = UIColor.whiteColor()
        deleteButton.setTitle("Delete", forState: UIControlState.Normal)
        deleteButton.addTarget(self, action: #selector(removeAnnotation), forControlEvents:UIControlEvents.TouchUpInside)
        rightCalloutView.addSubview(deleteButton)
        
        
        floodAnnotationView!.leftCalloutAccessoryView = leftCalloutView
        floodAnnotationView!.rightCalloutAccessoryView = rightCalloutView

        
        return floodAnnotationView
        
    }
    
    
    func removeAnnotation() {
        
       let query = CKQuery(recordType: "FloodWaters", predicate: NSPredicate(format: "name = %@", "location"))
        
        self.publicDB.performQuery(query, inZoneWithID: nil) { (records: [CKRecord]?, error: NSError?) in
            
            if let records = records {
                
                for record in records {
                    
                    let recordCoordinate = record["coordinate"] as! CLLocation
                    let selectedCoordinateLong = recordCoordinate.coordinate.longitude
                    let selectedAnnotationCoordinateLong = self.selectedAnnotation.coordinate.longitude
                    let selectedCoordinateLat = recordCoordinate.coordinate.latitude
                    let selectedAnnotationCoordinateLat = self.selectedAnnotation.coordinate.latitude
    
                    if(selectedCoordinateLong == selectedAnnotationCoordinateLong && selectedCoordinateLat == selectedAnnotationCoordinateLat ){
                        self.publicDB.deleteRecordWithID(record.recordID, completionHandler: { (recordId: CKRecordID?, error: NSError?) in })
                        print("record successfully removed from database!")
                    }
                }

            }
            
            
            
            
            
        }
        
       mapView.removeAnnotation(self.selectedAnnotation)
        
        
        
        
        
    }
    
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        
    }


}

