//
//  ViewController.swift
//  geojson
//
//  Created by Alessandro Perna on 15/07/2019.
//  Copyright © 2019 AlePerna. All rights reserved.
//

import UIKit
import GEOSwift
import MapKit
import Toast_Swift


class ViewController: UIViewController {

    
    @IBOutlet weak var mapView:MKMapView!
    var province = ["Belluno","Padova","Rovigo","Treviso","Venezia","Verona","Vicenza"]
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        mapView.addGestureRecognizer(gestureRecognizer)


    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setRegionFromGeoJson(name: "Veneto")
        DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
            self.province.forEach({ (provincia) in
                self.loadGeoJson(name: provincia)
            })
        }
    }

    @objc func handleTap(_ gestureReconizer: UILongPressGestureRecognizer)
    {
        
        let location = gestureReconizer.location(in: mapView)
        let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
        
        var style = ToastStyle()
        style.backgroundColor = .darkGray
        style.horizontalPadding = 20.0

        // Add annotation:
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)

        if checkPoint(name: "Veneto", coordinate: coordinate){
            
            self.province.forEach({ (provincia) in
                if checkPoint(name: provincia, coordinate: coordinate)  {
                    self.view.makeToast("Sei nella provincia di \(provincia)", duration: 1.5, position: .bottom, style: style)
                }
            })
            
        }else{
            self.view.makeToast("Sei fuori dal Veneto", duration: 1.5, position: .bottom, style: style)

        }
    }

    func checkPoint(name:String,coordinate:CLLocationCoordinate2D) -> Bool {
        
        if let geoJSONURL = Bundle.main.url(forResource: name, withExtension: "geojson"),
            let features = try! Features.fromGeoJSON(geoJSONURL),
            let geo = features.first?.geometries?.first as? MultiPolygon<Polygon>
        {
            
            if let shapesCollection = geo.mapShape() as? MKShapesCollection {
                
                let shapes = shapesCollection.shapes
                for shape in shapes {
                    if let polygon = shape as? MKPolygon {
                        return polygon.contain(coor: coordinate)
                    }
                }
            }
            
        }
        
        return false
        
    }

    
    func loadGeoJson(name:String){
        
        if let geoJSONURL = Bundle.main.url(forResource: name, withExtension: "geojson"),
            let features = try! Features.fromGeoJSON(geoJSONURL),
            let geo = features.first?.geometries?.first as? MultiPolygon<Polygon>
        {
            
            if let shapesCollection = geo.mapShape() as? MKShapesCollection {
                
                let shapes = shapesCollection.shapes
                for shape in shapes {
                    if let polygon = shape as? MKPolygon {
                        mapView.addOverlay(polygon)
                    }
                }
            }
        }

    }
    
    func setRegionFromGeoJson(name:String){
        
        if let geoJSONURL = Bundle.main.url(forResource: name, withExtension: "geojson"),
            let features = try! Features.fromGeoJSON(geoJSONURL),
            let geo = features.first?.geometries?.first as? MultiPolygon<Polygon>
        {
            
            if let shapesCollection = geo.mapShape() as? MKShapesCollection {
                mapView.setVisibleMapRect(shapesCollection.boundingMapRect, animated: true)
            }
            
        }
        
    }


}

extension ViewController: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolygon{
            
            let render = MKPolygonRenderer(overlay: overlay)
            render.strokeColor = UIColor.black
            render.fillColor = UIColor.lightGray
            render.alpha = 0.2
            render.lineWidth = 2.0
            return render
            
        }else if overlay is MKPolyline{
            
            let render = MKPolylineRenderer(overlay: overlay)
            render.strokeColor = UIColor.black
            render.fillColor = UIColor.lightGray
            render.alpha = 0.2
            render.lineWidth = 2.0
            return render
            
        }else if overlay is MKCircle{
            
            let render = MKCircleRenderer(overlay: overlay)
            render.strokeColor = UIColor.black
            render.fillColor = UIColor.lightGray
            render.alpha = 0.2
            render.lineWidth = 2.0
            return render
            
        }else if overlay is MKTileOverlay{
            
            let renderer = MKTileOverlayRenderer(overlay:overlay)
            renderer.alpha = 0.8
            return renderer
            
        }

        
        return MKOverlayRenderer()
    }
    
    
}


extension MKPolygon {
    func contain(coor: CLLocationCoordinate2D) -> Bool {
        let polygonRenderer = MKPolygonRenderer(polygon: self)
        let currentMapPoint: MKMapPoint = MKMapPoint(coor)
        let polygonViewPoint: CGPoint = polygonRenderer.point(for: currentMapPoint)
        return polygonRenderer.path.contains(polygonViewPoint)
    }
}
