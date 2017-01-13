//
//  ViewController.swift
//  PokeFinder
//
//  Created by Rafsan Chowdhury on 1/12/17.
//  Copyright © 2017 Mcraf. All rights reserved.
//

import UIKit
import GeoFire
import MapKit
import FirebaseDatabase
class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    let annoIdentifier = "Pokemon"
    let locationManager = CLLocationManager()
    var maphasCenteredOnce = true
    var geoFire: GeoFire!
    var geoFireRef: FIRDatabaseReference! // Read documentation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.userTrackingMode = MKUserTrackingMode.follow //Follows the user
        
        geoFireRef = FIRDatabase.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    func locationAuthStatus() { //ASKS FOR AUTHORIZATION
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
        
    }
    
    //When the user says yes or no we are gonna call this function
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse { //If they say yes lets just show user location on the map
            mapView.showsUserLocation = true
        }
    }
    
    //To Center the map 
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000) // Center em in 2000*2000 meters radius
        
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    //When user location is actually updated
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if let loc = userLocation.location {
            // We dont want to set it back to userlocation every single time and zoom in since they could be walking
            if !maphasCenteredOnce {
                centerMapOnLocation(location: loc)
                maphasCenteredOnce = true
            }
        }
    }
    
    // Have no clue whats going on the function below. AnnotationView is used to annotate the map MAYBE :?
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView: MKAnnotationView?
        
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
        } else if let deqAnno = mapView.dequeueReusableAnnotationView(withIdentifier: annoIdentifier) {
            annotationView = deqAnno
            annotationView?.annotation = annotation
        } else {
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annoIdentifier)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = av
        }
        
        if let annotationView = annotationView, let anno = annotation as? PokeAnnotation {
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "\(anno.pokemonNumber)")
            let btn = UIButton()
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30) // Button with a map
            btn.setImage(UIImage(named:"map"), for: .normal)
        }
        return annotationView
    }
    
    // If you spot a pokemon and you wanna report it use this function 
    
    func createSighting(forLocation location: CLLocation, withPokemon pokeId: Int) {
        geoFire.setLocation(location, forKey: "\(pokeId)") //Saving information
    }
    
    func showSightingsOnMap (location: CLLocation) {
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        
        _ = circleQuery?.observe(GFEventType.keyEntered, with: { (key, location) in
            if let key = key, let location = location {
                let anno = PokeAnnotation(coordinate: location.coordinate, pokemonNumber: Int(key)!)
                self.mapView.addAnnotation(anno) // Add to the map
            }
        })
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        showSightingsOnMap(location: loc)
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let anno = view.annotation as? PokeAnnotation {
            let place = MKPlacemark(coordinate: anno.coordinate)
            let destination = MKMapItem(placemark: place)
            destination.name = "Pokemon Sighting!"
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)
            
            let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String : Any]
            
            MKMapItem.openMaps(with: [destination], launchOptions: options)
            
        }
    }
    
    @IBAction func randomPokeBtnPressed(_ sender: Any) {
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        let rand = arc4random_uniform(151) + 1
        createSighting(forLocation: loc, withPokemon: Int(rand))
    }
    


}

