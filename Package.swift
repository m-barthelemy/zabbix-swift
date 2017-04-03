import PackageDescription

let package = Package(
    name: "ZabbixModule",
    dependencies: [
        .Package(url: "https://github.com/m-barthelemy/CZabbix.git", Version(0,1,3))
    ]
)
