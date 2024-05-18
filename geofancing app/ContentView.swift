import SwiftUI
import CoreLocation
import UserNotifications

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let center = UNUserNotificationCenter.current()
    private let geofenceRegionRadius: CLLocationDistance = 200
    private var geofenceLocations: [CLLocation] = []
    private var lastNotificationDate: Date?

    @Published var isInsideGeofence = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        
        generateGeofenceLocations()
    }
    func stopMonitoringGeofences() {
        for (index, _) in geofenceLocations.enumerated() {
            let identifier = "Geofence-\(index)"
            for region in locationManager.monitoredRegions {
                if region.identifier == identifier {
                    locationManager.stopMonitoring(for: region)
                }
            }
        }
    }

    
 
    func generateGeofenceLocations() {
        
        let monteSantAngelo = CLLocation(latitude: 40.823418, longitude: 14.193996)
        let sanGiovanni = CLLocation(latitude: 40.816579, longitude: 14.292384)
        let centroStorico = CLLocation(latitude: 40.848927, longitude: 14.258643)
        let viaMezzocannone = CLLocation(latitude: 40.850640, longitude: 14.258078)
        let capuana = CLLocation(latitude: 40.851656, longitude: 14.269951)

        // Posizione attuale dell'utente
        guard let userLocation = locationManager.location else {
                  return
              }
        
       // var geofenceLocations = [ tragitto1, tragitto2, tragitto3, tragitto4, tragitto5]
        var geofenceLocations = [ monteSantAngelo, sanGiovanni, centroStorico, viaMezzocannone, capuana]

        // Ordina le coordinate in base alla distanza dalla posizione attuale dell'utente
        geofenceLocations.sort { location1, location2 in
            let distance1 = location1.distance(from: userLocation)
            let distance2 = location2.distance(from: userLocation)
            return distance1 < distance2
        }
        
        // Mantieni solo le prime tre coordinate più vicine
        let closestLocations = Array(geofenceLocations.prefix(3))
        
        // Inserisci le coordinate più vicine nel geofencing
        for location in closestLocations {
        // Inserisci la logica per l'inserimento nel geofencing
            geofenceLocations.append(location)
            print("Coordinate geofencing: \(location.coordinate)")
        }
    }

    
    func startMonitoringGeofences() {
        print("startMonitoring")
        for (index, geofenceLocation) in geofenceLocations.enumerated() {
            let geofenceRegion = CLCircularRegion(center: geofenceLocation.coordinate,
                                                  radius: geofenceRegionRadius,
                                                  identifier: "Geofence-\(index)")
            geofenceRegion.notifyOnEntry = true
            geofenceRegion.notifyOnExit = true
            
            locationManager.startMonitoring(for: geofenceRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier.contains("Geofence") {
            guard shouldSendNotification() else {
                return
            }
            
            isInsideGeofence = true
            sendNotification()
        }
    }
    
    
    //funzione per far si che si bugghino lle notifiche quando sto al confine di un area
    private func shouldSendNotification() -> Bool {
        guard let lastDate = lastNotificationDate else {
            lastNotificationDate = Date()
            return true
        }
        
        let currentDate = Date()
        let timeInterval = currentDate.timeIntervalSince(lastDate)
        
        if timeInterval >= 60 { // Imposta una soglia di tempo di 60 secondi
            lastNotificationDate = currentDate
            return true
        }
        
        return false
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier.contains("Geofence") {
            isInsideGeofence = false
        }
    }
    
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Sei vicino a una delle coordinate di geofencing!"
        content.body = "Sei a meno di 200 metri da una delle coordinate di prova."
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        center.add(request) { error in
            if let error = error {
                print("Errore durante l'invio della notifica:", error.localizedDescription)
            }
        }
    }
}


struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isMonitoringStarted = false
    
    var body: some View {
        VStack {
            Text(locationManager.isInsideGeofence ? "You are near a place on the list!" : "No place detected.")
                .font(.title)
                .padding()
                .onAppear(perform: locationManager.startMonitoringGeofences)
 
            Button(action: {
                if isMonitoringStarted {
                    locationManager.stopMonitoringGeofences()
                } else {
                    locationManager.startMonitoringGeofences()
                }
                isMonitoringStarted.toggle()
            }) {
                Text(isMonitoringStarted ? "Stop." : "Start Monitoring.")
            }
            .padding()
        }
    }
}










// Genera casualmente 20 coordinate di prova
//        for _ in 0..<20 {
//            let latitude = Double.random(in: -90...90)
//            let longitude = Double.random(in: -180...180)
//            let geofenceLocation = CLLocation(latitude: latitude, longitude: longitude)
//            geofenceLocations.append(geofenceLocation)
//        }
