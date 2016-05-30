//
//  ZabbixModule.swift
//  zabbix-mongo
//
//  Created by Matthieu Barthélemy on 5/15/16.
//
//



// This is a failed attempt at making a plugin system by requiring the plugin to implement a protocol
//  and then find it at runtime. 
// Due to Sfwift's very limited reflection capabilities, it doesn't seem to be possible for now.



import Glibc

public enum ZabbixFunction {
    case IntFunc ( (Array<String>) throws -> Int)
    case StringFunc ( (Array<String>) throws -> String)
}


// This is the protocol (Interface) to implement
// in order we can find and register the Zabbis commands
// Must return a Dictionary<string,Func(String[] params)>
protocol ZabbixModule: class {
    func GetZabbixCommands()  -> [String : ZabbixFunction]

}


// Inspired by http://www.spanware.com/blog/files/81bb0532b7f5c9ce9d015abc9b50c0e5-0.html
/*class ZabbixModuleFactory {
    
    class func create(name : String) -> ZabbixModule? {
        //let infoDict = NSBundle.mainBundle().infoDictionary
        //let appName = NSBundle.mainBundle().infoDictionary!["CFBundleName"] //as! String
        //print("infoDict=\(infoDict)")
        //let className = NSStringFromClass(Mongo)
        //var classObj = NSClassFromString("Mongo") //NSClassFromString(className)
        //print("className=\(className), classObj=\(classObj)")
        guard let any : AnyObject.Type = NSClassFromString(name) else {
            //print("\(appName).\(name)  NULL NULL")
            return nil;
        }

        guard let ns = any as? ZabbixModule.Type else {
            return nil;
        }
        
        //if let classType = NSClassFromString(name) as? ZabbixModule.Type {
         //   let zbxModule = classType.init()
          //  return zbxModule
            //object.saySomething()
        //}

        
        /*var instance: ZabbixModule! = nil
        let classInst = NSClassFromString(name) //as! ZabbixModule.Type
        instance = classInst.init()*/
        return nil
        //return ns!.init()
    }
    
    func description() -> String {
        return  NSStringFromClass(self.dynamicType)
    }
    
    required init() { }
    
}*/
