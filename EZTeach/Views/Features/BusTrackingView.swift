//
//  BusTrackingView.swift
//  EZTeach
//
//  Bus tracking for parents and schools
//

import SwiftUI
import FirebaseFirestore
import MapKit

struct BusTrackingView: View {
    let schoolId: String
    let isAdmin: Bool
    
    @State private var routes: [BusRoute] = []
    @State private var selectedRoute: BusRoute?
    @State private var isLoading = true
    @State private var showAddRoute = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if routes.isEmpty {
                    emptyState
                } else {
                    // Route selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(routes) { route in
                                routeChip(route)
                            }
                        }
                        .padding()
                    }
                    
                    // Map
                    Map(position: .constant(.region(mapRegion))) {
                        ForEach(selectedRoute?.stops ?? []) { stop in
                            Annotation(stop.name, coordinate: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)) {
                                VStack {
                                    Image(systemName: "bus.fill")
                                        .foregroundColor(EZTeachColors.accent)
                                        .padding(8)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(radius: 3)
                                    
                                    Text(stop.name)
                                        .font(.caption2)
                                        .padding(4)
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .frame(height: 300)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Route details
                    if let route = selectedRoute {
                        List {
                            Section("Driver") {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(EZTeachColors.accent)
                                    
                                    VStack(alignment: .leading) {
                                        Text(route.driverName)
                                            .font(.headline)
                                        Text(route.driverPhone)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        callDriver(route.driverPhone)
                                    } label: {
                                        Image(systemName: "phone.fill")
                                            .padding(10)
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            
                            Section("Stops (\(route.stops.count))") {
                                ForEach(route.stops.indices, id: \.self) { index in
                                    HStack {
                                        Text("\(index + 1)")
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                            .frame(width: 24, height: 24)
                                            .background(EZTeachColors.accent)
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading) {
                                            Text(route.stops[index].name)
                                                .font(.subheadline)
                                            Text(route.stops[index].estimatedTime)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .background(EZTeachColors.background)
            .navigationTitle("Bus Tracking")
            .toolbar {
                if isAdmin {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddRoute = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddRoute) {
                AddBusRouteView(schoolId: schoolId) {
                    loadRoutes()
                }
            }
            .onAppear(perform: loadRoutes)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bus.fill")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Bus Routes")
                .font(.headline)
            Text(isAdmin ? "Add your first bus route" : "No routes available yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func routeChip(_ route: BusRoute) -> some View {
        Button {
            selectedRoute = route
            if let firstStop = route.stops.first {
                mapRegion.center = CLLocationCoordinate2D(latitude: firstStop.latitude, longitude: firstStop.longitude)
            }
        } label: {
            HStack {
                Image(systemName: "bus.fill")
                Text("Route \(route.routeNumber)")
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(selectedRoute?.id == route.id ? EZTeachColors.accentGradient : LinearGradient(colors: [EZTeachColors.secondaryBackground], startPoint: .leading, endPoint: .trailing))
            .foregroundColor(selectedRoute?.id == route.id ? .white : .primary)
            .cornerRadius(20)
        }
    }
    
    private func callDriver(_ phone: String) {
        if let url = URL(string: "tel://\(phone.replacingOccurrences(of: "-", with: ""))") {
            UIApplication.shared.open(url)
        }
    }
    
    private func loadRoutes() {
        isLoading = true
        db.collection("busRoutes")
            .whereField("schoolId", isEqualTo: schoolId)
            .getDocuments { snap, _ in
                routes = snap?.documents.compactMap { BusRoute.fromDocument($0) } ?? []
                selectedRoute = routes.first
                isLoading = false
            }
    }
}

struct AddBusRouteView: View {
    let schoolId: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var routeNumber = ""
    @State private var driverName = ""
    @State private var driverPhone = ""
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Route Info") {
                    TextField("Route Number", text: $routeNumber)
                        .keyboardType(.numberPad)
                }
                
                Section("Driver") {
                    TextField("Driver Name", text: $driverName)
                    TextField("Phone", text: $driverPhone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("New Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveRoute()
                    }
                    .disabled(routeNumber.isEmpty || driverName.isEmpty)
                }
            }
        }
    }
    
    private func saveRoute() {
        db.collection("busRoutes").addDocument(data: [
            "schoolId": schoolId,
            "routeNumber": routeNumber,
            "driverName": driverName,
            "driverPhone": driverPhone,
            "stops": [],
            "assignedStudentIds": []
        ]) { _ in
            onSave()
            dismiss()
        }
    }
}
