import HTTPserver
import std/[
    tables,
    net,
]

proc CreateHTMLResponse(html:string): Response =
    return Response(status: 200, body: html, headers: {"Content-Type": "text/html"}.toTable)

proc CreateAnyResponse(html:string, contentType:string): Response =
    return Response(status: 200, body: html, headers: {"Content-Type": contentType}.toTable)

proc index(req: Request): Response =
    return Response(status: 200, body: "<h1>Hello World!</h1>", headers: {"Content-Type": "text/html"}.toTable)

var server = HTTPserver.create(Port(8848))
server.register("GET", "/index.html", index)

server.register("GET", "/", proc (req:Request): Response = CreateHTMLResponse(readFile("./examples/boom-website/index.html")))
server.register("GET", "/style/style.css", proc (req:Request): Response = CreateAnyResponse(readFile("./examples/boom-website/style.css"), "text/css"))
server.register("GET", "/style/component.css", proc (req:Request): Response = CreateAnyResponse(readFile("./examples/boom-website/component.css"), "text/css"))
server.register("GET", "/script/app.js", proc (req:Request): Response = CreateAnyResponse(readFile("./examples/boom-website/app.js"), "text/javascript"))

server.register("GET", "/images/ears-anime.gif", proc (req:Request): Response = CreateAnyResponse(readFile("./examples/boom-website/gifs/ears-anime.gif"), "image/gif"))
server.register("GET", "/images/yumi-fox.gif", proc (req:Request): Response = CreateAnyResponse(readFile("./examples/boom-website/gifs/yumi-fox.gif"), "image/gif"))
server.register("GET", "/images/yandere-heart.gif", proc (req:Request): Response = CreateAnyResponse(readFile("./examples/boom-website/gifs/yandere-heart.gif"), "image/gif"))
server.register("GET", "/images/owo-what.gif", proc (req:Request): Response = CreateAnyResponse(readFile("./examples/boom-website/gifs/owo-what.gif"), "image/gif"))

server.register("POST", "/api/v1/users", proc (req:Request): Response = Response(status: 200, body: """["bob", "dii", "norm", "coline"]""", headers: {"Content-Type": "application/json"}.toTable))
server.run()


