//
//  ViewController.swift
//  2GIS
//
//  Created by admin on 28.11.2021.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell",for: indexPath)
        cell.textLabel?.text = places[indexPath.row].title
        cell.detailTextLabel?.text = places[indexPath.row].subtitle
        cell.backgroundColor = UIColor(white: 1, alpha: 0.3)
        return cell
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            deleteLocation(places[indexPath.row])
            places = loadLocation()
            addAnnotation()
            tableView.reloadData()
        }
        else if editingStyle == .insert{
            
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let location = CLLocation(latitude: places[indexPath.row].latitude, longitude: places[indexPath.row].longitude)
        mapView.centerLocation(location, regionRadius: 1000)
        tableView.isHidden = true
        clicked = false
        self.navigationItem.title = places[indexPath.row].title
    }
    
    
    public var arr = [MKPointAnnotation]()
    var pinAnnotationView:MKPinAnnotationView!
    var places: [Place] = []
    var clicked: Bool!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBAction func dataPressed(_ sender: Any) {
        hideTable()
    }
    func hideTable() {
        if clicked == false {
            clicked = true
            tableView.isHidden = false
        } else {
            clicked = false
            tableView.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clicked = false
        tableView.isHidden = true
        
        let initialLocation = CLLocation(latitude: 43.2407, longitude: 76.9286)
        mapView.centerLocation(initialLocation)
        
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(createNewAnnotation))
        uilpgr.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(uilpgr)
        
        places = loadLocation()
        mapView.delegate = self
        addAnnotation()
        
        tableView.backgroundColor = UIColor.clear
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        tableView.backgroundView = blurEffectView
        
    }
    
    func addAnnotation(){
        
        for place in places{
            let point = MKPointAnnotation()
            point.title = place.title
            point.subtitle = place.subtitle
            point.coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            arr.append(point)
        }
        self.mapView.addAnnotations(arr)
        tableView.reloadData()
    }
    @IBAction func segmentedControl(_ sender: UISegmentedControl) {
        mapView.mapType = MKMapType.init(rawValue: UInt(sender.selectedSegmentIndex)) ?? .standard
    }
    @objc func createNewAnnotation(_ sender: UIGestureRecognizer) {
        let touchPoint = sender.location(in: self.mapView)
        
        let coordinates = mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
        
        let heldPoint = MKPointAnnotation()
        heldPoint.coordinate = coordinates
        
        if (sender.state == .began) {
            let alert = UIAlertController(title: "Add Place", message: "Fill all the fields", preferredStyle: .alert)
            let saveAction = UIAlertAction(title: "Save", style: .default){
                (UIAlertAction) in
                let title = alert.textFields?[0].text ?? ""
                let subtitle = alert.textFields?[1].text ?? ""
                
                heldPoint.title = title
                heldPoint.subtitle = subtitle
                self.mapView.addAnnotation(heldPoint)
                self.saveLocation(title,subtitle,coordinates.latitude as Double,coordinates.longitude as Double)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addTextField{
                (textField) in textField.placeholder = "Title"
            }
            alert.addTextField{
                (textField) in textField.placeholder = "Subtitle"
            }
            alert.addAction(saveAction)
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
        }
        
    }
    func loadLocation() -> [Place]{
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate{
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<Place>(entityName: "Place")
            do{
                try places = context.fetch(fetchRequest)
                tableView.reloadData()
                addAnnotation()
            }catch{
                print("load location")
            }
        }
        return places
    }
    func saveLocation(_ title:String, _ subtitle:String,_ latitude: Double, _ longitude: Double){
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate{
            let context = appDelegate.persistentContainer.viewContext
            if let entity = NSEntityDescription.entity(forEntityName: "Place", in: context){
                let place = NSManagedObject(entity: entity, insertInto: context)
                place.setValue(title, forKey: "title")
                place.setValue(subtitle, forKey: "subtitle")
                place.setValue(latitude, forKey:
                                "latitude")
                place.setValue(longitude, forKey:
                                "longitude")
                do{
                    try context.save()
                    places.append(place as! Place)
                    tableView.reloadData()
                    addAnnotation()
                    
                }catch{
                    print("save location")
                }
            }
        }
    }
    func deleteLocation(_ object: Place){
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate{
            let context = appDelegate.persistentContainer.viewContext
            context.delete(object)
            do{
                try context.save()
                tableView.reloadData()
                addAnnotation()
            }catch{
                print("delete")
            }
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "marker"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            
            let btn = UIButton(type: .detailDisclosure)
            
            annotationView?.rightCalloutAccessoryView = btn
            btn.addTarget(self, action: #selector(edit), for: UIControl.Event.touchUpInside)
        } else {
            // 6
            annotationView?.annotation = annotation
        }
        return annotationView
    }
//    func mapView(_: MKMapView, didSelect: MKAnnotationView){
//
//    }

    @objc func edit(sender:UIButton!) {
            performSegue(withIdentifier: "mySegue", sender: nil)
        }
//    func editPlace(title:String,subtitle:String){
////        places
//    }

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//    let index = mapView
//       (tableView.indexPathForSelectedRow?.row)!
//        let destinationNavigationController = segue.destination as! UINavigationController
//        let targetController = destinationNavigationController.topViewController as! EditVC
//      targetController.name.text = places[index].title
//      targetController.subtitle.text = places[index].subtitle
//    }
    
}

extension MKMapView {
    func centerLocation(_ location: CLLocation, regionRadius:CLLocationDistance = 1000){
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        setRegion(coordinateRegion, animated: true)
    }
}

