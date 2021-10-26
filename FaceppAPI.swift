//
//  FaceppAPI.swift
//  tumblreader
//
//  Created by Alex Chow on 2018/10/27.
//  Copyright © 2018 Tumblreader. All rights reserved.
//

import Alamofire
import Foundation
import SwiftyJSON

private let detectApi = "https://api-cn.faceplusplus.com/facepp/v3/detect"
private let apiKey = "V4BBqd12AvpWVBNAjdAw-PCZIqu5KwWE"
private let apiSecret = "w_lQhWIpALi8Ul0bKK_WRTJowTKv1S-y"

class FaceppAPI {
    
    static func detectFace(image:UIImage,quality:CGFloat = 1,completion:@escaping (_ result:JSON?,_ error:Error?)->Void){
        if let imgdata = image.jpegData(compressionQuality: quality) {
            
            #if DEBUG
            dPrint("[FaceppAPI] detect face image size:\(image.size)")
            dPrint("[FaceppAPI] detect face image data:\(imgdata.description)")
            dPrint("[FaceppAPI] detect face image quality:\(quality)")
            #endif
            
            let imageSize = image.size
            let attributes = ["age","gender","beauty","smiling"].joined(separator: ",")
            
            let url = "\(detectApi)?api_key=\(apiKey)&api_secret=\(apiSecret)&return_attributes=\(attributes)"
            if let req = try? URLRequest(url: url, method: .post, headers: nil) {
                Alamofire.upload(multipartFormData: { mdata in
                    mdata.append(imgdata.base64EncodedData(), withName: "image_base64")
                }, with: req) { result in
                    switch result {
                    case let .success(request: taskReq, streamingFromDisk: _, streamFileURL: _):
                        taskReq.responseData { resp in
                            switch resp.result {
                            case let .success(data):
                                if var result = try? JSON(data: data) {
                                    var imageSizeJson = JSON()
                                    imageSizeJson["width"].double = Double(imageSize.width)
                                    imageSizeJson["height"].double = Double(imageSize.height)
                                    result["imageSize"].object = imageSizeJson
                                    completion(result,nil)
                                } else {
                                    completion(nil,NSError(domain: "FaceppAPI", code: -999, userInfo: nil))
                                }
                            case let .failure(err):
                                completion(nil,err)
                            }
                        }
                        
                    case let .failure(err):
                        completion(nil,err)
                    }
                }
            }else{
                completion(nil,NSError(domain: "FaceppAPI", code: -999, userInfo: nil))
            }
        }else{
            completion(nil,NSError(domain: "FaceppAPI", code: -999, userInfo: nil))
        }
    }
}

typealias FaceSmileInfo = (value:Float,threshold:Float)

class FaceInfo {
    var faceToken:String!
    var gender:String?
    var age:Int = 0
    var beautyByFemale:Float = 0
    var beautyByMale:Float = 0
    var faceRect = CGRect.zero
    
    var smile:FaceSmileInfo = (0,0)
    var smileing:Bool{ return smile.value > smile.threshold }
    
    var isFemaleFace:Bool{ return gender == "female" }
    var isMaleFace:Bool{ return gender == "male" }
    
    var avgBeauty:Float{ return (beautyByMale + beautyByFemale) / 2 }
    
    var maxBeauty:Float{ return max(beautyByMale,beautyByFemale) }
    
    var imageSize = CGSize.zero
    
    
}

extension FaceppAPI{
    
    static func getFirstFace(fromResut result:JSON) -> FaceInfo?{
        return getFace(fromResut: result, faceIndex: 0)
    }
    
    static func getFace(fromResut result:JSON,faceIndex index:Int) -> FaceInfo?{
        let faceCount = result["faces"].array?.count ?? 0
        
        if index >= faceCount {
            return nil
        }
        
        let fi = FaceInfo()
        fi.faceToken = getFaceToken(fromResult: result,faceIndex: index)
        fi.age = getAge(fromResult: result,faceIndex: index)
        fi.gender = getGender(fromResult: result,faceIndex: index)
        fi.beautyByFemale = getBeauty(fromResut: result, byFemale: true,faceIndex: index)
        fi.beautyByMale = getBeauty(fromResut: result, byFemale: false,faceIndex: index)
        fi.faceRect = getFaceRect(fromResult: result,faceIndex: index)
        fi.smile = getSmile(fromResult: result, faceIndex: index)
        fi.imageSize = getImageSize(fromResult: result)
        return fi
    }
    
