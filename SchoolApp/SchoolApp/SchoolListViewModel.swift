//
//  SchoolListViewModel.swift
//  SchoolApp
//
//  Created by Mohsin Khawas on 10/12/19.
//  Copyright © 2019 Mohsin Khawas. All rights reserved.
//

import Foundation

protocol SchoolListViewControllerDelegate: class {
    func fetchSchoolListSuccess(_ failedError: Error?)
    func fetchSATSuccess(_ failedError: Error?)
}

class SchoolListViewModel: NSObject {
    private var schools: [School] = []

    let networkManager = NetworkManager()
    
    weak var delegate: SchoolListViewControllerDelegate?
    
    init(_ delegate: SchoolListViewControllerDelegate) {
        super.init()
        
        self.delegate = delegate
        self.fetchSchools()
    }
    
    func numberOfRows(inSection section: Int) -> Int {
        return schools.count
    }
    
    func data(forRowAt indexPath: IndexPath) -> School {
        return schools[indexPath.row]
    }
    
    func fetchSchools(){
        networkManager.fetchData(urlString: APIURLConstants.fetchSchools) { (resultData, fetchError) in
            
            if let error = fetchError{
                self.delegate?.fetchSchoolListSuccess(error)
            }else {
                do{
                    let schoolList = try JSONDecoder().decode(Array<School>.self, from: resultData as! Data)
                    
                    self.schools = schoolList
                    self.fetchSATScores()
                }catch{
                    self.delegate?.fetchSchoolListSuccess(error)
                }
            }
        }
    }
    
    func fetchSATScores(){
        networkManager.fetchData(urlString: APIURLConstants.fetchSATScores) { (resultData, fetchError)  in
            
            if let error = fetchError{
                self.delegate?.fetchSchoolListSuccess(error)
            }else{
                do{
                    let schoolSATScores = try JSONDecoder().decode(Array<SchoolSATScores>.self, from: resultData as! Data)
                    self.mapSATScoresToSchools(schoolSATScores)
                self.delegate?.fetchSchoolListSuccess(fetchError)
                    self.delegate?.fetchSATSuccess(fetchError)

                }catch{
                    self.delegate?.fetchSATSuccess(error)
                }
            }
        }
    }
    
    func mapSATScoresToSchools(_ satScrores: [SchoolSATScores]){
        let previous = self.schools
        self.schools.removeAll()
        
        for schoolSATSchore in satScrores{
            if let dbn = schoolSATSchore.dbn{
                var matchedSchool = previous.first(where: { (nycHighSchool) -> Bool in
                    return nycHighSchool.dbn == dbn
                })
                
                guard matchedSchool != nil else{
                    continue
                }
                
                matchedSchool?.satScores = schoolSATSchore
                self.schools.append(matchedSchool!)
            }
        }
    }
}
