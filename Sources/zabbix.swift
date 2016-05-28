//
//  zabbix.swift
//  zabbix-swift
//
//  Created by Matthieu Barthélemy on 5/12/16.
//
//

//import CoreFoundation
import Foundation
import CZabbix
import Glibc


let default_level = LogLevel.Info

enum GenericError : ErrorProtocol {
    case BadParameters(String)
    case BadZabbixParameters(String)
}


@_cdecl("zbx_module_api_version")
func zbx_module_api_version() -> Int32 {
    
    return CZabbix.ZBX_MODULE_API_VERSION_ONE
}


@_cdecl("zbx_module_init")
func zbx_module_init() -> Int32 {
    
    Zabbix.log(default_level, message:"[zbx-swift]: zbx_module_init called")
    
    let zbxSwiftVersion = "0.5"
    var swiftVersion: String = "<unknown>"
    
    #if swift(>=3.0)
        swiftVersion =  "3"
    #elseif swift(>=2.2)
        swiftVersion =  "2.2"
    #elseif swift(>=2.1)
        swiftVersion =  "2.1"
    #endif
    Zabbix.log(LogLevel.Info,  message: "[zbx-swift]: v\(zbxSwiftVersion), using Swift v\(swiftVersion)")
    
    return CZabbix.ZBX_MODULE_OK
}

@_cdecl("zbx_module_uninit")
func zbx_module_uninit() -> Int32 {
    
    Zabbix.log(default_level, message:"[zbx-swift]: zbx_module_uninit called")
    return CZabbix.ZBX_MODULE_OK
}


@_cdecl("zbx_module_item_timeout")
func zbx_module_item_timeout(timeout:Int){
    
    Zabbix.Timeout = timeout
    Zabbix.log(default_level, message:"[zbx-swift]: set Timeout to \(timeout)s.")
}


@_cdecl("zbx_module_item_list")
func zbx_module_item_list() -> UnsafeMutablePointer<CZabbix.ZBX_METRIC> {
    
    Zabbix.log(default_level, message:"[zbx-swift]: zbx_module_item_list called.")
    
    // The returned list of metrics must be (real_size +1) else zabbix will crash
    let metrics = UnsafeMutablePointer<CZabbix.ZBX_METRIC>(allocatingCapacity:Zabbix.Metrics.count+1)
    
    var index = 0
    for (key, _) in Zabbix.Metrics {
        
        guard !key.isEmpty else{
            Zabbix.log(LogLevel.Error, message:"[zbx-swift]: metric with null key, ignoring.")
            continue
        }
        
        var metric = CZabbix.ZBX_METRIC()
        
        let cKey = key.cString(using: NSUTF8StringEncoding)!
        metric.key = UnsafeMutablePointer(cKey)
        
        metric.flags = UInt32(CZabbix.CF_HAVEPARAMS)
        metric.function = process_agent_request
        
        let params = ""
        let cParam = params.cString(using: NSUTF8StringEncoding)!
        metric.test_param = UnsafeMutablePointer(cParam)
        
        metrics[index] = metric
        Zabbix.log(default_level, message:"[zbx-swift]: added metric \(key)[].")
        index += 1
    }
    
    // From Zabbix doc: "The list is terminated by a ZBX_METRIC structure with “key” field of NULL."
    metrics[index] = CZabbix.ZBX_METRIC()
    
    return metrics
}

