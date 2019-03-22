import UIKit
import MapKit
import Kingfisher

@IBDesignable
class CustomSearchBar: UISearchBar {
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            return layer.cornerRadius = cornerRadius
        }
    }
}

class HomeViewController: UIViewController, UISearchBarDelegate, MKMapViewDelegate {
    
    var matchingItems: [MKMapItem] = [MKMapItem]()
    var restaurants: [Businesses] = []
    var selectedAnnotation: MKPointAnnotation?
    var mapAddress: String?
    
    // Outlets
    @IBOutlet weak var searchBarMap: CustomSearchBar!
    @IBOutlet weak var homeMapView: MKMapView!
    
    // 6) location manager Need for user location
    let locationManager = CLLocationManager()
    var currentCoordinate: CLLocationCoordinate2D?
    var selectedRestaurant: Businesses?
    
    func fromYelp() {
        matchingItems.removeAll()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarMap.text
        request.region = homeMapView.region
        
        let search = MKLocalSearch(request: request)
        search.start(completionHandler: { [unowned self] (response, error) in
            guard let searchText = self.searchBarMap.text, !searchText.isEmpty else {
                AlertHelper.showNoSearchTextAlert(vc: self)
                return
            }
            
            if error != nil || response == nil {
                AlertHelper.showNoSearchResultsAlert(vc: self, searchTerm: searchText)
                return
            }
            
            // Remove current annotations on map
            let annotations = self.homeMapView.annotations
            self.homeMapView.removeAnnotations(annotations)
            // Getting data
            guard let latitude = response?.boundingRegion.center.latitude else { return }
            guard let longitude = response?.boundingRegion.center.longitude else { return }
            
            RestaurantInfoController.fetchRestaurantInfo(withSearchTerm: searchText, latitude: latitude, longitude: longitude) { (businesses) in
                if let businesses = businesses {
                    self.restaurants = businesses
                    
                }
                
                for objects in RestaurantInfoController.restaurants {
                    print("Name = \(objects.restaurantName ?? "No match")")
                    print("Phone = \(objects.restaurantPhone ?? "No Match")")
                    print("Matching items = \(self.matchingItems.count)")
                    
                    guard let lat = objects.coordinate?.latitude,
                        let log =  objects.coordinate?.longitude else { return }
                    
                    let coordinate = self.getCordinate(latitude: lat, longitude: log)
                    
                    // TODO: - remove unnecessary code from main thread
                    DispatchQueue.main.async {
                        let point = CustomAnnotation(coordinate: coordinate, restaurant: objects)
                        
                        self.homeMapView.addAnnotations([point])
                        
                        //Zooming in on annotation
                        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
                        let span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                        let region = MKCoordinateRegion(center: coordinate, span: span)
                        self.homeMapView.setRegion(region, animated: true)
                    }
                }
            }
        })
    }
    
    func getCordinate(latitude: Double, longitude: Double) -> CLLocationCoordinate2D {
        let lat = CLLocationDegrees(latitude)
        let log =  CLLocationDegrees(longitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: log)
        return coordinate
    }
    
