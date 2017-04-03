import PackageDescription

let package = Package(
	name: "Aquifer",
	targets: [
		Target(
			name: "Aquifer"),
	],
	dependencies: [
		.Package(url: "https://github.com/typelift/Operadics.git", versions: Version(0,2,2)...Version(1,0,0)),
		.Package(url: "https://github.com/typelift/Swiftz.git", versions: Version(0,6,0)...Version(1,0,0)),
		.Package(url: "https://github.com/typelift/Focus.git", versions: Version(0,3,0)...Version(1,0,0)),
	]
)

let libAquifer = Product(name: "Aquifer", type: .Library(.Dynamic), modules: "Aquifer")
products.append(libAquifer)
