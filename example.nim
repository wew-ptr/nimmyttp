import HTTPserver
import std/[
    tables,
    net
]

proc CreateHTMLResponse(html:string): Response =
    return Response(status: 200, body: html, headers: {"Content-Type": "text/html"}.toTable)


proc index(req: Request): Response =
    return Response(status: 200, body: "<h1>Hello World!</h1>", headers: {"Content-Type": "text/html"}.toTable)

var server = HTTPserver.create(Port(8848))
server.register("GET", "/index.html", index)
server.register("GET", "/hello", proc (req:Request): Response = CreateHTMLResponse(""))
server.register("POST", "/api/v1/users", proc (req:Request): Response = Response(status: 200, body: """["kaggle", "dii", "norm", "coline"]""", headers: {"Content-Type": "application/json"}.toTable))
server.run()
