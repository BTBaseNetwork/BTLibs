//
//  XiaoBingAPI.swift
//  ibeauty
//
//  Created by Alex Chow on 2018/11/30.
//  Copyright © 2018 btbase. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class XiaoBingAPI {
    private func uploadFaceImage(imageData:Data,callback:@escaping (JSON?,Error?)->Void){
        let uploadUrl = "http://kan.msxiaobing.com/Api/Image/UploadBase64"
        let encodedData = imageData.base64EncodedData()
        //let encodedData = imageData.base64EncodedString().toUTF8EncodingData()
        let headers = ["User-Agent":"Mozilla/5.0"]
        Alamofire.upload(encodedData, to: uploadUrl, method: .post, headers: headers)
            .validate(statusCode: 200..<300)
            .responseData { (resp) in
                switch resp.result{
                case let .success(data):
                    do{
                        let json = try JSON(data: data)
                        callback(json,nil)
                    }catch let jsonError{
                        callback(nil,jsonError)
                    }
                case let .failure(error):
                    callback(nil,error)
                }
        }
    }
    
    private func detectFaceScore(imageUrl:String){
        
    }
}

/*
 [HttpGet("FaceScoreTest")]
 public async Task<object> FaceScoreTest(string imageUrl, float addition)
 {
 try
 {
 var userId = UserSessionData.UserId;
 var apiUrl = "http://kan.msxiaobing.com/Api/ImageAnalyze/Process?service=beauty";
 var client = new HttpClient();
 client.DefaultRequestHeaders.Add("user-agent", "Mozilla/5.0");
 var time = (long)DateTimeUtil.UnixTimeSpan.TotalSeconds;
 
 var paras = new KeyValuePair<string, string>[] {
 new KeyValuePair<string, string>("MsgId",IDUtil.GenerateLongId().ToString()),
 new KeyValuePair<string, string>("CreateTime",time.ToString()),
 new KeyValuePair<string, string>("Content[imageUrl]",imageUrl)
 };
 var content = new FormUrlEncodedContent(paras);
 var result = await client.PostAsync(apiUrl, content);
 
 var resultContent = await result.Content.ReadAsStringAsync();
 
 
 #if DEBUG
 Console.WriteLine(resultContent);
 #else
 if (NiceFaceClubConfigCenter.IsFaceTestLogEnabled)
 {
 LogInfo(resultContent);
 }
 #endif
 
 dynamic obj = JsonConvert.DeserializeObject(resultContent);
 var metadata = (JObject)obj.content.metadata;
 var fbrCnt = 0;
 try
 {
 fbrCnt = (int)metadata["FBR_Cnt"];
 }
 catch (Exception)
 {
 }
 
 var highScore = 0.0f;
 var sumScore = 0.0f;
 
 for (int i = 0; i < fbrCnt; i++)
 {
 var s = (float)metadata["FBR_Score" + i];
 sumScore += s;
 if (s > highScore)
 {
 highScore = s;
 }
 }
 
 var avgScore = sumScore / fbrCnt;
 
 var resScore = AdjustScore(highScore, sumScore, avgScore, fbrCnt, addition);
 
 if (resScore >= 10f)
 {
 resScore = 9.9f;
 }
 else
 {
 resScore = ((int)(resScore * 10f)) / 10f;
 }
 
 var msg = NiceFaceClubConfigCenter.GetScoreString(resScore);
 
 return new
 {
 rId = GenerateResultId(time, resScore, userId),
 hs = resScore,
 msg = msg,
 ts = time
 };
 }
 catch (Exception)
 {
 Response.StatusCode = 400;
 return null;
 }
 }
 
 
 
 */