    static func getImageSize(fromResult result:JSON)-> CGSize{
        let sizeJson = result["imageSize"]
        return CGSize(width: sizeJson["width"].doubleValue, height: sizeJson["height"].doubleValue)
    }
    
    static func getFaces(fromResult result:JSON) -> [FaceInfo]{
        let faceCount = result["faces"].array?.count ?? 0
        return (0..<faceCount).map{getFace(fromResut: result, faceIndex: $0)}.filter{$0 != nil}.map{$0!}
    }
    
    static func getTestRequestId(fromResut result:JSON) -> String?{
        return result["request_id"].string
    }
    
    static func getTestTimeUsed(fromResut result:JSON) -> TimeInterval{
        return result["time_used"].doubleValue / 1000
    }
    
    static func getFaceImageId(fromResut result:JSON) -> String?{
        return result["image_id"].string
    }
    
    static func getBeauty(fromResut result:JSON,byFemale:Bool,faceIndex index:Int = 0) -> Float{
        return result["faces"][index]["attributes"]["beauty"][byFemale ? "female_score" : "male_score"].float ?? -1
    }
    
    static func getAge(fromResult result:JSON,faceIndex index:Int = 0) -> Int{
        return result["faces"][index]["attributes"]["age"]["value"].int ?? -1
    }
    
    static func getGender(fromResult result:JSON,faceIndex index:Int = 0) -> String?{
        return result["faces"][index]["attributes"]["gender"]["value"].string?.lowercased()
    }
    
    static func getSmile(fromResult result:JSON,faceIndex index:Int = 0) -> FaceSmileInfo{
        let smileValue = result["faces"][index]["attributes"]["smile"]["value"].float ?? 0
        let smileThreshold = result["faces"][index]["attributes"]["smile"]["threshold"].float ?? 0
        return (smileValue,smileThreshold)
    }
    
    static func getFaceToken(fromResult result:JSON,faceIndex index:Int = 0) -> String?{
        return result["faces"][index]["face_token"].string
    }
    
    static func getFaceRect(fromResult result:JSON,faceIndex index:Int = 0) -> CGRect{
        let x = CGFloat(result["faces"][index]["face_rectangle"]["left"].float ?? 0)
        let w = CGFloat(result["faces"][index]["face_rectangle"]["width"].float ?? 0)
        let y = CGFloat(result["faces"][index]["face_rectangle"]["top"].float ?? 0)
        let h = CGFloat(result["faces"][index]["face_rectangle"]["height"].float ?? 0)
        return CGRect(x: x, y: y, width: w, height: h)
    }
}

protocol DetectFaceDelegate {
    func detectFace(sender: DetectFace, onDetected result: JSON)
    func detectFace(sender: DetectFace, onDetectFailure error: Error?)
}

private var detecting: DetectFace!

extension FaceppAPI{
    
    static func startDetectFace(vc: UIViewController, delegate: DetectFaceDelegate) {
        let imagePicker = UIImagePickerController()
        detecting = DetectFace(vc: vc)
        detecting.delegate = delegate
        imagePicker.delegate = detecting
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
        imagePicker.cameraDevice = .front
        imagePicker.cameraCaptureMode = .photo
        vc.present(imagePicker, animated: true, completion: nil)
    }
}

class DetectFace: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var vc: UIViewController!
    var delegate: DetectFaceDelegate?
    
    init(vc: UIViewController) {
        self.vc = vc
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        detecting = nil
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) {
            if let originImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                let hud = self.vc.showActivityHud()
                FaceppAPI.detectFace(image: originImage.scaleToWidthOf(256), completion: { (result, err) in
                    hud.hide(animated: true)
                    if let res = result{
                        self.delegate?.detectFace(sender: self, onDetected: res)
                    }else if let e = err{
                        self.delegate?.detectFace(sender: self, onDetectFailure: e)
                    }
                    detecting = nil
                })
            }else{
                detecting = nil
            }
        }
    }
}