    // Adding custom pins
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?  {
        if annotation is MKUserLocation {
            return nil
        }
        var annotationView = self.homeMapView.dequeueReusableAnnotationView(withIdentifier: "Pin")
        if annotationView == nil {
            annotationView = AnnotationView(annotation: annotation, reuseIdentifier: "Pin")
            annotationView?.canShowCallout = false
        } else {
            annotationView?.annotation = annotation
        }
        annotationView?.image = UIImage(named: "pin")
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // 1
        if view.annotation is MKUserLocation {
            // Don't proceed with custom callout
            return
        }
        
        // 2
        let customAnnotation = view.annotation as! CustomAnnotation
        let views = Bundle.main.loadNibNamed("CalloutView", owner: nil, options: nil)
        let calloutView = views?[0] as! CalloutView
        
        calloutView.restaurant = customAnnotation.restaurant
        calloutView.delegate = self
        
        // Returns just the street name capitalized. Required to match database naming conventions.
        let address = customAnnotation.restaurant.location?.displayAddress[0].truncate(endingCharacter: ",")
        mapAddress = address?.uppercased()
        
        if let imageUrl = URL(string: customAnnotation.restaurantImageUrlString) {
            let imageTransition = ImageTransition.fade(0.2)
            
            DispatchQueue.main.async {
                calloutView.restaurantImage.kf.indicatorType = .activity
                calloutView.restaurantImage.kf.setImage(with: imageUrl, options: [.transition(imageTransition)])
            }
        }
        
        // 3
        calloutView.center = CGPoint(x: view.bounds.size.width / 2, y: -calloutView.bounds.size.height * 0.52)
        view.addSubview(calloutView)
        mapView.setCenter((view.annotation?.coordinate)!, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if view.isKind(of: AnnotationView.self) {
            for subview in view.subviews {
                subview.removeFromSuperview()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarItems()
        homeMapView.showsUserLocation = true
        homeMapView.delegate = self
        searchBarMap.backgroundImage = UIImage()
        searchBarMap.delegate = self
        searchBarMap.layer.cornerRadius = searchBarMap.bounds.height / 2
        searchBarMap.clipsToBounds = true
        searchBarMap.layer.shadowColor = UIColor.darkGray.cgColor
        searchBarMap.layer.shadowOffset = CGSize(width: 1, height: 1)
        searchBarMap.layer.shadowRadius = 2
        searchBarMap.layer.shadowOpacity = 0.65
        configureLocationServices()
        let scale = MKScaleView(mapView: homeMapView)
        scale.scaleVisibility = .visible // always visible
        view.addSubview(scale)
        
        //        guard let y = navigationController?.navigationBar.frame.size.height else { return }
        //        let y2 = y + 10
        //        let size = CGSize(width: self.view.frame.width, height: y2)
        //        navigationController?.navigationBar.sizeThatFits(size)
        //        let logo = UIImage(named: "DineRiteNew")
        //        var imageView = UIImageView()
        //        imageView = UIImageView(image: logo)
        //        imageView.contentMode = .scaleAspectFit
        //
        //        navigationController?.navigationBar.addSubview(imageView)
        //        imageView.translatesAutoresizingMaskIntoConstraints = false
        //        guard let navBar = navigationController?.navigationBar else { return }
        //        imageView.topAnchor.constraint(equalTo: navBar.topAnchor, constant: 0).isActive = true
        //        imageView.bottomAnchor.constraint(equalTo: navBar.bottomAnchor, constant: -15).isActive = true
        //        imageView.centerXAnchor.constraint(equalTo: navBar.centerXAnchor).isActive = true
        //        imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        //        imageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func setupNavigationBarItems() {
        let logo = UIImage(named: "DineRiteNew")
        var imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 5))
        imageView = UIImageView(image: logo)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView
    }
    //
    //    func setUpNavHeight() {
    //        guard let y = navigationController?.navigationBar.frame.origin.y else { return }
    //        let y2 = y + 20
    //        let size = CGSize(width: self.view.frame.width, height: y2)
    //        navigationController?.navigationBar.sizeThatFits(size)
    //    }
    
    //    func setUpNavbarHeight() {
    //        for subview in (self.navigationController?.navigationBar.subviews)! {
    //            if NSStringFromClass(subview.classForCoder).contains("BarBackground") {
    //                var subViewFrame: CGRect = subview.frame
    //                let subView = UIView()
    //
    //                subViewFrame.size.height = 90
    //                subView.frame = subViewFrame
    //                // Convert an image view to a view
    //                // Constrain it to the center and size it
    //                let logo = UIImage(named: "DineRiteNew")
    //                var imageView = UIImageView()
    //                imageView = UIImageView(image: logo)
    //                imageView.contentMode = .scaleAspectFit
    //
    //                subView.addSubview(imageView)
    //                imageView.translatesAutoresizingMaskIntoConstraints = false
    //                imageView.topAnchor.constraint(equalTo: subView.topAnchor, constant: 0).isActive = true
    //                imageView.bottomAnchor.constraint(equalTo: subView.bottomAnchor, constant: -15).isActive = true
    //                imageView.centerXAnchor.constraint(equalTo: subView.centerXAnchor).isActive = true
    //                imageView.widthAnchor.constraint(equalToConstant: 114).isActive = true
    //                imageView.heightAnchor.constraint(equalToConstant: 35).isActive = true
    //                subview.backgroundColor = .clear
    //
    //                navigationController?.navigationBar.addSubview(subView)
    //            }
    //        }
    //    }
    
    // Action for the searchBar on the MAP
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBarMap.resignFirstResponder()
        //        performSearch()
        fromYelp()
        zoomToLatestLocation(with: currentCoordinate!)
    }
    
    // Function for finding the user location
    // 1 Authorization for user to access maps
    func configureLocationServices() {
        locationManager.delegate = self
        
        let status = CLLocationManager.authorizationStatus()
        
        if status == .restricted ||
            status == .denied ||
            status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedAlways || status == .authorizedWhenInUse{
            beginLocationUpdates(locationManager: locationManager)
        }
    }
    
    // 2 Function for giving the desired user's location
    func beginLocationUpdates(locationManager: CLLocationManager) {
        homeMapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    // 3 Function for zooming into user's location
    func zoomToLatestLocation(with coordinate: CLLocationCoordinate2D) {
        let zoomRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        homeMapView.setRegion(zoomRegion, animated: true)
    }
    
    
    // 4 Function for givng the annotation for user's location
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        self.selectedAnnotation = view.annotation as? MKPointAnnotation
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "restaurantProfile" {
            guard let detailVC = segue.destination as? RestaurantProfileViewController else { return }
            detailVC.mapAddress = mapAddress
            detailVC.businesses = self.selectedRestaurant
            //            detailVC.navigationItem.hidesBackButton = true
        }
    }
}

// 5 Extremely important for user location functionality to work
extension HomeViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.first else { return }
        
        if currentCoordinate == nil {
            zoomToLatestLocation(with: latestLocation.coordinate)
        }
        
        currentCoordinate = latestLocation.coordinate
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            beginLocationUpdates(locationManager: manager)
        }
    }
    
    // ✅ TODO: Move to alert helper
    func showNoResultsAlert() {
        guard let searchedTerm = searchBarMap.text else { return }
        AlertHelper.showNoSearchResultsAlert(vc: self, searchTerm: searchedTerm)
    }
}

extension HomeViewController: CalloutViewDelegate {
    func calloutViewTapped(restaurant: Businesses, sender: CalloutView) {
        self.selectedRestaurant = restaurant
        self.performSegue(withIdentifier: "restaurantProfile", sender: sender)
    }
}
