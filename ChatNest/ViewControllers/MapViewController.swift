import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate {
    
    var messages: [Message] = []
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBAction func closeMap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        LocationManager.shared.start()
        // draw the region in mapview
        findCoordinates()
        self.mapView.showsUserLocation = true
        
        NSLog("Got messages \(String(describing: messages.count))")
        messages.forEach() { item in
            plotUsersOnGraph(latitude: item.latitude, longitude: item.longitude, title: item.senderName, subtitle: item.text)
            
        }
        
    }
    
    func plotUsersOnGraph(latitude:Double,longitude:Double,title:String,subtitle:String){
        
        let userlocation = CLLocationCoordinate2DMake(latitude, longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = userlocation
        annotation.title = title
        annotation.subtitle = subtitle
        mapView.addAnnotation(annotation)
    }
    
    //this function returns boundary coordinates for box
    func findCoordinates() {
        
        let messageWithMaxLat = messages.max { left, right -> Bool in
            return left.latitude > right.latitude
        }
        
        let messageWithMinLat = messages.min { left, right -> Bool in
            return left.latitude < right.latitude
        }
        
        let messageWithMaxLon = messages.max { left, right -> Bool in
            return left.longitude > right.longitude
        }
        
        let messageWithMinLon = messages.min { left, right -> Bool in
            return left.longitude < right.longitude
        }
        
        guard  let latMax = messageWithMaxLat?.latitude else {
            return
        }
        guard let latMin = messageWithMinLat?.latitude else {
            return
        }
        guard let lonMax = messageWithMaxLon?.longitude else {
            return
        }
        guard  let lonMin = messageWithMinLon?.longitude else {
            return
        }
        
        guard let userLoc = LocationManager.shared.coord else {
            return
        }
        
        
        //mapReg = MKMapView(frame: CGRect(x: longMin, y: latMax, width: longMin - longMax, height: latMax - latMin))
        let mapSpan = MKCoordinateSpan(latitudeDelta: latMax - latMin, longitudeDelta: lonMin - lonMax)
        let mapReg = MKCoordinateRegionMake(userLoc, mapSpan)
        self.mapView.setRegion(mapReg, animated: true)
    }
    
}

