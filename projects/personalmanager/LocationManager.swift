import Foundation
import CoreLocation

public final class LocationManager: NSObject, CLLocationManagerDelegate {
    public static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?
    
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    public func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    public func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    public func getCoordinates() -> (latitude: Double, longitude: Double) {
        if let loc = lastLocation {
            return (loc.coordinate.latitude, loc.coordinate.longitude)
        }
        if let loc = manager.location {
            return (loc.coordinate.latitude, loc.coordinate.longitude)
        }
        // Default mock coordinates (e.g. Berlin, Germany) to always return a valid coordinate
        return (52.5200, 13.4050)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
}
