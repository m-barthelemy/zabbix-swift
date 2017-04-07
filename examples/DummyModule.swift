import Glibc
import Foundation
import ZabbixModule


/// This section is mandatory.
/// This is where you declare the Zabbix metrics of your module
@_cdecl("zbx_module_init")
func zbx_module_init() -> Int32 {
    
    return Zabbix.registerMetrics(metricsList: [
        //Zabbix item Key   : Function to call
        "dummy.ping"        : Dummy.Ping,
        "dummy.echo"        : Dummy.Echo,
    ] )
}


public final class Dummy {

    public static func Ping(params: Array<String>) throws -> String {
        return "pong"
    }


    public static func Echo(params: Array<String>) throws -> String {

        if params.count == 0 {
            // This will get logged by Zabbix, and will mark this item as unsupported.
            // Here we reuse a generic exception defined in ZabbixModule, but any
            // custom exception will work fine.
            throw GenericError.BadParameters("This item expects 1 parameter")
        }

        // Like any good and useful echo command, we return the string passed as parameter
        return params[0]
    }
}