var process_agent_request : @convention(c) (UnsafeMutablePointer<CZabbix.AGENT_REQUEST>?, UnsafeMutablePointer<CZabbix.AGENT_RESULT>?) -> Int32 = {
    (req, res) -> Int32 in
    
    guard req != nil && res != nil  else {
        Zabbix.log(LogLevel.Critical, message: "[zbx-swift]: Zabbix passed a null AGENT_REQUEST or AGENT_RESULT, this should never happen.")
        return CZabbix.SYSINFO_RET_FAIL;
    }
    
    let agentRequest: CZabbix.AGENT_REQUEST = req!.pointee
    
    let requestKey:String = String(UTF8String: UnsafeMutablePointer<CChar>(agentRequest.key))!
    Zabbix.log(default_level, message:"[zbx-swift]: Agent Request Key = '\(requestKey)' with \(agentRequest.nparam) parameters.")
    
    var requestParams = UnsafePointer<UnsafeMutablePointer<Int8>>(agentRequest.params)
    var parameters: [String] = Array<String>()
    for index:Int in 0..<Int(agentRequest.nparam) {
        let cParam = requestParams![index]
        let requestParam:String! = String(UTF8String: UnsafeMutablePointer<Int8>(cParam))
        parameters.append(requestParam)
    }
    
    do{
        /*if parameters.count < 3 {
            throw GenericError.BadParameters("Zabbix item \(requestKey) expects 3 parameters, but only \(parameters.count) were given.")
        }*/
        
        let result = try Zabbix.Metrics[requestKey]?(parameters)
        
        res!.pointee.type =  CZabbix.AR_TEXT //CZabbix.AR_STRING is limited to 255 "chars"
        guard result != nil else {
            return CZabbix.SYSINFO_RET_OK
        }
        var cResponseStr = result!.cString(using: NSUTF8StringEncoding)!
        //var cResponseStr = result!.cString(using: CFStringBuiltInEncodings.UTF8.rawValue)
        
        // Directly setting 'text' makes Zabbix crash when attempting to free() something (the AgentResult struct or something inside it)
        // Setting chars one by one seems do to the trick. Swift/C expert advice needed ;-)
        res!.pointee.text = UnsafeMutablePointer<CChar>(allocatingCapacity: cResponseStr.count+1)
        for index:Int in 0..<Int( cResponseStr.count) {
            res!.pointee.text[index] = cResponseStr[index]
        }
    }
    catch {
        Zabbix.log(LogLevel.Error, message: "[zbx-swift]: \(requestKey) : \(error)")
        
        res!.pointee.type =  CZabbix.AR_MESSAGE

        let cMsgStr = String("\(error)").cString(using: NSUTF8StringEncoding)! //.cStringUsingEncoding(NSUTF8StringEncoding)!
        
        // Directly setting 'msg' makes Zabbix crash when attempting to free() something (the AgentResult struct or something inside it)
        // Setting chars one by one seems do to the trick. Swift/C expert advice needed ;-)
        //res.pointee.msg = UnsafeMutablePointer<Int8>(cMsgStr)
        res!.pointee.msg = UnsafeMutablePointer<CChar>(allocatingCapacity: cMsgStr.count+1)
        for index:Int in 0..<Int( cMsgStr.count) {
            res!.pointee.msg[index] = cMsgStr[index]
        }
        
        return CZabbix.SYSINFO_RET_FAIL;
    }
    
    return CZabbix.SYSINFO_RET_OK
}


public enum LogLevel:Int32 {
    case Empty = 0
    case Critical = 1
    case Error = 2
    case Warning = 3
    case Debug = 4
    case Info = 127
}


public class Zabbix {
    
    public static var Timeout:Int = 3;
    
    internal static var metrics = [String: ((Array<String>) throws -> String)]();
    
    public static var Metrics : [String: ((Array<String>) throws -> String)] {
        get{
            return metrics
        }
        /*set(metricsList){
            metrics = metricsList
        }*/
    }
    
    public static func registerMetrics(metricsList: [String: ((Array<String>) throws -> String) ]) -> Bool {
        log(message: "[zbx-swift]: registering metrics.")
        metrics = metricsList
        return true
    }
    
    public static func log(_ level:LogLevel = default_level, message: String) {
        
        let cMessage = message.cString(using: NSUTF8StringEncoding)!
        let msgPtr = UnsafeMutablePointer<Int8>(cMessage)
        CZabbix.g2z_log(level.rawValue, msgPtr)
        
        msgPtr.deinitialize()
        //msgPtr = nil
        //msgPtr.deallocateCapacity(1)
    }

}








