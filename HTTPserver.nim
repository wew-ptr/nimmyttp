import std/[
    net,
    strformat,
    strutils,
    tables
]
import asyncdispatch


proc `?`(a:auto, b:tuple): auto =
    if bool(a):
        return b[0]
    else:
        return b[1]


type
    Request* = object
        reqMethod: string
        path: string
        headers: Table[string, string]
        body: string
    Response* = object
        status*: int16
        statusText*: string
        headers*: Table[string, string]
        body*: string
    Handler = proc(req: Request): Response
    HTTPServer = object
        socket: Socket
        endpoints: Table[string, Table[string, Handler]]

proc readRequest(data: string): Request =
    let d = data.split("\r\n\r\n", 1)

    let control = d[0].split("\r\n", 1)[0]
    let control_data = control.split(" ")
    if control_data.len == 3:
        result.reqMethod = control_data[0]
        result.path = control_data[1]
    else:
        result.reqMethod = ""
        result.path = ""

    let headers = d[0].split("\r\n", 1)[1]
    for line in headers.splitlines():
        result.headers[line.split(": ", 1)[0]] = line.split(": ", 1)[1]

    result.body = d.len == 2 ? (d[1], "")

proc parseResponse(data: Response): string =
    result = &"HTTP/1.1 {data.status}" & (data.statusText=="" ? ("", " ")) & data.statusText & "\r\n"
    for k, v in data.headers.pairs:
        result &= &"{k}: {v}\r\n"
    if data.body != "":
        result &= &"Content-Length: {data.body.len}\r\n\r\n"
        result &= data.body
    else:
        result &= "\r\n"

proc ClientConnection(server: HTTPServer, client: Socket) {.async.}=
    var stack: string
    while true:
        var data: string
        discard client.recv(data, 1)
        stack &= data

        if data == "":
            client.close()
            echo "Connection aborted"
            break

        if "\r\n\r\n" in stack:
            let headerContent = stack.split("\r\n", 1)[1].split("\r\n\r\n", 1)[0].toLower
            if ("content-length: " in headerContent and headerContent.split("content-length: ")[1].split("\r\n")[0].parseInt == stack.split("\r\n\r\n", 1)[1].len) or "content-length: " notin headerContent:
                let request = readRequest(stack)
                if request.path notin server.endpoints:
                    echo &"No endpoint found ({request.path})"
                    client.send(parseResponse(Response(status:404)))
                else:
                    if request.reqMethod notin server.endpoints[request.path]:
                        var allowedMethods = ""
                        for k in server.endpoints[request.path].keys:
                            allowedMethods &= k & ", "
                        allowedMethods.removeSuffix(", ")
                        client.send(parseResponse(Response(status:405, statusText: "Method Not Allowed", headers: {"Allow": allowedMethods}.toTable)))
                    else:
                        let response = server.endpoints[request.path][request.reqMethod](request)
                        client.send(parseResponse(response))
                stack = ""
                client.close()
                return

proc create*(port: Port, address: string=""): HTTPServer =
    result.socket = newSocket()
    result.socket.bindAddr(port, address)

proc run*(server: var HTTPServer) =
    server.socket.listen()
    echo "Start server"
    var client: Socket
    var address = ""
    while true:
        server.socket.acceptAddr(client, address)
        echo &"Client connected: {address}"
        discard ClientConnection(server, client)

proc register*(server: var HTTPServer, httpMethod:string, path: string, callback: Handler) =
    if path notin server.endpoints:
        server.endpoints[path] = initTable[string, Handler]()
    server.endpoints[path][httpMethod] = callback

#[

let server = HTTPServer.new("127.0.0.1", Port(5472))
server.register("/hello")
server.run()

]#